const express = require("express");
const cors = require("cors");
const bodyParser = require("body-parser");
const fetch = require("node-fetch");

const app = express();

// CORS + JSON
app.use(cors());
app.use(bodyParser.json());

// TEST
app.get("/", (req, res) => {
  res.send("SMS Server is running");
});

// MAIN SMS ROUTE
app.post("/send-sms", async (req, res) => {
  console.log("Received body:", req.body);

  const { mobile, studentName, phone, message } = req.body;

  // Accept both formats:
  const finalMobile = (mobile || phone || "").toString().trim();

  // If Flutter sends full message, use it. Otherwise build from studentName.
  let finalMessage = message;
  if (!finalMessage) {
    if (studentName) {
      finalMessage = `Dear Parents, Your child, ${studentName} remained absent in school today., Vidyakunj School Navsari`;
    } else {
      finalMessage = `Dear Parents, Your child remained absent in school today., Vidyakunj School Navsari`;
    }
  }

  if (!finalMobile || finalMobile.length < 10) {
    return res.status(400).json({
      success: false,
      error: "Missing or invalid mobile number",
      received: req.body,
    });
  }

  const apiUrl = "https://enterprise.smsgupshup.com/GatewayAPI/rest";

  const params = new URLSearchParams({
    method: "SendMessage",
    send_to: finalMobile,
    msg: finalMessage,
    msg_type: "TEXT",
    userid: "2000176036",
    password: "rkbJIg7O0",
    auth_scheme: "PLAIN",
    v: "1.1",
  });

  try {
    const response = await fetch(apiUrl + "?" + params.toString());
    const result = await response.text();

    console.log("GupShup Response:", result);

    if (result.toLowerCase().includes("success")) {
      return res.json({ success: true, response: result });
    } else {
      return res.json({ success: false, response: result });
    }
  } catch (err) {
    console.error("SMS ERROR:", err);
    return res.status(500).json({ success: false, error: "Server error" });
  }
});

const PORT = process.env.PORT || 10000;
app.listen(PORT, () => console.log("Server running on port " + PORT));
