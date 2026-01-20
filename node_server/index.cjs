/* =======================================================
   VIDYAKUNJ SMS + ATTENDANCE BACKEND
   FINAL – ABSENT + LATE (OLD WORKING METHOD)
   ======================================================= */

const compression = require("compression");
const express = require("express");
const cors = require("cors");
const bodyParser = require("body-parser");
const mongoose = require("mongoose");
const axios = require("axios");
require("dotenv").config();

/* ================= LOGIN USERS ================= */
const users = [
  { username: "patil", password: "iken", role: "teacher" },
  { username: "teacher1", password: "1234", role: "teacher" },
  { username: "vks", password: "1234", role: "teacher" },
  { username: "admin", password: "admin123", role: "admin" },
];

/* ================= APP SETUP ================= */
const app = express();

app.use(cors({
  origin: "https://vidyakunj-frontend.onrender.com",
  methods: ["GET", "POST", "OPTIONS"],
  allowedHeaders: ["Content-Type"],
}));

app.use(bodyParser.json());
app.use(compression());

/* ================= ROOT CHECK ================= */
app.get("/", (req, res) => {
  res.send("Vidyakunj SMS Server Running");
});

/* ================= MONGO ================= */
mongoose
  .connect(process.env.MONGO_URL || process.env.MONGODB_URI)
  .then(() => console.log("✅ MongoDB Connected"))
  .catch((err) => console.error("❌ MongoDB Error:", err));

/* ================= SCHEMAS ================= */
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
  late: { type: Boolean, default: false },
}));

const AttendanceLock = mongoose.model("attendance_locks", new mongoose.Schema({
  std: String,
  div: String,
  date: String,
  locked: [Number],
}));

/* ================= LOGIN ================= */
app.post("/login", (req, res) => {
  const user = users.find(
    u => u.username === req.body.username && u.password === req.body.password
  );
  if (!user) return res.json({ success: false });
  res.json({ success: true, role: user.role });
});

/* ================= BASIC APIs ================= */
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

/* ================= ATTENDANCE ================= */
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

    const toLock = [];

    for (const e of attendance) {
      // 🔒 ONE-TIME LOCK (ABSENT + LATE + PRESENT)
      if (locked.includes(e.roll)) continue;

      await Attendance.updateOne(
        {
          studentId: e.studentId,
          std,
          div,
          date: parsedDate,
        },
        {
          $set: {
            roll: e.roll,
            present: e.present,
            late: e.present === true ? !!e.late : false,
          },
        },
        { upsert: true }
      );

      toLock.push(e.roll);
    }

    if (toLock.length) {
      await AttendanceLock.updateOne(
        { std, div, date: dateStr },
        { $addToSet: { locked: { $each: toLock } } },
        { upsert: true }
      );
    }

    res.json({ success: true });
  } catch (err) {
    console.error("Attendance Error:", err);
    res.status(500).json({ success: false });
  }
});

/* ================= ADMIN SCHOOL SUMMARY ================= */
app.get("/attendance/summary-school", async (req, res) => {
  try {
    const { date } = req.query;
    if (!date) {
      return res.json({
        success: true,
        primary: [],
        secondary: [],
        schoolTotal: { total: 0, present: 0, absent: 0 }
      });
    }

    const parsedDate = new Date(date);
    parsedDate.setHours(0, 0, 0, 0);

    const nextDay = new Date(parsedDate);
    nextDay.setDate(parsedDate.getDate() + 1);

    const classes = await Student.aggregate([
      {
        $group: {
          _id: { std: "$std", div: "$div" },
          total: { $sum: 1 }
        }
      }
    ]);

    let primary = [];
    let secondary = [];
    let schoolTotal = { total: 0, present: 0, absent: 0 };

    for (const c of classes) {
      const std = c._id.std;
      const div = c._id.div;
      const total = c.total;

      const absent = await Attendance.countDocuments({
        std,
        div,
        present: false,
        date: { $gte: parsedDate, $lt: nextDay }
      });

      const present = total - absent;

      const row = { std, div, total, present, absent };

      schoolTotal.total += total;
      schoolTotal.present += present;
      schoolTotal.absent += absent;

      if (parseInt(std) <= 8) primary.push(row);
      else secondary.push(row);
    }

    res.json({
      success: true,
      primary,
      secondary,
      schoolTotal
    });

  } catch (err) {
    console.error("SUMMARY ERROR:", err);
    res.json({
      success: true,
      primary: [],
      secondary: [],
      schoolTotal: { total: 0, present: 0, absent: 0 }
    });
  }
});
/* ================= ADMIN SCHOOL SUMMARY – DATE RANGE ================= */
app.get("/attendance/summary-school-range", async (req, res) => {
  try {
    const { from, to } = req.query;
    if (!from || !to) {
      return res.json({
        success: true,
        primary: [],
        secondary: [],
        schoolTotal: { total: 0, present: 0, absent: 0 }
      });
    }

    const start = new Date(from);
    start.setHours(0, 0, 0, 0);

    const end = new Date(to);
    end.setHours(23, 59, 59, 999);

    const classes = await Student.aggregate([
      {
        $group: {
          _id: { std: "$std", div: "$div" },
          total: { $sum: 1 }
        }
      }
    ]);

    let primary = [];
    let secondary = [];
    let schoolTotal = { total: 0, present: 0, absent: 0 };

    for (const c of classes) {
      const std = c._id.std;
      const div = c._id.div;
      const total = c.total;

      const absent = await Attendance.countDocuments({
        std,
        div,
        present: false,
        date: { $gte: start, $lte: end }
      });

      const present = total - absent;

      const row = { std, div, total, present, absent };

      schoolTotal.total += total;
      schoolTotal.present += present;
      schoolTotal.absent += absent;

      if (parseInt(std) <= 8) primary.push(row);
      else secondary.push(row);
    }

    res.json({ success: true, primary, secondary, schoolTotal });
  } catch (err) {
    console.error("RANGE SUMMARY ERROR:", err);
    res.status(500).json({ success: false });
  }
});

/* =======================================================
   ALIAS ROUTES – FIX FRONTEND 404 ISSUE
   DO NOT MOVE THIS BLOCK
   ======================================================= */

// ✅ SINGLE DAY (frontend calls /attendance/summary)
app.get("/attendance/summary", (req, res) => {
  req.url = "/attendance/summary-school";
  app._router.handle(req, res);
});

// ✅ DATE RANGE (frontend calls /attendance/summary-range)
app.get("/attendance/summary-range", (req, res) => {
  req.url = "/attendance/summary-school-range";
  app._router.handle(req, res);
});

/* ================= START ================= */
app.listen(process.env.PORT || 10000, () =>
  console.log("🚀 Server running")
);
