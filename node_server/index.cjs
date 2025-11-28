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
const MONGO_URL = process.env.MONGODB_URI;  // 🔥 CORRECT ENV NAME

mongoose
  .connect(MONGO_URL)
  .then(() => console.log("MongoDB Connected"))
  .catch((err) => console.log("Mongo Error:", err));

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
// ROOT ROUTE (fix Cannot GET /)
// ---------------------------
app.get("/", (req, res) => {
  res.send("✅ Vidyakunj SMS Server is Running");
});

// ---------------------------
// API — Get Divisions
// ---------------------------
app.get("/divisions", async (req, res) => {
  try {
    const { std } = req.query;

    // TEMPORARY FIX (remove later)
    const defaultDivs = ["A", "B", "C", "D"];

    const divisions = await Student.distinct("div", { std });

    if (!divisions || divisions.length === 0) {
      return res.json({ divisions: defaultDivs });
    }

    return res.json({ divisions });
  } catch (err) {
    return res.status(500).json({ error: err });
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
    return res.status(500).json({ error: err.message });
  }
});

// ---------------------------
// API — Send SMS (GUPSHUP)
// ---------------------------
app.post("/send-sms", async (req, res) => {
  try {
    const { mobile, studentName } = req.body;

    const url = process.env.GUPSHUP_URL;
    const user = process.env.GUPSHUP_USER;
    const password = process.env.GUPSHUP_PASSWORD;
    const sender = process.env.GUPSHUP_SENDER;

    const smsText = `Your child ${studentName} is absent today.`;

    const fullUrl = `${url}?method=sendMessage&send_to=${mobile}&msg=${encodeURIComponent(
      smsText
    )}&format=json&userid=${user}&password=${password}&v=1.1&auth_scheme=plain&extra=SID:${sender}`;

    const response = await axios.get(fullUrl);

    return res.json({ success: true, data: response.data });
  } catch (err) {
    return res.json({ success: false, error: err.message });
  }
});

// ---------------------------
// START SERVER
// ---------------------------
const PORT = process.env.PORT || 5000;
app.listen(PORT, () => console.log(`Server running on port ${PORT}`));
