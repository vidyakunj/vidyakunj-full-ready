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
   UPLOAD CSV
   ======================================================= */
app.post("/upload-csv", async (req, res) => {
  try {
    const { std, div, csv } = req.body;

    if (!std || !div || !csv) {
      return res.status(400).json({ success: false, error: "Missing data" });
    }

    const rows = csv.split("\n").map((line) => line.split(","));
    const records = rows.slice(1);

    for (let r of records) {
      if (r.length >= 4) {
        const roll = parseInt(r[0]);
        const name = r[1];
        const mobile = r[3];

        if (roll && name && mobile) {
          await Student.updateOne(
            { std, div, roll },
            { $set: { name, mobile } },
            { upsert: true }
          );
        }
      }
    }

    res.json({ success: true });
  } catch (err) {
    res.status(500).json({ success: false, error: err.message });
  }
});

/* =======================================================
   DOWNLOAD CSV
   ======================================================= */
app.get("/download-csv", async (req, res) => {
  const { std, div } = req.query;

  if (!std || !div) {
    return res.status(400).send("Missing STD or DIV");
  }

  const students = await Student.find({ std, div }).sort({ roll: 1 });

  let csv = "roll,name,mobile\n";
  students.forEach((s) => {
    csv += `${s.roll},${s.name},${s.mobile}\n`;
  });

  res.header("Content-Type", "text/csv");
  res.attachment(`${std}-${div}-students.csv`);
  res.send(csv);
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
   GET ATTENDANCE SUMMARY BY DATE + STD + DIV
   ======================================================= */
app.get("/attendance-summary", async (req, res) => {
  try {
    const { date, std, div } = req.query;
    if (!date || !std || !div) {
      return res.status(400).json({ success: false, message: "Missing query params" });
    }

    const parsedDate = new Date(date);
    const startOfDay = new Date(parsedDate.setHours(0, 0, 0, 0));
    const endOfDay = new Date(parsedDate.setHours(23, 59, 59, 999));

    const records = await Attendance.find({
      date: { $gte: startOfDay, $lte: endOfDay },
      std,
      div
    });

    const total = records.length;
    const present = records.filter(r => r.present).length;
    const absent = total - present;

    res.json({ total, present, absent });
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
