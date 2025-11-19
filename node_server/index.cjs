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

// ************  SMS API ROUTE  ************
app.post("/send-sms", async (req, res) => {
  try {
    const { phone, message } = req.body;

    const USERID = "2000176036";
    const PASSWORD = "Iken@123";
    const SENDERID = "VKSMIS";

    // Encode message for URL
    const encodedMessage = encodeURIComponent(message);

    const apiUrl =
      `https://enterprise.smsgatewayhub.com/Enterprise/EnterpriseSMSAPI.jsp?` +
      `UserId=${USERID}&Password=${PASSWORD}&SenderId=${SENDERID}` +
      `&MobileNo=${phone}&Message=${encodedMessage}&EntityId=1701168990968610308&TemplateId=1707168991022513651`;

    const response = await fetch(apiUrl);
    const text = await response.text();

    console.log("SMS API Response:", text);
    res.json({ success: true, response: text });
  } catch (err) {
    console.error(err);
    res.status(500).json({ success: false, error: err.toString() });
  }
});
// *******************************************

const PORT = process.env.PORT || 10000;
app.listen(PORT, () => console.log("Server running on " + PORT));
