/* =======================================================
   VIDYAKUNJ SCHOOL – FINAL BACKEND (STABLE)
   ======================================================= */

const express = require("express");
const cors = require("cors");
const bodyParser = require("body-parser");
const compression = require("compression");
const mongoose = require("mongoose");
const axios = require("axios");
require("dotenv").config();

/* =======================================================
   APP SETUP
   ======================================================= */
const app = express();

app.use(cors({
  origin: "*",
  methods: ["GET", "POST", "OPTIONS"],
  allowedHeaders: ["Content-Type"],
}));

app.use(bodyParser.json());
app.use(compression());

/* =======================================================
   MONGO CONNECTION
   ======================================================= */
mongoose
  .connect(process.env.MONGO_URL || process.env.MONGODB_URI)
  .then(() => console.log("✅ MongoDB connected"))
  .catch(err => console.error("❌ Mongo error:", err));

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
}, { timestamps: true }));

const AttendanceLock = mongoose.model("attendance_locks", new mongoose.Schema({
  std: String,
  div: String,
  date: String,
  locked: [Number],
}));

/* =======================================================
   ROUTES
   ======================================================= */

/* 🔐 LOGIN (FIXED) */
app.post("/login", (req, res) => {
  const { username, password } = req.body || {};
  const user = users.find(
    u => u.username === username && u.password === password
  );

  if (!user) {
    return res.json({ success: false, message: "Invalid username or password" });
  }

  res.json({
    success: true,
    username: user.username,
    role: user.role,
  });
});

/* 🔒 CHECK ATTENDANCE LOCK */
app.get("/attendance/check-lock", async (req, res) => {
  const { std, div, date } = req.query;
  const lock = await AttendanceLock.findOne({ std, div, date });
  res.json({ locked: lock?.locked || [] });
});

/* 📩 POST ATTENDANCE (ABSENT ONLY) */
app.post("/attendance", async (req, res) => {
  try {
    const { date, attendance } = req.body;

    if (!date || !Array.isArray(attendance)) {
      return res.status(400).json({ success: false });
    }

    const parsedDate = new Date(date);
    parsedDate.setHours(0, 0, 0, 0);

    const dateStr = parsedDate.toISOString().split("T")[0];
    const { std, div } = attendance[0];

    const existingLock = await AttendanceLock.findOne({ std, div, date: dateStr });
    const locked = existingLock?.locked || [];

    const save = [];
    const newLocks = [];
    const smsJobs = [];
    let sent = 0, failed = 0;

    for (const s of attendance) {
      if (s.present === true) continue;
      if (locked.includes(s.roll)) continue;

      save.push({
        studentId: s.studentId,
        std, div,
        roll: s.roll,
        date: parsedDate,
        present: false,
      });

      newLocks.push(s.roll);

      smsJobs.push(
        axios.get(process.env.GUPSHUP_URL, {
          params: {
            method: "SendMessage",
            send_to: s.mobile,
            msg: `Dear Parents, Your child ${s.name} remained absent today.,Vidyakunj School`,
            msg_type: "TEXT",
            userid: process.env.GUPSHUP_USER,
            password: process.env.GUPSHUP_PASSWORD,
            auth_scheme: "PLAIN",
            v: "1.1",
          },
        })
        .then(r => r.data.toLowerCase().includes("success") ? sent++ : failed++)
        .catch(() => failed++)
      );
    }

    if (save.length) await Attendance.insertMany(save);
    if (newLocks.length) {
      await AttendanceLock.updateOne(
        { std, div, date: dateStr },
        { $addToSet: { locked: { $each: newLocks } } },
        { upsert: true }
      );
    }

    await Promise.all(smsJobs);

    res.json({ success: true, smsSummary: { sent, failed } });
  } catch (err) {
    console.error(err);
    res.status(500).json({ success: false });
  }
});

/* ✅ HEALTH CHECK (VERY IMPORTANT) */
app.get("/", (req, res) => {
  res.json({ status: "Vidyakunj Backend Running" });
});

/* =======================================================
   START SERVER
   ======================================================= */
const PORT = process.env.PORT || 10000;
app.listen(PORT, () =>
  console.log("🚀 Backend running on port", PORT)
);
