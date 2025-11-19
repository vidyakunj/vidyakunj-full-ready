const express = require("express");
const cors = require("cors");
const bodyParser = require("body-parser");
const fetch = (...args) => import("node-fetch").then(({default: fetch}) => fetch(...args));

const app = express();
app.use(cors());
app.use(bodyParser.json());

// TEST ROUTE
app.get("/", (req, res) => {
  res.send("SMS Server is running");
});

// SEND SMS ROUTE
app.post("/send-sms", async (req, res) => {
  const { mobile, message } = req.body;

  if (!mobile || !message) {
    return res.status(400).json({ success: false, error: "Missing mobile or message" });
  }

  const apiUrl = "https://smslogin.secureapi.com/api/mt/SendSMS";

  const params = new URLSearchParams();
  params.append("user", "2000176036");
  params.append("password", "rkbJIg7O0"); 
  params.append("senderid", "VKSMIS");
  params.append("channel", "Trans");
  params.append("DCS", "0");
  params.append("flashsms", "0");
  params.append("number", mobile);
  params.append("text", message);
  params.append("route", "1");

  try {
    const response = await fetch(apiUrl, {
      method: "POST",
      body: params,
      headers: {
        "Content-Type": "application/x-www-form-urlencoded"
      }
    });

    const result = await response.text();
    console.log("SMS API Response:", result);

    if (result.includes("Message Submitted Successfully")) {
      res.json({ success: true });
    } else {
      res.json({ success: false, response: result });
    }
  } catch (error) {
    console.error("SMS ERROR:", error);
    res.status(500).json({ success: false, error: "Server error" });
  }
});

const PORT = process.env.PORT || 10000;
app.listen(PORT, () => console.log("Server running on " + PORT));
