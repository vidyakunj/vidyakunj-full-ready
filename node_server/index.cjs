const express = require("express");
const cors = require("cors");
const bodyParser = require("body-parser");
const fetch = require("node-fetch");

const app = express();
app.use(cors());
app.use(bodyParser.json());

// TEST ROUTE
app.get("/", (req, res) => {
  res.send("SMS Server is running");
});

// HEALTH CHECK REQUIRED BY RENDER
app.get("/healthz", (req, res) => {
  res.status(200).send("OK");
});

// SEND SMS ROUTE
app.post("/send-sms", async (req, res) => {
  const { mobile, message } = req.body;

  if (!mobile || !message) {
    return res.status(400).json({ success: false, error: "Missing data" });
  }

  const apiUrl = "https://smslogin.secureapi.com/API/sendSMS";

  const params = new URLSearchParams();
  params.append("username", "2000176036");
  params.append("msg_token", "Iken@123"); 
  params.append("senderid", "VKSMIS");
  params.append("message", message);
  params.append("number", mobile);

  try {
    const response = await fetch(apiUrl, {
      method: "POST",
      body: params
    });

    const result = await response.text();

    console.log("SMS API Response:", result);

    if (result.includes("SMS Sent Successfully")) {
      res.json({ success: true });
    } else {
      res.json({ success: false, response: result });
    }
  } catch (error) {
    console.error("SMS ERROR:", error);
    res.status(500).json({ success: false, error: "Server error" });
  }
});

const PORT = process.env.PORT;
app.listen(PORT, () => console.log("Server running on " + PORT));
