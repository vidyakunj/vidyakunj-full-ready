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

app.use(
  cors({
    origin: "https://vidyakunj-frontend.onrender.com",
    methods: ["GET", "POST", "OPTIONS"],
    allowedHeaders: ["Content-Type", "Accept"],
    credentials: true,
  })
);
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
const attendanceSchema = new mongoose.Schema(
  {
    studentId: { type: mongoose.Schema.Types.ObjectId, ref: "students", required: true },
    std: String,
    div: String,
    roll: Number,
    date: { type: Date, required: true },
    present: { type: Boolean, default: false },
  },
  { timestamps: true }
);
const Attendance = mongoose.model("attendance", attendanceSchema);

/* =======================================================
   INDEX OPTIMIZATION
   ======================================================= */
async function ensureIndexes() {
  await Student.collection.createIndex({ std: 1, div: 1 });
  await Attendance.collection.createIndex({ std: 1, div: 1, date: 1 });
  await Attendance.collection.createIndex({ studentId: 1, date: 1 });
  console.log("📌 MongoDB indexes ensured");
}
mongoose.connection.once("open", ensureIndexes);

/* =======================================================
   LOGIN API
   ======================================================= */
app.post("/login", (req, res) => {
  const { username, password } = req.body;
  const user = users.find((u) => u.username === username && u.password === password);
  return user
    ? res.json({ success: true, username: user.username, role: user.role })
    : res.json({ success: false, message: "Invalid username or password" });
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
   POST ATTENDANCE + SMS (Parallelized)
   ======================================================= */
app.post("/attendance", async (req, res) => {
  try {
    const { date, attendance } = req.body;
    if (!date || !attendance) return res.status(400).json({ success: false, message: "Missing data" });

    const parsedDate = new Date(date);
    parsedDate.setHours(0, 0, 0, 0);
    const nextDay = new Date(parsedDate);
    nextDay.setDate(parsedDate.getDate() + 1);

    const bulkOps = [];
    const smsPromises = [];

    for (const entry of attendance) {
      const exists = await Attendance.exists({ studentId: entry.studentId, date: { $gte: parsedDate, $lt: nextDay } });
      if (!exists) {
        bulkOps.push({
          insertOne: {
            document: {
              studentId: entry.studentId,
              std: entry.std,
              div: entry.div,
              roll: entry.roll,
              date: parsedDate,
              present: entry.present,
            },
          },
        });

        if (!entry.present) {
          const message = `Dear Parents,Your child, ${entry.name} remained absent in school today.,Vidyakunj School`;
          const params = {
            method: "SendMessage",
            send_to: entry.mobile,
            msg: message,
            msg_type: "TEXT",
            userid: process.env.GUPSHUP_USER,
            password: process.env.GUPSHUP_PASSWORD,
            auth_scheme: "PLAIN",
            v: "1.1",
          };
          smsPromises.push(
            axios.get(process.env.GUPSHUP_URL, { params })
              .then(r => r.data.toLowerCase().includes("success"))
              .catch(() => false)
          );
        }
      }
    }

    if (bulkOps.length) await Attendance.bulkWrite(bulkOps);

    const results = await Promise.all(smsPromises);
    const sent = results.filter(r => r).length;
    const failed = results.length - sent;

    res.json({ success: true, smsSummary: { sent, failed } });
  } catch (err) {
    res.status(500).json({ success: false, error: err.message });
  }
});

/* =======================================================
   CHECK LOCKED STUDENTS
   ======================================================= */
app.get("/attendance/check-lock", async (req, res) => {
  const { std, div, date } = req.query;
  if (!std || !div || !date) return res.status(400).json({ error: "Missing required query params" });

  try {
    const start = new Date(date);
    start.setHours(0, 0, 0, 0);
    const end = new Date(date);
    end.setHours(23, 59, 59, 999);

    const records = await Attendance.find({ std, div, date: { $gte: start, $lte: end }, present: false });
    const locked = records.map((r) => r.roll);
    res.json({ locked });
  } catch (err) {
    res.status(500).json({ error: "Internal server error" });
  }
});

/* =======================================================
   START SERVER
   ======================================================= */
const PORT = process.env.PORT || 10000;
app.listen(PORT, () => console.log("🚀 Vidyakunj Backend running on port " + PORT));
