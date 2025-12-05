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
   SIMPLE LOGIN USERS (Option 1)
   ======================================================= */
const users = [
  { username: "teacher1", password: "1234", role: "teacher" },
  { username: "mamta", password: "1234", role: "teacher" },
  { username: "admin", password: "admin123", role: "admin" }
];

/* =======================================================
   APP SETUP
   ======================================================= */
const app = express();
app.use(cors());
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
   LOGIN API  (Simple Authentication)
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
