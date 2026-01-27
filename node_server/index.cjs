/* =======================================================
   VIDYAKUNJ SMS + ATTENDANCE BACKEND
   FINAL – ABSENT + LATE + DLT PLAIN SMS
   ======================================================= */

const compression = require("compression");
const express = require("express");
const cors = require("cors");
const bodyParser = require("body-parser");
const mongoose = require("mongoose");
const axios = require("axios");
require("dotenv").config();

/* ================= LOGIN USERS ================= */
const users = [
  { username: "patil", password: "iken", role: "teacher" },
  { username: "teacher1", password: "1234", role: "teacher" },
  { username: "vks", password: "1234", role: "teacher" },
  { username: "admin", password: "admin123", role: "admin" },
];

/* ================= APP SETUP ================= */
const app = express();

app.use(cors({
  origin: "https://vidyakunj-frontend.onrender.com",
  methods: ["GET", "POST", "OPTIONS"],
  allowedHeaders: ["Content-Type"],
}));

app.use(bodyParser.json());
app.use(compression());

/* ================= ROOT ================= */
app.get("/", (req, res) => {
  res.send("Vidyakunj SMS Server Running");
});

/* ================= MONGO ================= */
mongoose
  .connect(process.env.MONGO_URL || process.env.MONGODB_URI)
  .then(() => console.log("✅ MongoDB Connected"))
  .catch((err) => console.error("❌ MongoDB Error:", err));

/* ================= SCHEMAS ================= */
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
  late: { type: Boolean, default: false },
}));

const AttendanceLock = mongoose.model("attendance_locks", new mongoose.Schema({
  std: String,
  div: String,
  date: String,
  locked: [Number],
}));

/* ================= LOGIN ================= */
app.post("/login", (req, res) => {
  const user = users.find(
    u => u.username === req.body.username && u.password === req.body.password
  );
  if (!user) return res.json({ success: false });
  res.json({ success: true, role: user.role });
});

/* ================= BASIC APIs ================= */
app.get("/divisions", async (req, res) => {
  const divisions = await Student.distinct("div", { std: req.query.std });
  res.json({ divisions });
});

app.get("/students", async (req, res) => {
  const students = await Student.find(req.query).sort({ roll: 1 });
  res.json({ students });
});

/* ================= ATTENDANCE CHECK (ABSENT + LATE) ================= */
app.get("/attendance/check-lock", async (req, res) => {
  try {
    const { std, div, date } = req.query;

    const parsedDate = new Date(date);
    parsedDate.setHours(0, 0, 0, 0);

    const records = await Attendance.find({ std, div, date: parsedDate });

    const absent = [];
    const late = [];

    for (const r of records) {
      if (r.present === false) absent.push(r.roll);
      else if (r.present === true && r.late === true) late.push(r.roll);
    }

    res.json({ absent, late });
  } catch (err) {
    console.error("CHECK LOCK ERROR:", err);
    res.json({ absent: [], late: [] });
  }
});

/* ================= SAVE ATTENDANCE + SMS ================= */
app.post("/attendance", async (req, res) => {
  try {
    const { attendance, date } = req.body;

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

      const student = await Student.findById(e.studentId);
      if (!student) continue;

      await Attendance.updateOne(
        { studentId: e.studentId, std, div, date: parsedDate },
        {
          $set: {
            roll: e.roll,
            present: e.present,
            late: e.present === true ? !!e.late : false,
          },
        },
        { upsert: true }
      );

      const mobile = student.mobile;
      const studentName = student.name;

      /* ---------- ABSENT SMS ---------- */
      if (e.present === false) {
        await axios.get(process.env.GUPSHUP_URL, {
          params: {
            method: "SendMessage",
            send_to: mobile,
            msg: `Dear Parents,Your child, ${studentName} remained absent in school today.,Vidyakunj School`,
            msg_type: "TEXT",
            userid: process.env.GUPSHUP_USER,
            password: process.env.GUPSHUP_PASSWORD,
            auth_scheme: "PLAIN",
            v: "1.1",
          },
        });

        toLock.push(e.roll);
      }

      /* ---------- LATE SMS ---------- */
      if (e.present === true && e.late === true) {
        await axios.get(process.env.GUPSHUP_URL, {
          params: {
            method: "SendMessage",
            send_to: mobile,
            msg: `Dear Parents,Your child, ${studentName} remained absent in school today.,Vidyakunj School`,
            msg_type: "TEXT",
            userid: process.env.GUPSHUP_USER,
            password: process.env.GUPSHUP_PASSWORD,
            auth_scheme: "PLAIN",
            v: "1.1",
          },
        });

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
  } catch (err) {
    console.error("ATTENDANCE ERROR:", err);
    res.status(500).json({ success: false });
  }
});
/* ================= ATTENDANCE LIST (READ ONLY – ADMIN REPORT) ================= */
app.get("/attendance/list", async (req, res) => {
  try {
    const { std, div, date } = req.query;

    const parsedDate = new Date(date);
    parsedDate.setHours(0, 0, 0, 0);

    const students = await Student.find({ std, div }).sort({ roll: 1 });
    const attendance = await Attendance.find({ std, div, date: parsedDate });

    const map = {};
    attendance.forEach(a => {
      map[a.studentId.toString()] = a;
    });

    const result = students.map(s => {
      const a = map[s._id.toString()];

      let status = "absent";
      if (a) {
        if (a.present === true && a.late === true) status = "late";
        else if (a.present === true) status = "present";
        else status = "absent";
      }

      return {
        rollNo: s.roll,
        name: s.name,
        status,
      };
    });

    res.json({ students: result });
  } catch (err) {
    console.error("ATTENDANCE LIST ERROR:", err);
    res.status(500).json({ students: [] });
  }
});

/* ================= ATTENDANCE SUMMARY (ADMIN REPORT) ================= */
app.get("/attendance/summary", async (req, res) => {
  try {
    const { std, div, date } = req.query;

    if (!std || !div || !date) {
      return res.status(400).json({ summary: null });
    }

    const parsedDate = new Date(date);
    parsedDate.setHours(0, 0, 0, 0);

    const total = await Student.countDocuments({ std, div });

    const records = await Attendance.find({
      std,
      div,
      date: parsedDate,
    });

    let present = 0;
    let absent = 0;
    let late = 0;

    for (const r of records) {
     if (r.present === true && r.late === true) {
      late++;
    } else if (r.present === true) {
      present++;
    } else {
      absent++;
    }
}


    res.json({
      summary: {
        total,
        present,
        absent,
        late,
      },
    });
  } catch (err) {
    console.error("SUMMARY ERROR:", err);
    res.status(500).json({ summary: null });
  }
});

/* ================= PRIMARY SECTION SUMMARY (STD 1–8) ================= */
app.get("/attendance/primary-section-summary", async (req, res) => {
  try {
    const { date } = req.query;
    if (!date) return res.status(400).json({ success: false });

    const parsedDate = new Date(date);
    parsedDate.setHours(0, 0, 0, 0);

    const result = [];
    let grandTotal = 0;
    let grandPresent = 0;
    let grandAbsent = 0;
    let grandLate = 0;

    // STD 1 → 8 (strict ascending)
    for (let std = 1; std <= 8; std++) {
      const stdStr = std.toString();

      // Get divisions in ascending order
      const divisions = await Student
        .distinct("div", { std: stdStr })
        .sort();

      for (const div of divisions) {
        const total = await Student.countDocuments({ std: stdStr, div });

        const records = await Attendance.find({
          std: stdStr,
          div,
          date: parsedDate,
        });

        let present = 0;
        let absent = 0;
        let late = 0;

        for (const r of records) {
          if (r.present === true) {
            present++;
            if (r.late === true) late++;
          } else {
            absent++;
          }
        }

        const percentage =
          total > 0 ? ((present / total) * 100).toFixed(2) : "0.00";

        result.push({
          std: stdStr,
          div,
          total,
          present,
          absent,
          late,
          percentage,
        });

        // Grand totals
        grandTotal += total;
        grandPresent += present;
        grandAbsent += absent;
        grandLate += late;
      }
    }

    res.json({
      success: true,
      classes: result,
      totals: {
        total: grandTotal,
        present: grandPresent,
        absent: grandAbsent,
        late: grandLate,
        percentage:
          grandTotal > 0
            ? ((grandPresent / grandTotal) * 100).toFixed(2)
            : "0.00",
      },
    });
  } catch (err) {
    console.error("PRIMARY SECTION SUMMARY ERROR:", err);
    res.status(500).json({ success: false });
  }
});

/* ================= SECONDARY SECTION SUMMARY (STD 9–12) ================= */
app.get("/attendance/secondary-section-summary", async (req, res) => {
  try {
    const { date } = req.query;
    if (!date) return res.status(400).json({ success: false });

    const parsedDate = new Date(date);
    parsedDate.setHours(0, 0, 0, 0);

    const result = [];
    let grandTotal = 0;
    let grandPresent = 0;
    let grandAbsent = 0;
    let grandLate = 0;

    // STD 9 → 12
    for (let std = 9; std <= 12; std++) {
      const stdStr = std.toString();

      const divisions = await Student
        .distinct("div", { std: stdStr })
        .sort();

      for (const div of divisions) {
        const total = await Student.countDocuments({ std: stdStr, div });

        const records = await Attendance.find({
          std: stdStr,
          div,
          date: parsedDate,
        });

        let present = 0;
        let absent = 0;
        let late = 0;

        for (const r of records) {
          if (r.present === true) {
            present++;
            if (r.late === true) late++;
          } else {
            absent++;
          }
        }

        const percentage =
          total > 0 ? ((present / total) * 100).toFixed(2) : "0.00";

        result.push({
          std: stdStr,
          div,
          total,
          present,
          absent,
          late,
          percentage,
        });

        grandTotal += total;
        grandPresent += present;
        grandAbsent += absent;
        grandLate += late;
      }
    }

    res.json({
      success: true,
      classes: result,
      totals: {
        total: grandTotal,
        present: grandPresent,
        absent: grandAbsent,
        late: grandLate,
        percentage:
          grandTotal > 0
            ? ((grandPresent / grandTotal) * 100).toFixed(2)
            : "0.00",
      },
    });
  } catch (err) {
    console.error("SECONDARY SECTION SUMMARY ERROR:", err);
    res.status(500).json({ success: false });
  }
});

/* ================= START ================= */
app.listen(process.env.PORT || 10000, () =>
  console.log("🚀 Server running")
);
