/* =======================================================
   VIDYAKUNJ SMS + ATTENDANCE BACKEND
   FINAL – ABSENT + LATE (CORRECT)
   ======================================================= */

const compression = require("compression");
const express = require("express");
const cors = require("cors");
const bodyParser = require("body-parser");
const mongoose = require("mongoose");
require("dotenv").config();

/* ================= APP ================= */
const app = express();
app.use(cors({ origin: "*" }));
app.use(bodyParser.json());
app.use(compression());

/* ================= MONGO ================= */
mongoose
  .connect(process.env.MONGO_URL)
  .then(() => console.log("✅ MongoDB Connected"))
  .catch(err => console.error(err));

/* ================= MODELS ================= */
const Student = mongoose.model("students", new mongoose.Schema({
  std: String,
  div: String,
  name: String,
  roll: Number,
  mobile: String,
}));

const Attendance = mongoose.model("attendance", new mongoose.Schema({
  studentId: mongoose.Schema.Types.ObjectId,
  std: String,
  div: String,
  roll: Number,
  date: Date,
  present: Boolean,
  late: Boolean,
}));

const AttendanceLock = mongoose.model("attendance_locks", new mongoose.Schema({
  std: String,
  div: String,
  date: String,
  locked: [Number],
}));

/* ================= BASIC ================= */
app.get("/", (_, res) => res.send("Server running"));

app.get("/divisions", async (req, res) => {
  const divisions = await Student.distinct("div", { std: req.query.std });
  res.json({ divisions });
});

app.get("/students", async (req, res) => {
  const students = await Student.find(req.query).sort({ roll: 1 });
  res.json({ students });
});

/* ================= SAVE ATTENDANCE ================= */
app.post("/attendance", async (req, res) => {
  try {
    const { date, attendance } = req.body;

    const parsedDate = new Date(date);
    parsedDate.setHours(0, 0, 0, 0);
    const dateStr = parsedDate.toISOString().split("T")[0];

    const std = attendance[0].std;
    const div = attendance[0].div;

    const lockDoc = await AttendanceLock.findOne({ std, div, date: dateStr });
    const locked = lockDoc?.locked || [];
    const toLock = [];

    for (const e of attendance) {
      if (locked.includes(e.roll)) continue;

      await Attendance.updateOne(
        { studentId: e.studentId, std, div, date: parsedDate },
        {
          $set: {
            roll: e.roll,
            present: e.present,
            late: e.present ? !!e.late : false,
          },
        },
        { upsert: true }
      );

      if (e.present === false || e.late === true) {
        toLock.push(e.roll);
      }
    }

    if (toLock.length) {
      await AttendanceLock.updateOne(
        { std, div, date: dateStr },
        { $addToSet: { locked: { $each: toLock } } },
        { upsert: true }
      );
    }

    res.json({ success: true });
  } catch (e) {
    console.error(e);
    res.status(500).json({ success: false });
  }
});

/* ================= CHECK LOCK (ABSENT + LATE) ================= */
app.get("/attendance/check-lock", async (req, res) => {
  const { std, div, date } = req.query;
  const d = new Date(date);
  d.setHours(0, 0, 0, 0);

  const records = await Attendance.find({ std, div, date: d });

  const absent = [];
  const late = [];

  for (const r of records) {
    if (!r.present) absent.push(r.roll);
    else if (r.late) late.push(r.roll);
  }

  res.json({ absent, late });
});

/* ================= START ================= */
app.listen(process.env.PORT || 10000, () =>
  console.log("🚀 Server started")
);
