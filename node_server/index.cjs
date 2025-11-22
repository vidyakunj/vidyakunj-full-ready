const express = require("express");
const cors = require("cors");

const app = express();
app.use(express.json());
app.use(cors());

// --- SMS API ---
app.post("/send-sms", (req, res) => {
    const { mobile, studentName } = req.body;

    console.log("Received body:", req.body);

    if (!mobile || !studentName) {
        return res.status(400).json({
            success: false,
            error: "Missing data",
            received: req.body
        });
    }

    // Here you can integrate Fast2SMS / MSG91 / TextLocal etc.
    console.log(`SMS ready → ${studentName} → ${mobile}`);

    return res.json({
        success: true,
        message: "SMS sent successfully!"
    });
});

// --- START SERVER ---
app.listen(10000, () => {
    console.log("Server running on port 10000");
});
