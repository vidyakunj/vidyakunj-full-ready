/* =======================================================
   VIDYAKUNJ ATTENDANCE + SMS BACKEND
   FINAL GUARANTEED WORKING VERSION
   ======================================================= */

const express = require("express");
const cors = require("cors");
const compression = require("compression");
const bodyParser = require("body-parser");
const mongoose = require("mongoose");
const axios = require("axios");
require("dotenv").config();

/* =======================================================
   APP SETUP
   ======================================================= */
const app = express();

app.use(
  cors({
    origin: "https://vidyakunj-frontend.onrender.com",
    methods: ["GET", "POST", "OPTIONS"],
    allowedHeaders: ["Content-Type"],
  })
);

app.use(bodyParser.json());
app.use(compression());

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
const Student = mongoose.model(
  "students",
  new mongoose.Schema({
    std: String,
    div: String,
    name: String,
    roll: Number,
    mobile: String,
  })
);

const Attendance = mongoose.model(
  "attendance",
  new mongoose.Schema(
    {
      studentId: mongoose.Schema.Types.ObjectId,
      std: String,
      div: String,
      roll: Number,
      date: Date,
      present: Boolean,
    },
    { timestamps: true }
  )
);

const AttendanceLock = mongoose.model(
  "attendance_locks",
  new mongoose.Schema({
    std: String,
    div: String,
    date: String,
    locked: [Number],
  })
);

/* =======================================================
   CHECK LOCK (FRONTEND)
   ======================================================= */
app.get("/attendance/check-lock", async (req, res) => {
  const { std, div, date } = req.query;
  const lock = await AttendanceLock.findOne({ std, div, date });
  res.json({ locked: lock?.locked || [] });
});

/* =======================================================
   POST ATTENDANCE (FINAL FIX)
   ======================================================= */
app.post("/attendance", async (req, res) => {
  try {
    const { date, attendance } = req.body;

    if (!date || !Array.isArray(attendance)) {
      return res.status(400).json({ success: false });
    }

    const parsedDate = new Date(date);
    parsedDate.setHours(0, 0, 0, 0);

    const dateStr =
      parsedDate.getFullYear() +
      "-" +
      String(parsedDate.getMonth() + 1).padStart(2, "0") +
      "-" +
      String(parsedDate.getDate()).padStart(2, "0");

    const std = attendance[0].std;
    const div = attendance[0].div;

    const existingLock = await AttendanceLock.findOne({ std, div, date: dateStr });
    const alreadyLocked = existingLock?.locked || [];

    const saveAttendance = [];
    const newLocks = [];
    const smsJobs = [];

    let sent = 0;
    let failed = 0;

    for (const entry of attendance) {
      // 🔒 LOCK ONLY ABSENT STUDENTS
      if (entry.present === true) continue;

      // ⛔ Skip already locked
      if (alreadyLocked.includes(entry.roll)) continue;

      saveAttendance.push({
        studentId: entry.studentId,
        std,
        div,
        roll: entry.roll,
        date: parsedDate,
        present: false,
      });

      newLocks.push(entry.roll);

      // 📩 SMS (ONLY ABSENT)
      smsJobs.push(
        axios
          .get(process.env.GUPSHUP_URL, {
            params: {
              method: "SendMessage",
              send_to: entry.mobile,
              msg: `Dear Parents, Your child ${entry.name} remained absent today.,Vidyakunj School`,
              msg_type: "TEXT",
              userid: process.env.GUPSHUP_USER,
              password: process.env.GUPSHUP_PASSWORD,
              auth_scheme: "PLAIN",
              v: "1.1",
            },
          })
          .then((r) =>
            r.data.toLowerCase().includes("success") ? sent++ : failed++
          )
          .catch(() => failed++)
      );
    }

    if (saveAttendance.length > 0) {
      await Attendance.insertMany(saveAttendance);
    }

    if (newLocks.length > 0) {
      await AttendanceLock.updateOne(
        { std, div, date: dateStr },
        { $addToSet: { locked: { $each: newLocks } } },
        { upsert: true }
      );
    }

    await Promise.all(smsJobs);

    res.json({ success: true, smsSummary: { sent, failed } });
  } catch (err) {
    console.error("❌ Error:", err);
    res.status(500).json({ success: false });
  }
});

/* =======================================================
   START SERVER
   ======================================================= */
const PORT = process.env.PORT || 10000;
app.listen(PORT, () =>
  console.log("🚀 Server running on port", PORT)
);
