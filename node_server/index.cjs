// ---------------------------
// Vidyakunj SMS Backend
// Node.js + Express + MongoDB
// ---------------------------

const express = require("express");
const cors = require("cors");
const bodyParser = require("body-parser");
const mongoose = require("mongoose");
require("dotenv").config();
const axios = require("axios");

// ---------------------------
// APP SETUP
// ---------------------------
const app = express();
app.use(cors());
app.use(bodyParser.json());

// ---------------------------
// MONGO CONNECTION
// ---------------------------

const MONGO_URL = process.env.MONGO_URL || process.env.MONGODB_URI;


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
// API — Get Divisions
// ---------------------------
app.get("/divisions", async (req, res) => {
  try {
    const { std } = req.query;
    const divisions = await Student.distinct("div", { std });
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
    return res.status(500).json({ error: err });
  }
});

// ---------------------------
// API — Send SMS
// ---------------------------
// ---------------------------------------------------
// SEND SMS API  (GUPSHUP)
// ---------------------------------------------------
app.post("/send-sms", async (req, res) => {
  try {
    const { mobile, studentName } = req.body;

    if (!mobile || !studentName) {
      return res.status(400).json({ success: false, error: "Missing data" });
    }

    const message = `Dear Parents, Your child ${studentName} remained absent today. - Vidyakunj School`;

    const params = new URLSearchParams({
      method: "SendMessage",
      send_to: mobile,
      msg: message,
      msg_type: "TEXT",
      userid: process.env.GUPSHUP_USER,
      password: process.env.GUPSHUP_PASSWORD,
      auth_scheme: "PLAIN",
      v: "1.1",
      format: "text",
    });

    const apiUrl = process.env.GUPSHUP_URL;

    const response = await fetch(apiUrl + "?" + params.toString());
    const result = await response.text();

    return res.json({
      success: result.toLowerCase().includes("success"),
      response: result,
    });

  } catch (err) {
    return res.status(500).json({ success: false, error: err.message });
  }
});


// ---------------------------
// START SERVER
// ---------------------------
const PORT = process.env.PORT || 5000;
app.listen(PORT, () => console.log(`Server running on port ${PORT}`));
