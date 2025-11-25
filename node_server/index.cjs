const express = require("express");
const cors = require("cors");
const bodyParser = require("body-parser");
const fetch = require("node-fetch");

const app = express();
app.use(cors());
app.use(bodyParser.json());

// ---------------------------------------------------
// TEST ROUTE
// ---------------------------------------------------
app.get("/", (req, res) => {
  res.send("SMS Server is running");
});

// ---------------------------------------------------
// DIVISIONS API
// ---------------------------------------------------
app.get("/divisions", (req, res) => {
  const std = (req.query.std || "").trim();
  const num = parseInt(std);

  let divisions = [];

  if (num >= 1 && num <= 8) {
    divisions = ["A", "B", "C", "D"];
  } else if (num >= 9 && num <= 12) {
    divisions = ["A", "B", "C"];
  }

  res.json({
    success: true,
    std,
    divisions,
  });
});

// ---------------------------------------------------
// STUDENTS API (FULL STD 1–12 DATA)
// ---------------------------------------------------
const demoStudents = {

  ### PASTE THE GENERATED STUDENT JSON HERE ###
  ### (from the python result above) ###
  ### It starts with "1-A": [ and ends with "12-C": [ ... ] ###

};

app.get("/students", (req, res) => {
  const std = (req.query.std || "").trim();
  const div = (req.query.div || "").trim();

  const key = `${std}-${div}`;
  const students = demoStudents[key] || [];

  res.json({
    success: true,
    std,
    div,
    students,
  });
});

// ---------------------------------------------------
// SEND SMS API
// ---------------------------------------------------
app.post("/send-sms", async (req, res) => {
  const { mobile, studentName } = req.body;

  if (!mobile || !studentName) {
    return res.status(400).json({ success: false, error: "Missing data" });
  }

  const message = `Dear Parents,Your child, ${studentName} remained absent in school today.,Vidyakunj School`;

  const apiUrl = "https://enterprise.smsgupshup.com/GatewayAPI/rest";

  const params = new URLSearchParams({
    method: "SendMessage",
    send_to: mobile,
    msg: message,
    msg_type: "TEXT",
    userid: "2000176036",
    password: "rkbJIg7O0",
    auth_scheme: "PLAIN",
    v: "1.1",
  });

  try {
    const response = await fetch(apiUrl + "?" + params.toString());
    const result = await response.text();

    res.json({
      success: result.toLowerCase().includes("success"),
      response: result,
    });
  } catch (err) {
    res.status(500).json({ success: false, error: "Server error" });
  }
});

// ---------------------------------------------------
const PORT = process.env.PORT || 10000;
app.listen(PORT, () => console.log("Server running on port " + PORT));
