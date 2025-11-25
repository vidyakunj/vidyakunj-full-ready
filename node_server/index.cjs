const express = require("express");
const cors = require("cors");
const bodyParser = require("body-parser");
const fetch = require("node-fetch");

const app = express();
app.use(cors());
app.use(bodyParser.json());

// Test route
app.get("/", (req, res) => {
  res.send("SMS Server is running");
});
// ---------------- DIVISIONS API ----------------

app.get("/divisions", (req, res) => {
  const std = (req.query.std || "").toString().trim();
  const stdNum = parseInt(std);

  let divisions = [];
  
// ---------------- STUDENTS API ----------------

app.get("/students", (req, res) => {
  const std = (req.query.std || "").trim();
  const div = (req.query.div || "").trim();

  // TEMP DEMO STUDENT DATA (Later connect to DB)
  const demoStudents = {
    "1-A": [
      { roll: 1, name: "Patil Manohar", mobile: "8980994984" },
      { roll: 2, name: "Diya Patil", mobile: "919265635968" }
    ],

    "2-A": [
      { roll: 1, name: "Student 1", mobile: "9999999999" },
      { roll: 2, name: "Student 2", mobile: "9999998888" }
    ]
  };

  const key = `${std}-${div}`;
  const students = demoStudents[key] || [];

  return res.json({
    success: true,
    std,
    div,
    students
  });
});

  // Nursery, LKG, UKG → 2 divisions always
  if (std === "Nursery" || std === "LKG" || std === "UKG") {
    divisions = ["A", "B"];
  }

  // STD 1 to 8 → 4 divisions (A, B, C, D)
  else if (stdNum >= 1 && stdNum <= 8) {
    divisions = ["A", "B", "C", "D"];
  }

  // STD 9, 10, 11, 12 → 3 divisions (A, B, C)
  else if (stdNum >= 9 && stdNum <= 12) {
    divisions = ["A", "B", "C"];
  }

  return res.json({
    success: true,
    class: std,
    divisions: divisions,
  });
});

app.post("/send-sms", async (req, res) => {
  const { mobile, studentName } = req.body;

  if (!mobile || !studentName) {
    return res.status(400).json({ success: false, error: "Missing data" });
  }

  // EXACT DLT TEMPLATE (1 variable)
  // Dear Parents,Your child, {#var#} remained absent in school today.,Vidyakunj School
  const message =
    `Dear Parents,Your child, ${studentName} remained absent in school today.,Vidyakunj School`;

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

    res.json({
      success: result.toLowerCase().includes("success"),
      response: result
    });
  } catch (err) {
    console.error("SMS ERROR:", err);
    res.status(500).json({ success: false, error: "Server error" });
  }
});

const PORT = process.env.PORT || 10000;
app.listen(PORT, () => console.log("Server running on port " + PORT));
