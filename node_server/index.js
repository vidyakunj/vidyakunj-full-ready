const express = require("express");
const fetch = require("node-fetch");
const cors = require("cors");

const app = express();
app.use(cors());
app.use(express.json());

// =============================
// GUPSHUP CONFIG
// =============================
const USER_ID = "2000176036"; 
const PASSWORD = process.env.GUPSHUP_PASSWORD; 
const SENDER_ID = "VKSMIS";

// =============================
// SEND SMS API
// =============================
app.post("/send-sms", async (req, res) => {
  try {
    const { phone, message } = req.body;

    const url = `https://enterprise.smsgupshup.com/GatewayAPI/rest?method=SendMessage&send_to=${phone}&msg=${encodeURIComponent(
      message
    )}&msg_type=TEXT&userid=${USER_ID}&auth_scheme=plain&password=${PASSWORD}&v=1.1&format=text&extra=SenderId=${SENDER_ID}`;

    const response = await fetch(url);
    const text = await response.text();

    res.json({ success: true, api_response: text });
  } catch (err) {
    res.json({ success: false, error: err.toString() });
  }
});

// SERVER START
app.listen(3000, () => {
  console.log("SMS Server running on port 3000");
});
