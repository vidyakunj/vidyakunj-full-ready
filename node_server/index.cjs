/* =======================================================
   VIDYAKUNJ SMS + AUTH SERVER
   FINAL CORS-FIXED VERSION
   ======================================================= */

const express = require("express");
const cors = require("cors");
const bodyParser = require("body-parser");
const axios = require("axios");
require("dotenv").config();

/* =======================================================
   USERS
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

/* ✅ CORS FIX (REQUIRED FOR FLUTTER WEB LOCALHOST) */
const allowedOrigins = [
  "https://vidyakunj-frontend.onrender.com",
  "http://localhost:3000",
  "http://localhost:53378",
  "http://127.0.0.1:53378",
  "http://localhost:51540",
  "http://localhost:53069",
];

app.use((req, res, next) => {
  const origin = req.headers.origin;

  if (allowedOrigins.includes(origin)) {
    res.setHeader("Access-Control-Allow-Origin", origin);
  }

  res.setHeader(
    "Access-Control-Allow-Headers",
    "Origin, X-Requested-With, Content-Type, Accept"
  );

  res.setHeader(
    "Access-Control-Allow-Methods",
    "GET, POST, OPTIONS"
  );

  if (req.method === "OPTIONS") {
    return res.sendStatus(200);
  }

  next();
});

app.use(express.json());

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

  res.json({
    success: true,
    role: user.role,
    username: user.username,
  });
});

/* =======================================================
   SEND SMS (DLT SAFE)
   ======================================================= */
app.post("/send-sms", async (req, res) => {
  try {
    const { mobile, studentName } = req.body;

    const params = {
      method: "SendMessage",
      send_to: mobile,
      msg: `Dear Parents, Your child, ${studentName} remained absent in school today.,Vidyakunj School`,
      msg_type: "TEXT",
      userid: process.env.GUPSHUP_USER,
      password: process.env.GUPSHUP_PASSWORD,
      auth_scheme: "PLAIN",
      v: "1.1",
    };

    const response = await axios.get(process.env.GUPSHUP_URL, { params });

    res.json({
      success: response.data.toLowerCase().includes("success"),
    });
  } catch (err) {
    console.error(err);
    res.status(500).json({ success: false });
  }
});

/* =======================================================
   START SERVER
   ======================================================= */
const PORT = process.env.PORT || 3000;
app.listen(PORT, () =>
  console.log(`🚀 SMS Server running on port ${PORT}`)
);
