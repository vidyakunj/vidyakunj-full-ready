/* =======================================================
   VIDYAKUNJ SMS + ATTENDANCE BACKEND
   FINAL – STABLE, LATE ≠ ABSENT, DLT SAFE
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

/* ================= LOGIN ================= */
app.post("/login", (req, res) => {
  const user = users.find(
    u => u.username === req.body.username && u.password === req.body.password
  );
  if (!user) return res.json({ success: false });
  res.json({ success: true, role: user.role });
});

/* ================= BASIC ================= */
app.get("/divisions", async (req, res) => {
  const divisions = await Student.distinct("div", { std: req.query.std });
  res.json({ divisions });
});

app.get("/students", async (req, res) => {
  const students = await Student.find(req.query).sort({ roll: 1 });
  res.json({ students });
});

/* ================= ATTENDANCE SAVE ================= */
app.post("/attendance", async (req, res) => {
  try {
    const { date, attendance } = req.body;

    const parsedDate = new Date(date);
    parsedDate.setHours(0, 0, 0, 0);

    for (const e of attendance) {
      await Attendance.updateOne(
        {
          studentId: e.studentId,
          std: e.std,
          div: e.div,
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

      /* ================= DLT SMS (UNCHANGED) ================= */
      if (e.present === false) {
        await axios.post(
          "https://enterprise.smsgupshup.com/GatewayAPI/rest",
          null,
          {
            params: {
              method: "SendMessage",
              send_to: e.mobile,
              msg: `Dear Parents,Your child, ${studentName} remained absent in school today.,Vidyakunj School`,
              msg_type: "TEXT",
              userid: process.env.GUPSHUP_USERID,
              password: process.env.GUPSHUP_PASSWORD,
              auth_scheme: "PLAIN",
              v: "1.1",
              format: "text",
            },
          }
        );
      }
    }

    res.json({ success: true });
  } catch (err) {
    console.error("Attendance Error:", err);
    res.status(500).json({ success: false });
  }
});

/* ================= ATTENDANCE CHECK (ONLY ONE) ================= */
app.get("/attendance/check-lock", async (req, res) => {
  try {
    const { std, div, date } = req.query;

    const parsedDate = new Date(date);
    parsedDate.setHours(0, 0, 0, 0);

    const records = await Attendance.find({ std, div, date: parsedDate });

    const absent = [];
    const late = [];

    for (const r of records) {
      if (r.present === false) absent.push(r.roll);
      else if (r.present === true && r.late === true) late.push(r.roll);
    }

    res.json({ absent, late });
  } catch (err) {
    console.error("Check Error:", err);
    res.json({ absent: [], late: [] });
  }
});

/* ================= START ================= */
app.listen(process.env.PORT || 10000, () =>
  console.log("🚀 Server running")
);
