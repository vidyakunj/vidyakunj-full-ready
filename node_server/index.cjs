/* =======================================================
   VIDYAKUNJ SMS + ATTENDANCE BACKEND
   FINAL STABLE VERSION
   ======================================================= */

const express = require("express");
const cors = require("cors");
const compression = require("compression");
const bodyParser = require("body-parser");
const mongoose = require("mongoose");
const axios = require("axios");
require("dotenv").config();

/* =======================================================
   SIMPLE LOGIN USERS
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

app.use(
  cors({
    origin: "https://vidyakunj-frontend.onrender.com",
    methods: ["GET", "POST", "PUT", "DELETE", "OPTIONS"],
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
const studentSchema = new mongoose.Schema({
  std: String,
  div: String,
  name: String,
  roll: Number,
  mobile: String,
});

const Student = mongoose.model("students", studentSchema);

const attendanceSchema = new mongoose.Schema(
  {
    studentId: mongoose.Schema.Types.ObjectId,
    std: String,
    div: String,
    roll: Number,
    date: Date,
    present: Boolean,
  },
  { timestamps: true }
);

attendanceSchema.index({ studentId: 1, date: 1 }, { unique: true });

const Attendance = mongoose.model("attendance", attendanceSchema);

const attendanceLockSchema = new mongoose.Schema({
  std: String,
  div: String,
  date: String,      // YYYY-MM-DD
  locked: [Number],  // roll numbers
});

const AttendanceLock = mongoose.model(
  "attendance_locks",
  attendanceLockSchema
);

/* =======================================================
   ROUTES
   ======================================================= */

/* ---------- LOGIN ---------- */
app.post("/login", (req, res) => {
  const { username, password } = req.body;
  const user = users.find(
    (u) => u.username === username && u.password === password
  );

  if (!user) {
    return res.json({ success: false, message: "Invalid login" });
  }

  res.json({ success: true, username: user.username, role: user.role });
});

/* ---------- STUDENTS ---------- */
app.get("/divisions", async (req, res) => {
  const divisions = await Student.distinct("div", { std: req.query.std });
  res.json({ divisions });
});

app.get("/students", async (req, res) => {
  const students = await Student.find(req.query).sort({ roll: 1 });
  res.json({ students });
});

/* =======================================================
   ATTENDANCE LOCK CHECK (FOR FLUTTER)
   ======================================================= */
app.get("/attendance/check-lock", async (req, res) => {
  const { std, div, date } = req.query;
  const lock = await AttendanceLock.findOne({ std, div, date });
  res.json({ locked: lock?.locked || [] });
});

/* =======================================================
   POST ATTENDANCE (FINAL FIXED LOGIC)
   ======================================================= */
app.post("/attendance", async (req, res) => {
  try {
    const { date, attendance } = req.body;

    if (!date || !Array.isArray(attendance)) {
      return res.status(400).json({ success: false, message: "Invalid data" });
    }

    const parsedDate = new Date(date);
    parsedDate.setHours(0, 0, 0, 0);

    const dateStr =
      parsedDate.getFullYear() +
      "-" +
      String(parsedDate.getMonth() + 1).padStart(2, "0") +
      "-" +
      String(parsedDate.getDate()).padStart(2, "0");

    // 🔒 Load existing locks ONCE
    const existingLock = await AttendanceLock.findOne({
      std: attendance[0].std,
      div: attendance[0].div,
      date: dateStr,
    });

    const alreadyLocked = existingLock?.locked || [];

    const attendanceToSave = [];
    const rollsToLock = [];
    const smsJobs = [];

    let sent = 0;
    let failed = 0;

    for (const entry of attendance) {
      // ⛔ Skip locked students
      if (alreadyLocked.includes(entry.roll)) continue;

      attendanceToSave.push({
        studentId: entry.studentId,
        std: entry.std,
        div: entry.div,
        roll: entry.roll,
        date: parsedDate,
        present: entry.present,
      });

      rollsToLock.push(entry.roll);

      // 📩 Send SMS only if ABSENT
      if (!entry.present) {
        const message = `Dear Parents, Your child, ${entry.name} remained absent in school today.,Vidyakunj School`;

        smsJobs.push(
          axios
            .get(process.env.GUPSHUP_URL, {
              params: {
                method: "SendMessage",
                send_to: entry.mobile,
                msg: message,
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
    }

    // ✅ Save attendance FIRST
    if (attendanceToSave.length > 0) {
      await Attendance.insertMany(attendanceToSave, { ordered: false });
    }

    // ✅ Lock ONLY saved rolls
    if (rollsToLock.length > 0) {
      await AttendanceLock.updateOne(
        { std: attendance[0].std, div: attendance[0].div, date: dateStr },
        { $addToSet: { locked: { $each: rollsToLock } } },
        { upsert: true }
      );
    }

    // ✅ Send SMS LAST
    await Promise.all(smsJobs);

    res.json({
      success: true,
      smsSummary: { sent, failed },
    });
  } catch (err) {
    console.error("❌ Attendance Error:", err);
    res.status(500).json({ success: false, error: err.message });
  }
});

/* =======================================================
   START SERVER
   ======================================================= */
const PORT = process.env.PORT || 10000;
app.listen(PORT, () =>
  console.log("🚀 Vidyakunj Backend running on port", PORT)
);
