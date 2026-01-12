const express = require("express");
const app = express();

app.get("/", (req, res) => {
  res.send("Backend OK");
});

app.get("/attendance/summary", (req, res) => {
  res.json({
    success: true,
    test: true,
    query: req.query
  });
});

app.listen(process.env.PORT || 10000, () => {
  console.log("Server running");
});
