const express = require("express");
const cors = require("cors");
const bodyParser = require("body-parser");

const app = express();
app.use(cors());
app.use(bodyParser.json());

// TEST ROUTE
app.get("/", (req, res) => {
  res.send("SMS Server is running");
});

// SEND SMS ROUTE
app.post("/send-sms", async (req, res) => {
  const { mobile, value } = req.body;

  if (!mobile || !value) {
    return res.status(400).json({ success: false, error: "Missing data" });
  }

  // MESSAGE MUST MATCH EXACT TEMPLATE EXACTLY
  const message =
    `Dear Parents,Your child, ${value}${value} remained absent in school today.,Vidyakunj School`;

  const apiUrl = "https://enterprise.smsgupshup.com/GatewayAPI/rest";

  const params = new URLSearchParams({
    method: "SendMessage",
    send_to: mobile,
    msg: message,
    msg_type: "TEXT",
    userid: "2000176036",
    password: "rkbJIg7O0",
    auth_scheme: "PLAIN",
    v: "1.1"
  });

  try {
    const response = await fetch(apiUrl + "?" + params.toString(), {
      method: "GET",
    });

    const result = await response.text();
    console.log("GupShup Response:", result);

    if (result.includes("success") || result.includes("SUCCESS")) {
      res.json({ success: true });
    } else {
      res.json({ success: false, response: result });
    }
  } catch (error) {
    console.error("SMS ERROR:", error);
    res.status(500).json({ success: false, error: "Server error" });
  }
});

// PORT
const PORT = process.env.PORT || 10000;
app.listen(PORT, () => console.log("Server running on " + PORT));
