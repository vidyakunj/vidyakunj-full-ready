/* =======================================================
   VIDYAKUNJ SCHOOL BACKEND – FINAL STABLE
   ======================================================= */

const express = require("express");
const cors = require("cors");
const compression = require("compression");
const bodyParser = require("body-parser");
const mongoose = require("mongoose");
const axios = require("axios");
require("dotenv").config();

/* ================= APP SETUP ================= */
const app = express();

app.use(cors({
  origin: "https://vidyakunj-frontend.onrender.com",
  methods: ["GET", "POST", "OPTIONS"],
  allowedHeaders: ["Content-Type"],
}));

app.use(bodyParser.json());
app.use(compression());

/* ================= MONGO ================= */
mongoose.connect(process.env.MONGO_URL || process.env.MONGODB_URI)
  .then(() => console.log("✅ MongoDB Connected"))
  .catch(err => console.error("❌ Mongo Error", err));

/* ================= USERS ================= */
const users = [
  { username: "teacher1", password: "1234", role: "teacher" },
  { username: "admin", password: "admin123", role: "admin" },
];

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
}, { timestamps: true }));

const AttendanceLock = mongoose.model("attendance_locks", new mongoose.Schema({
  std: String,
  div: String,
  date: String,
  locked: [Number],
}));

/* ================= LOGIN ================= */
app.post("/login", (req, res) => {
  const { username, password } = req.body;
  const user = users.find(u => u.username === username && u.password === password);
  if (!user) return res.json({ success: false, message: "Invalid login" });
  res.json({ success: true, role: user.role });
});

/* ================= DIVISIONS ================= */
app.get("/divisions", async (req, res) => {
  const divisions = await Student.distinct("div", { std: req.query.std });
  res.json({ divisions });
});

/* ================= STUDENTS ================= */
app.get("/students", async (req, res) => {
  const students = await Student.find(req.query).sort({ roll: 1 });
  res.json({ students });
});

/* ================= LOCK CHECK ================= */
app.get("/attendance/check-lock", async (req, res) => {
  const { std, div, date } = req.query;
  const lock = await AttendanceLock.findOne({ std, div, date });
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

    const existingLock = await AttendanceLock.findOne({ std, div, date: dateStr });
    const locked = existingLock?.locked || [];

    const save = [];
    const lockNew = [];
    const sms = [];

    let sent = 0, failed = 0;

    for (const e of attendance) {
      if (e.present === true) continue;
      if (locked.includes(e.roll)) continue;

      save.push({
        studentId: e.studentId,
        std, div,
        roll: e.roll,
        date: parsedDate,
        present: false,
      });

      lockNew.push(e.roll);

      sms.push(
        axios.get(process.env.GUPSHUP_URL, {
          params: {
            method: "SendMessage",
            send_to: e.mobile,
            msg: `Dear Parents, Your child ${e.name} remained absent today.,Vidyakunj School`,
            msg_type: "TEXT",
            userid: process.env.GUPSHUP_USER,
            password: process.env.GUPSHUP_PASSWORD,
            auth_scheme: "PLAIN",
            v: "1.1",
          }
        })
        .then(r => r.data.toLowerCase().includes("success") ? sent++ : failed++)
        .catch(() => failed++)
      );
    }

    if (save.length) await Attendance.insertMany(save);
    if (lockNew.length) {
      await AttendanceLock.updateOne(
        { std, div, date: dateStr },
        { $addToSet: { locked: { $each: lockNew } } },
        { upsert: true }
      );
    }

    await Promise.all(sms);
    res.json({ success: true, smsSummary: { sent, failed } });
  } catch (err) {
    res.status(500).json({ success: false, error: err.message });
  }
});

/* ================= START ================= */
const PORT = process.env.PORT || 10000;
app.listen(PORT, () => console.log("🚀 Backend running on", PORT));
