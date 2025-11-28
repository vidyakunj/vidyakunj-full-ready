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

const MONGO_URL = process.env.MONGODB_URI;   // ✅ FIXED VARIABLE NAME

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
app.post("/send-sms", async (req, res) => {
  try {
    const { mobile, studentName } = req.body;

    const apiKey = process.env.FAST2SMS_KEY;

    const response = await axios.post(
      "https://www.fast2sms.com/dev/bulkV2",
      {
        route: "v3",
        sender_id: "TXTIND",
        message: `Your child ${studentName} is absent today.`,
        language: "english",
        flash: 0,
        numbers: mobile,
      },
      { headers: { authorization: apiKey } }
    );

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
