const express = require("express");
const cors = require("cors");
const bodyParser = require("body-parser");
const fetch = require("node-fetch");

const app = express();
app.use(cors());
app.use(bodyParser.json());

app.get("/", (req, res) => {
  res.send("SMS Server is running");
});

app.post("/send-sms", async (req, res) => {
  const { mobile, var1, var2 } = req.body;

  if (!mobile || (!var1 && !var2)) {
    return res.status(400).json({
      success: false,
      error: "Missing data"
    });
  }

  // EXACT DLT APPROVED FORMAT
  const message = `Dear Parents,Your child, ${var1}${var2} remained absent in school today.,Vidyakunj School`;

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
      res.json({ success: true, response: result });
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
