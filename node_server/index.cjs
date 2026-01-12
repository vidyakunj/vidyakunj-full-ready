/* =======================================================
   VIDYAKUNJ SMS + ATTENDANCE BACKEND
   FINAL – STABLE – PRODUCTION READY
   ======================================================= */

const compression = require("compression");
const express = require("express");
const cors = require("cors");
const bodyParser = require("body-parser");
const mongoose = require("mongoose");
const axios = require("axios");
require("dotenv").config();

/* =======================================================
   LOGIN USERS
   ======================================================= */
const users = [
  { username: "patil", password: "iken", role: "teacher" },
  { username: "teacher1", password: "1234", role: "teacher" },
  { username: "vks", password: "1234", role: "teacher" },
  { username: "admin", password: "admin123", role: "admin" },
];

/* =======================================================
   APP SETUP
   ======================================================= */
const app = express();

app.use(cors({
  origin: "https://vidyakunj-frontend.onrender.com",
  methods: ["GET", "POST", "OPTIONS"],
  allowedHeaders: ["Content-Type"],
}));

app.use(bodyParser.json());
app.use(compression());

/* =======================================================
   HEALTH CHECK (IMPORTANT)
   ======================================================= */
app.get("/", (req, res) => {
  res.send("Vidyakunj Backend Running");
});

/* =======================================================
   MONGO CONNECTION
   ======================================================= */
mongoose
  .connect(process.env.MONGO_URL || process.env.MONGODB_URI)
  .then(() => console.log("✅ MongoDB Connected"))
  .catch((err) => console.error("❌ MongoDB Error:", err));

/* =======================================================
   SCHEMAS
   ======================================================= */
const Student = mongoose.model("students", new mongoose.Schema({
  std: String,
  div: String,
  name: String,
  roll: Number,
  mobile: String,
}));

const Attendance = mongoose.model("attendance", new mongoose.Schema({
  studentId: mongoose.Schema.Types.ObjectId,
  std: String,
  div: String,
  roll: Number,
  date: Date,
  present: Boolean,
}));

const AttendanceLock = mongoose.model("attendance_locks", new mongoose.Schema({
  std: String,
  div: String,
  date: String,
  locked: [Number],
}));

/* =======================================================
   LOGIN
   ======================================================= */
app.post("/login", (req, res) => {
  const user = users.find(
    u => u.username === req.body.username && u.password === req.body.password
  );
  if (!user) return res.json({ success: false });
  res.json({ success: true, role: user.role });
});

/* =======================================================
   BASIC APIs
   ======================================================= */
app.get("/divisions", async (req, res) => {
  const divisions = await Student.distinct("div", { std: req.query.std });
  res.json({ divisions });
});

app.get("/students", async (req, res) => {
  const students = await Student.find(req.query).sort({ roll: 1 });
  res.json({ students });
});

app.get("/attendance/check-lock", async (req, res) => {
  const lock = await AttendanceLock.findOne(req.query);
  res.json({ locked: lock?.locked || [] });
});

/* =======================================================
   SEND SMS (DLT SAFE – DO NOT MODIFY)
   ======================================================= */
app.post("/send-sms", async (req, res) => {
  const { mobile, studentName } = req.body;

  const params = {
    method: "SendMessage",
    send_to: mobile,
    msg: `Dear Parents, Your child, ${studentName} remained absent in school today.,Vidyakunj School`,
    msg_type: "TEXT",
    userid: process.env.GUPSHUP_USER,
    password: process.env.GUPSHUP_PASSWORD,
    auth_scheme: "PLAIN",
    v: "1.1",
  };

  const response = await axios.get(process.env.GUPSHUP_URL, { params });
  res.json({ success: response.data.toLowerCase().includes("success") });
});

/* =======================================================
   ATTENDANCE (ABSENT ONLY STORED)
   ======================================================= */
app.post("/attendance", async (req, res) => {
  try {
    const { date, attendance } = req.body;
    const parsedDate = new Date(date);
    parsedDate.setHours(0, 0, 0, 0);

    const dateStr = parsedDate.toISOString().split("T")[0];
    const std = attendance[0].std;
    const div = attendance[0].div;

    const lockDoc = await AttendanceLock.findOne({ std, div, date: dateStr });
    const locked = lockDoc?.locked || [];

    const toSave = [];
    const toLock = [];

    for (const e of attendance) {
      if (e.present === true) continue;
      if (locked.includes(e.roll)) continue;

      toSave.push({
        studentId: e.studentId,
        std,
        div,
        roll: e.roll,
        date: parsedDate,
        present: false,
      });

      toLock.push(e.roll);

      await axios.get(process.env.GUPSHUP_URL, {
        params: {
          method: "SendMessage",
          send_to: e.mobile,
          msg: `Dear Parents, Your child, ${e.name} remained absent in school today.,Vidyakunj School`,
          msg_type: "TEXT",
          userid: process.env.GUPSHUP_USER,
          password: process.env.GUPSHUP_PASSWORD,
          auth_scheme: "PLAIN",
          v: "1.1",
        }
      });
    }

    if (toSave.length) await Attendance.insertMany(toSave);

    if (toLock.length) {
      await AttendanceLock.updateOne(
        { std, div, date: dateStr },
        { $addToSet: { locked: { $each: toLock } } },
        { upsert: true }
      );
    }

    res.json({ success: true });
  } catch (err) {
    console.error(err);
    res.status(500).json({ success: false });
  }
});

/* =======================================================
   ADMIN SUMMARY (SCHOOL + SINGLE CLASS)
   ======================================================= */
app.get("/attendance/summary-school", async (req, res) => {
  try {
    const { date, std, div } = req.query;
    if (!date) return res.status(400).json({ success: false });

    const parsedDate = new Date(date);
    parsedDate.setHours(0, 0, 0, 0);
    const nextDay = new Date(parsedDate);
    nextDay.setDate(parsedDate.getDate() + 1);

    const match = {};
    if (std) match.std = String(std);
    if (div) match.div = div;

    const classes = await Student.aggregate([
      { $match: match },
      { $group: { _id: { std: "$std", div: "$div" }, total: { $sum: 1 } } },
      { $sort: { "_id.std": 1, "_id.div": 1 } }
    ]);

    let primary = [];
    let secondary = [];
    let schoolTotal = { total: 0, present: 0, absent: 0 };

    for (const c of classes) {
      const cStd = c._id.std;
      const cDiv = c._id.div;
      const total = c.total;

      const absent = await Attendance.countDocuments({
        std: cStd,
        div: cDiv,
        date: { $gte: parsedDate, $lt: nextDay },
        present: false,
      });

      const present = total - absent;
      const row = { std: cStd, div: cDiv, total, present, absent };

      schoolTotal.total += total;
      schoolTotal.present += present;
      schoolTotal.absent += absent;

      if (parseInt(cStd) <= 8) primary.push(row);
      else secondary.push(row);
    }

    res.json({
      success: true,
      date,
      primary,
      secondary,
      schoolTotal,
    });
  } catch (err) {
    console.error(err);
    res.status(500).json({ success: false });
  }
});

/* =======================================================
   ALIAS FOR OLD FRONTEND URL (CRITICAL)
   ======================================================= */
app.get("/attendance/summary", (req, res) => {
  req.url = "/attendance/summary-school";
  app._router.handle(req, res);
});

/* =======================================================
   START SERVER
   ======================================================= */
app.listen(process.env.PORT || 10000, () =>
  console.log("🚀 Vidyakunj Backend Running")
);
