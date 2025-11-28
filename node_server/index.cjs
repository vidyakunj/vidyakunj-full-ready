// ---------------------------
// Vidyakunj SMS Backend
// Node.js + Express + MongoDB
// ---------------------------

const express = require("express");
const cors = require("cors");
const bodyParser = require("body-parser");
const mongoose = require("mongoose");
const axios = require("axios");
require("dotenv").config();

// ---------------------------
// APP SETUP
// ---------------------------
const app = express();
app.use(cors());
app.use(bodyParser.json());

// ---------------------------
// MONGO CONNECTION
// ---------------------------
// IMPORTANT: your Render variable name is MONGODB_URI
const MONGO_URL = process.env.MONGODB_URI;

if (!MONGO_URL) {
  console.log("❌ MONGODB_URI NOT FOUND");
} else {
  console.log("🔄 Connecting to MongoDB...");
}

mongoose
  .connect(MONGO_URL)
  .then(() => console.log("✅ MongoDB Connected Successfully"))
  .catch((err) => console.log("❌ MongoDB Error:", err));

// ---------------------------
// STUDENT SCHEMA
// ---------------------------
const studentSchema = new mongoose.Schema({
  std: String,
  div: String,
  name: String,
  roll: Number,
  mobile: String,
});

const Student = mongoose.model("students", studentSchema);

// ---------------------------
// API — Get Divisions
// ---------------------------
app.get("/divisions", async (req, res) => {
  try {
    const { std } = req.query;

    const divisions = await Student.distinct("div", { std });

    return res.json({ divisions });
  } catch (err) {
    return res.status(500).json({ error: err.toString() });
  }
});

// ---------------------------
// API — Get Students
// ---------------------------
app.get("/students", async (req, res) => {
  try {
    const { std, div } = req.query;

    const students = await Student.find({ std, div }).sort({ roll: 1 });

    return res.json({ students });
  } catch (err) {
    return res.status(500).json({ error: err.toString() });
  }
});

// ---------------------------
// API — Send SMS (Gupshup)
// ---------------------------
app.post("/send-sms", async (req, res) => {
  try {
    const { mobile, message } = req.body;

    const user = process.env.GUPSHUP_USER;
    const password = process.env.GUPSHUP_PASSWORD;
    const sender = process.env.GUPSHUP_SENDER;
    const url = process.env.GUPSHUP_URL;

    const apiUrl =
      `${url}?method=sendMessage` +
      `&send_to=${mobile}` +
      `&msg=${encodeURIComponent(message)}` +
      `&userid=${user}` +
      `&password=${password}` +
      `&v=1.1&msg_type=TEXT&auth_scheme=PLAIN&extra=SID:${sender}`;

    const response = await axios.get(apiUrl);

    return res.json({ success: true, response: response.data });
  } catch (err) {
    return res.json({ success: false, error: err.toString() });
  }
});

// ---------------------------
// DEFAULT HOME ROUTE
// ---------------------------
app.get("/", (req, res) => {
  res.send("✅ Vidyakunj SMS Server is Running");
});

// ---------------------------
// START SERVER
// ---------------------------
const PORT = process.env.PORT || 5000;
app.listen(PORT, () => console.log(`🚀 Server running on port ${PORT}`));
