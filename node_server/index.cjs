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
   INDEX OPTIMIZATION STEP
   ======================================================= */
async function ensureIndexes() {
  await Student.collection.createIndex({ std: 1, div: 1 });
  await Attendance.collection.createIndex({ std: 1, div: 1, date: 1 });
  await Attendance.collection.createIndex({ studentId: 1, date: 1 });
  console.log("📌 MongoDB indexes ensured");
}

mongoose.connection.once("open", () => {
  console.log("🔌 MongoDB connection open");
  ensureIndexes();
});

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
   GET SINGLE STUDENT BY ID (Step 6)
   ======================================================= */
app.get("/students/:id", async (req, res) => {
  try {
    const student = await Student.findById(req.params.id);
    if (!student) return res.status(404).json({ success: false, message: "Student not found" });
    res.json({ success: true, student });
  } catch (err) {
    res.status(500).json({ success: false, error: err.message });
  }
});
// =============================
// STEP 7: UPDATE STUDENT BY ID
// =============================
app.put("/students/:id", async (req, res) => {
  try {
    const { name, roll, mobile, std, div } = req.body;

    const updated = await Student.findByIdAndUpdate(
      req.params.id,
      { name, roll, mobile, std, div },
      { new: true, runValidators: true }
    );

    if (!updated) {
      return res.status(404).json({ success: false, message: "Student not found" });
    }

    res.json({ success: true, student: updated });
  } catch (err) {
    res.status(500).json({ success: false, error: err.message });
  }
});
// =============================
// STEP 8: DELETE STUDENT BY ID
// =============================
app.delete("/students/:id", async (req, res) => {
  try {
    const deleted = await Student.findByIdAndDelete(req.params.id);

    if (!deleted) {
      return res.status(404).json({ success: false, message: "Student not found" });
    }

    res.json({ success: true, message: "Student deleted successfully" });
  } catch (err) {
    res.status(500).json({ success: false, error: err.message });
  }
});

/* =======================================================
   POST ATTENDANCE + SMS
   ======================================================= */
app.post("/attendance", async (req, res) => {
  try {
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
    res.status(500).json({ success: false, error: err.message });
  }
});

/* =======================================================
   CHECK LOCKED STUDENTS
   ======================================================= */
app.get("/attendance/check-lock", async (req, res) => {
  const { std, div, date } = req.query;

  if (!std || !div || !date) {
    return res.status(400).json({ error: "Missing required query params" });
  }

  try {
    const start = new Date(date);
    start.setHours(0, 0, 0, 0);
    const end = new Date(date);
    end.setHours(23, 59, 59, 999);

    const records = await Attendance.find({
      std,
      div,
      date: { $gte: start, $lte: end },
      present: false,
    });

    const locked = records.map((r) => r.roll);
    res.json({ locked });
  } catch (err) {
    res.status(500).json({ error: "Internal server error" });
  }
});

/* =======================================================
   ATTENDANCE REPORT
   ======================================================= */
app.get("/attendance-report", async (req, res) => {
  try {
    const { date } = req.query;
    if (!date) return res.status(400).json({ success: false, message: "Missing date" });

    const parsed = new Date(date);
    const startOfDay = new Date(parsed);
    startOfDay.setHours(0, 0, 0, 0);
    const endOfDay = new Date(parsed);
    endOfDay.setHours(23, 59, 59, 999);

    const pipeline = [
      { $match: { date: { $gte: startOfDay, $lte: endOfDay } } },
      {
        $group: {
          _id: { std: "$std", div: "$div" },
          total: { $sum: 1 },
          present: { $sum: { $cond: ["$present", 1, 0] } },
        },
      },
      {
        $project: {
          _id: 0,
          std: "$_id.std",
          div: "$_id.div",
          total: 1,
          present: 1,
          absent: { $subtract: ["$total", "$present"] },
        },
      },
      { $sort: { std: 1, div: 1 } },
    ];

    const rows = await Attendance.aggregate(pipeline);

    const grand = rows.reduce(
      (acc, r) => {
        acc.total += r.total || 0;
        acc.present += r.present || 0;
        acc.absent += r.absent || 0;
        return acc;
      },
      { total: 0, present: 0, absent: 0 }
    );

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
   SUMMARY FOR ALL CLASSES
   ======================================================= */
app.get("/attendance-summary-all", async (req, res) => {
  try {
    const { date } = req.query;
    if (!date) return res.status(400).json({ success: false, message: "Missing date" });

    const parsedDate = new Date(date);
    const startOfDay = new Date(parsedDate.setHours(0, 0, 0, 0));
    const endOfDay = new Date(parsedDate.setHours(23, 59, 59, 999));

    const records = await Attendance.aggregate([
      {
        $match: {
          date: { $gte: startOfDay, $lte: endOfDay },
        },
      },
      {
        $group: {
          _id: { std: "$std", div: "$div" },
          total: { $sum: 1 },
          present: { $sum: { $cond: [{ $eq: ["$present", true] }, 1, 0] } },
          absent: { $sum: { $cond: [{ $eq: ["$present", false] }, 1, 0] } },
        },
      },
      {
        $project: {
          _id: 0,
          std: "$_id.std",
          div: "$_id.div",
          total: 1,
          present: 1,
          absent: 1,
        },
      },
    ]);

    res.json({ success: true, data: records });
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
