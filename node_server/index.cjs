import express from "express";
import cors from "cors";

const app = express();
app.use(express.json());
app.use(cors());

app.post("/send-sms", (req, res) => {
    const { mobile, studentName } = req.body;

    console.log("Received:", req.body);  // DEBUG

    if (!mobile || !studentName) {
        return res.status(400).json({
            success: false,
            error: "Missing data",
            received: req.body
        });
    }

    // 👇 Here you will send SMS using Fast2SMS OR any provider
    console.log(`SMS ready → ${studentName} → ${mobile}`);

    return res.json({
        success: true,
        message: "SMS sent successfully!",
    });
});

app.listen(10000, () => {
    console.log("Server running on 10000");
});
