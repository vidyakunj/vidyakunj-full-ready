const express = require("express");
const cors = require("cors");
const bodyParser = require("body-parser");
const fetch = (...args) => import('node-fetch').then(({default: fetch}) => fetch(...args));

const app = express();
app.use(cors());
app.use(bodyParser.json());

// TEST ROUTE
app.get("/", (req, res) => {
  res.send("SMS Server is running");
});

// SEND SMS ROUTE (GUPSHUP ENTERPRISE)
app.post("/send-sms", async (req, res) => {
  const { mobile, message } = req.body;

  if (!mobile || !message) {
    return res.status(400).json({ success: false, error: "Missing data" });
  }

  const apiUrl = "https://enterprise.smsgupshup.com/GatewayAPI/rest";

  const params = new URLSearchParams();
  params.append("method", "SendMessage");
  params.append("send_to", mobile);
  params.append("msg", message);
  params.append("msg_type", "TEXT");
  params.append("userid", "2000176036");
  params.append("password", "Iken@123");
  params.append("auth_scheme", "PLAIN");
  params.append("v", "1.1");

  try {
    const fullUrl = apiUrl + "?" + params.toString();

    console.log("Sending to URL:", fullUrl);

    const response = await fetch(fullUrl, {
      method: "GET",
    });

    const result = await response.text();
    console.log("SMS API Response:", result);

    // Check success response format from GupShup
    if (result.toLowerCase().includes("success")) {
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
