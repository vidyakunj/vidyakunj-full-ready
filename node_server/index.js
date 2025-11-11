import express from "express";
import fetch from "node-fetch";
import bodyParser from "body-parser";

const app = express();
const PORT = process.env.PORT || 10000;

app.use(bodyParser.json());

app.post("/send-sms", async (req, res) => {
  const { phone, message } = req.body;

  const userId = "2000176036";
  const password = "rkbJIg7O0";
  const senderId = "VKSNVS";

  try {
    const response = await fetch(
      `https://enterprise.smsgupshup.com/GatewayAPI/rest?method=SendMessage&send_to=${phone}&msg=${encodeURIComponent(
        message
      )}&msg_type=TEXT&userid=${userId}&auth_scheme=plain&password=${password}&v=1.1&format=text&mask=${senderId}`
    );
    const text = await response.text();
    res.send(text);
  } catch (err) {
    console.error(err);
    res.status(500).send("Error sending SMS");
  }
});

app.listen(PORT, () => console.log(`✅ Server running on port ${PORT}`));
