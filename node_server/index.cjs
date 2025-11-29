// ---------------------------
// Vidyakunj SMS Backend
// Node.js + Express + MongoDB + Gupshup SMS
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

// ---------------------------------------------------
// SEND SMS — GUPSHUP
// ---------------------------------------------------
app.post("/send-sms", async (req, res) => {
  try {
    const { mobile, studentName } = req.body;

    if (!mobile || !studentName) {
      return res
        .status(400)
        .json({ success: false, error: "Missing SMS data" });
    }

    const msg = `Dear Parents, Your child ${studentName} is absent today. - Vidyakunj School`;

    // Read from Render Environment Variables
    const userid = process.env.GUPSHUP_USER;
    const password = process.env.GUPSHUP_PASSWORD;
    const sender = process.env.GUPSHUP_SENDER;
    const apiUrl = process.env.GUPSHUP_URL;

    const url =
      apiUrl +
      "?" +
      new URLSearchParams({
        method: "SendMessage",
        send_to: mobile,
        msg: msg,
        msg_type: "TEXT",
        userid: userid,
        password: password,
        auth_scheme: "PLAIN",
        v: "1.1",
        format: "text",
        extra: `sender=${sender}`,
      }).toString();

    const response = await axios.get(url);

    return res.json({
      success: true,
      response: response.data,
    });
  } catch (err) {
    return res.json({
      success: false,
      error: err.message,
    });
  }
});

// ---------------------------
// START SERVER
// ---------------------------
const PORT = process.env.PORT || 10000;
app.listen(PORT, () => console.log(`Server running on port ${PORT}`));
