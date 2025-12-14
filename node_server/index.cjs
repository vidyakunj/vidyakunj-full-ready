/* =======================================================
   VIDYAKUNJ SMS + ATTENDANCE BACKEND
   Node.js + Express + MongoDB + Gupshup
   ======================================================= */
const compression = require("compression");
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
app.use(compression());
console.log("✅ Compression Middleware Applied");

/* =======================================================
   MONGO CONNECTION
   ======================================================= */
const MONGO_URL = process.env.MONGO_URL || process.env.MONGODB_URI;

mongoose
  .connect(MONGO_URL)
  .then(() => console.log("✅ MongoDB Connected"))
  .catch((err) => console.log("❌ Mongo Error:", err));

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
   ATTENDANCE LOCK SCHEMA (NEW)
   Prevents teacher from marking same student again
   ======================================================= */

const attendanceLockSchema = new mongoose.Schema({
  std: String,          // Standard (e.g., "9")
  div: String,          // Division (e.g., "D")
  date: String,         // "YYYY-MM-DD"
  locked: [Number],     // Array of roll numbers already marked
});

const AttendanceLock = mongoose.model("attendance_locks", attendanceLockSchema);

mongoose.connection.once("open", () => {
  console.log("🔌 MongoDB connection open");
  Student.collection.createIndex({ std: 1, div: 1 });
  Attendance.collection.createIndex({ std: 1, div: 1, date: 1 });
  Attendance.collection.createIndex({ studentId: 1, date: 1 });
  console.log("📌 MongoDB indexes ensured");
});

/* =======================================================
   ROUTES
   ======================================================= */
app.post("/login", (req, res) => {
  const { username, password } = req.body;
  const user = users.find((u) => u.username === username && u.password === password);
  if (!user) return res.json({ success: false, message: "Invalid username or password" });
  res.json({ success: true, username: user.username, role: user.role });
});

app.get("/divisions", async (req, res) => {
  try {
    const { std } = req.query;
    const divisions = await Student.distinct("div", { std });
    res.json({ divisions });
  } catch (err) {
    res.status(500).json({ error: err });
  }
});

app.get("/students", async (req, res) => {
  try {
    const { std, div } = req.query;
    const students = await Student.find({ std, div }).sort({ roll: 1 });
    res.json({ students });
  } catch (err) {
    res.status(500).json({ error: err });
  }
});

app.get("/students/:id", async (req, res) => {
  try {
    const student = await Student.findById(req.params.id);
    if (!student) return res.status(404).json({ success: false, message: "Student not found" });
    res.json({ success: true, student });
  } catch (err) {
    res.status(500).json({ success: false, error: err.message });
  }
});

app.put("/students/:id", async (req, res) => {
  try {
    const { name, roll, mobile, std, div } = req.body;
    const updated = await Student.findByIdAndUpdate(req.params.id, { name, roll, mobile, std, div }, { new: true, runValidators: true });
    if (!updated) return res.status(404).json({ success: false, message: "Student not found" });
    res.json({ success: true, student: updated });
  } catch (err) {
    res.status(500).json({ success: false, error: err.message });
  }
});

app.delete("/students/:id", async (req, res) => {
  try {
    const deleted = await Student.findByIdAndDelete(req.params.id);
    if (!deleted) return res.status(404).json({ success: false, message: "Student not found" });
    res.json({ success: true, message: "Student deleted successfully" });
  } catch (err) {
    res.status(500).json({ success: false, error: err.message });
  }
});

app.post("/students", async (req, res) => {
   console.log("📩 Attendance POST Payload:", JSON.stringify(req.body, null, 2));
  try {
    const { name, roll, mobile, std, div } = req.body;
    if (!name || !roll || !mobile || !std || !div)
      return res.status(400).json({ success: false, message: "Missing fields" });
    const existing = await Student.findOne({ std, div, roll });
    if (existing)
      return res.status(400).json({ success: false, message: "Student with same roll already exists" });
    const newStudent = new Student({ name, roll, mobile, std, div });
    await newStudent.save();
    res.json({ success: true, student: newStudent });
  } catch (err) {
    res.status(500).json({ success: false, error: err.message });
  }
});

app.post("/students/bulk", async (req, res) => {
  try {
    const { students } = req.body;
    if (!students || !Array.isArray(students))
      return res.status(400).json({ success: false, message: "Invalid students array" });
    const inserted = await Student.insertMany(students, { ordered: false });
    res.json({ success: true, insertedCount: inserted.length });
  } catch (err) {
    res.status(500).json({ success: false, error: err.message });
  }
});

app.get("/students-all", async (req, res) => {
  try {
    const allStudents = await Student.find().sort({ std: 1, div: 1, roll: 1 });
    res.json({ success: true, students: allStudents });
  } catch (err) {
    res.status(500).json({ success: false, error: err.message });
  }
});

/* =======================================================
   SEND SMS USING GUPSHUP
   ======================================================= */
app.post("/send-sms", async (req, res) => {
  const { mobile, studentName } = req.body;
  if (!mobile || !studentName)
    return res.status(400).json({ success: false, error: "Missing data" });

  const message = `Dear Parents, Your child, ${studentName} remained absent in school today.,Vidyakunj School`;
                   
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
   POST ATTENDANCE + SEND SMS IF ABSENT
   ======================================================= */
app.post("/attendance", async (req, res) => {
  try {
    console.log("📩 Attendance POST Payload:", JSON.stringify(req.body, null, 2));

    const { date, attendance } = req.body;

    if (!date || !attendance) {
      return res.status(400).json({ success: false, message: "Missing data" });
    }

    const parsedDate = new Date(date);
    parsedDate.setHours(0, 0, 0, 0);
    const nextDay = new Date(parsedDate);
    nextDay.setDate(parsedDate.getDate() + 1);

    let sent = 0,
      failed = 0;

    const newEntries = [];
    const smsPromises = [];

    for (const entry of attendance) {
      const alreadyExists = await Attendance.findOne({
        studentId: entry.studentId,
        date: { $gte: parsedDate, $lt: nextDay },
      });

      if (!alreadyExists) {
        newEntries.push({
          studentId: entry.studentId,
          std: entry.std,
          div: entry.div,
          roll: entry.roll,
          date: parsedDate,
          present: entry.present,
        });

        if (!entry.present) {
          const message = `Dear Parents, Your child, ${entry.name} remained absent in school today.,Vidyakunj School`;

          const params = {
            method: "sendMessage",
            send_to: entry.mobile,
            msg: message,
            msg_type: "TEXT",
            userid: process.env.GUPSHUP_USER,
            password: process.env.GUPSHUP_PASSWORD,
            auth_scheme: "plain",
            v: "1.1",
          };

          smsPromises.push(
            axios
              .get(process.env.GUPSHUP_URL, { params })
              .then((res) => {
                if (res.data.toLowerCase().includes("success")) sent++;
                else failed++;
              })
              .catch(() => failed++)
          );
        }
      }
    }

    if (newEntries.length) await Attendance.insertMany(newEntries);
    await Promise.all(smsPromises);

    res.json({ success: true, smsSummary: { sent, failed } });
  } catch (err) {
    console.error("❌ Error saving attendance:", err);
    res.status(500).json({ success: false, error: err.message });
  }
});

/* =======================================================
   START SERVER
   ======================================================= */
const PORT = process.env.PORT || 10000;
app.listen(PORT, () => console.log("🚀 Vidyakunj Backend running on port " + PORT));
