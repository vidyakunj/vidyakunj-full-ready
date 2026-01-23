/* =======================================================
   VIDYAKUNJ SMS + ATTENDANCE BACKEND
   FINAL – STABLE – ABSENT + LATE + DLT SMS
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

/* ================= ROOT ================= */
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

/* =======================================================
   ATTENDANCE SAVE + LOCK + DLT SMS
   ======================================================= */
app.post("/attendance", async (req, res) => {
  try {
    const { date, attendance } = req.body;

    if (!attendance || !attendance.length) {
      return res.status(400).json({ success: false });
    }

    const parsedDate = new Date(date);
    parsedDate.setHours(0, 0, 0, 0);
    const dateStr = parsedDate.toISOString().split("T")[0];

    const std = attendance[0].std;
    const div = attendance[0].div;

    const lockDoc = await AttendanceLock.findOne({ std, div, date: dateStr });
    const alreadyLocked = lockDoc?.locked || [];

    const newlyLocked = [];

    for (const s of attendance) {
      // Skip already locked
      if (alreadyLocked.includes(s.roll)) continue;

      await Attendance.updateOne(
        {
          studentId: s.studentId,
          std,
          div,
          date: parsedDate,
        },
        {
          $set: {
            roll: s.roll,
            present: s.present,
            late: s.present === true ? !!s.late : false,
          },
        },
        { upsert: true }
      );

      // 🔒 LOCK ONLY ABSENT OR LATE
      if (s.present === false || s.late === true) {
        newlyLocked.push(s.roll);

        // ================= SMS =================
        if (s.mobile) {
          let message = "";

          if (s.present === false) {
            message =
              "Dear Parent, your ward is ABSENT today. Vidyakunj School.";
          } else if (s.late === true) {
            message =
              "Dear Parent, your ward came LATE today. Vidyakunj School.";
          }

          if (message) {
            await axios.post(
              "https://api.gupshup.io/wa/api/v1/msg",
              new URLSearchParams({
                channel: "sms",
                source: process.env.GUPSHUP_SENDER,
                destination: s.mobile,
                message,
                srcname: process.env.GUPSHUP_SRCNAME,
              }),
              {
                headers: {
                  "apikey": process.env.GUPSHUP_API_KEY,
                  "Content-Type": "application/x-www-form-urlencoded",
                },
              }
            );
          }
        }
      }
    }

    if (newlyLocked.length) {
      await AttendanceLock.updateOne(
        { std, div, date: dateStr },
        { $addToSet: { locked: { $each: newlyLocked } } },
        { upsert: true }
      );
    }

    res.json({ success: true });
  } catch (err) {
    console.error("Attendance Error:", err);
    res.status(500).json({ success: false });
  }
});

/* =======================================================
   ATTENDANCE CHECK (USED BY FRONTEND)
   ======================================================= */
app.get("/attendance/check-lock", async (req, res) => {
  try {
    const { std, div, date } = req.query;

    if (!std || !div || !date) {
      return res.json({ absent: [], late: [] });
    }

    const parsedDate = new Date(date);
    parsedDate.setHours(0, 0, 0, 0);

    const records = await Attendance.find({
      std,
      div,
      date: parsedDate,
    });

    const absent = [];
    const late = [];

    for (const r of records) {
      if (r.present === false) absent.push(r.roll);
      else if (r.present === true && r.late === true) late.push(r.roll);
    }

    res.json({ absent, late });
  } catch (err) {
    console.error("Check Lock Error:", err);
    res.json({ absent: [], late: [] });
  }
});

/* ================= START ================= */
app.listen(process.env.PORT || 10000, () =>
  console.log("🚀 Server running")
);
