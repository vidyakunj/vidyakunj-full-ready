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

// SEND SMS ROUTE
app.post("/send-sms", async (req, res) => {
  const { mobile, studentName } = req.body;

  if (!mobile || !studentName) {
    return res.status(400).json({ success: false, error: "Missing data" });
  }

  // DLT TEMPLATE: @__123__@@__123__@
  // Variable 1 = name
  // Variable 2 = blank so name appears only once
  const var1 = studentName;
  const var2 = "";

  // This matches EXACTLY your DLT template content
  const message =
    `Dear Parents,Your child, ${var1}${var2} remained absent in school today.,Vidyakunj School`;

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
    const response = await fetch(apiUrl + "?" + params.toString());
    const result = await response.text();

    console.log("GupShup Response:", result);

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
