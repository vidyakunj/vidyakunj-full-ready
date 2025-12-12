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
   Remaining Routes and Logic
   ======================================================= */
// Leave the rest of your routes as-is — you've already pasted them and they look good

/* =======================================================
   START SERVER
   ======================================================= */
const PORT = process.env.PORT || 10000;
app.listen(PORT, () =>
  console.log("🚀 Vidyakunj Backend running on port " + PORT)
);
