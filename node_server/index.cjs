/* =======================================================
   VIDYAKUNJ SMS + ATTENDANCE BACKEND
   Node.js + Express + MongoDB + Gupshup
   ======================================================= */

const express = require("express");
const cors = require("cors");
const bodyParser = require("body-parser");
const mongoose = require("mongoose");
require("dotenv").config();
const axios = require("axios");

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

app.options("*", cors());

app.use(cors({
  origin: "https://vidyakunj-frontend.onrender.com",
  methods: ["GET", "POST", "OPTIONS"],
  allowedHeaders: ["Content-Type", "Accept"],
  credentials: true
}));
console.log("✅ CORS Middleware Applied");

app.use(bodyParser.json());

/* =======================================================
   MONGO CONNECTION
   ======================================================= */
const MONGO_URL = process.env.MONGO_URL || process.env.MONGODB_URI;

mongoose
  .connect(MONGO_URL)
  .then(() => console.log("✅ MongoDB Connected"))
  .catch((err) => console.log("❌ Mongo Error:", err));

/* =======================================================
   STUDENT SCHEMA
   ======================================================= */
const studentSchema = new mongoose.Schema({
  std: String,
  div: String,
  name: String,
  roll: Number,
  mobile: String,
});

const Student = mongoose.model("students", studentSchema);

/* =======================================================
   ATTENDANCE SCHEMA
   ======================================================= */
const attendanceSchema = new mongoose.Schema({
  studentId: { type: mongoose.Schema.Types.ObjectId, ref: "students", required: true },
  std: String,
  div: String,
  roll: Number,
  date: { type: Date, required: true },
  present: { type: Boolean, default: false },
}, { timestamps: true });

const Attendance = mongoose.model("attendance", attendanceSchema);

/* =======================================================
   LOGIN API
   ======================================================= */
app.post("/login", (req, res) => {
  const { username, password } = req.body;

  const user = users.find(
    (u) => u.username === username && u.password === password
  );

  if (!user) {
    return res.json({
      success: false,
      message: "Invalid username or password",
    });
  }

  return res.json({
    success: true,
    username: user.username,
    role: user.role,
  });
});

/* =======================================================
   GET DIVISIONS
   ======================================================= */
app.get("/divisions", async (req, res) => {
  try {
    const { std } = req.query;
    const divisions = await Student.distinct("div", { std });
    res.json({ divisions });
  } catch (err) {
    res.status(500).json({ error: err });
  }
});

/* =======================================================
   GET STUDENTS
   ======================================================= */
app.get("/students", async (req, res) => {
  try {
    const { std, div } = req.query;
    const students = await Student.find({ std, div }).sort({ roll: 1 });
    res.json({ students });
  } catch (err) {
    res.status(500).json({ error: err });
  }
});

/* =======================================================
   SUBMIT ATTENDANCE (date-wise)
   ======================================================= */
app.post("/attendance", async (req, res) => {
  try {
    const { date, attendance } = req.body;

    if (!date || !attendance) {
      return res.status(400).json({ success: false, message: "Missing data" });
    }

    for (const entry of attendance) {
      await Attendance.updateOne(
        { studentId: entry.studentId, date },
        {
          studentId: entry.studentId,
          std: entry.std,
          div: entry.div,
          roll: entry.roll,
          date,
          present: entry.present
        },
        { upsert: true }
      );
    }

    res.json({ success: true });
  } catch (err) {
    res.status(500).json({ success: false, error: err.message });
  }
});

/* =======================================================
   ATTENDANCE REPORT (per class + grand total)
   ======================================================= */
app.get("/attendance-report", async (req, res) => {
  try {
    const { date } = req.query;
    if (!date) return res.status(400).json({ success: false, message: "Missing date" });

    const parsed = new Date(date);
    const startOfDay = new Date(parsed);
    startOfDay.setHours(0,0,0,0);
    const endOfDay = new Date(parsed);
    endOfDay.setHours(23,59,59,999);

    const pipeline = [
      { $match: { date: { $gte: startOfDay, $lte: endOfDay } } },
      { $group: {
          _id: { std: "$std", div: "$div" },
          total: { $sum: 1 },
          present: { $sum: { $cond: [ "$present", 1, 0 ] } }
      }},
      { $project: {
          _id: 0,
          std: "$_id.std",
          div: "$_id.div",
          total: 1,
          present: 1,
          absent: { $subtract: ["$total", "$present"] }
      }},
      { $sort: { std: 1, div: 1 } }
    ];

    const rows = await Attendance.aggregate(pipeline);

    const grand = rows.reduce((acc, r) => {
      acc.total += r.total || 0;
      acc.present += r.present || 0;
      acc.absent += r.absent || 0;
      return acc;
    }, { total: 0, present: 0, absent: 0 });

    res.json({ success: true, rows, grand });
  } catch (err) {
    res.status(500).json({ success: false, error: err.message });
  }
});

/* =======================================================
   SEND SMS USING GUPSHUP
   ======================================================= */
app.post("/send-sms", async (req, res) => {
  const { mobile, studentName } = req.body;

  if (!mobile || !studentName) {
    return res.status(400).json({ success: false, error: "Missing data" });
  }

  const message = `Dear Parents,Your child, ${studentName} remained absent in school today.,Vidyakunj School`;

  const params = {
    method: "SendMessage",
    send_to: mobile,
    msg: message,
    msg_type: "TEXT",
    userid: process.env.GUPSHUP_USER,
    password: process.env.GUPSHUP_PASSWORD,
    auth_scheme: "PLAIN",
    v: "1.1",
  };

  try {
    const response = await axios.get(process.env.GUPSHUP_URL, { params });

    res.json({
      success: response.data.toLowerCase().includes("success"),
      response: response.data,
    });
  } catch (err) {
    res.status(500).json({ success: false, error: err.message });
  }
});

/* =======================================================
   START SERVER
   ======================================================= */
const PORT = process.env.PORT || 10000;
app.listen(PORT, () =>
  console.log("🚀 Vidyakunj Backend running on port " + PORT)
);
