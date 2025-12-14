// =========================
// FILE: index.cjs
// =========================

const express = require('express');
const cors = require('cors');
const compression = require('compression');
const mongoose = require('mongoose');
const dotenv = require('dotenv');
const fetch = require('node-fetch');

dotenv.config();

const app = express();
app.use(express.json());
app.use(cors());
app.use(compression());

const PORT = process.env.PORT || 10000;
const MONGO_URL = process.env.MONGO_URL;
const GUPSHUP_URL = process.env.GUPSHUP_URL;
const GUPSHUP_USER = process.env.GUPSHUP_USER;
const GUPSHUP_PASSWORD = process.env.GUPSHUP_PASSWORD;

mongoose.connect(MONGO_URL, {
  useNewUrlParser: true,
  useUnifiedTopology: true,
});

const studentSchema = new mongoose.Schema({
  name: String,
  roll: Number,
  std: String,
  div: String,
  mobile: String,
});

const attendanceSchema = new mongoose.Schema({
  studentId: mongoose.Types.ObjectId,
  std: String,
  div: String,
  roll: Number,
  name: String,
  mobile: String,
  date: Date,
  present: Boolean,
  smsSent: { type: Boolean, default: false },
});

const Student = mongoose.model('Student', studentSchema);
const Attendance = mongoose.model('Attendance', attendanceSchema);

app.get('/students', async (req, res) => {
  const { std, div } = req.query;
  const students = await Student.find({ std, div }).sort({ roll: 1 });
  res.json({ students });
});

app.get('/divisions', async (req, res) => {
  const { std } = req.query;
  const divs = await Student.distinct('div', { std });
  res.json({ divisions: divs });
});

app.get('/attendance/check-lock', async (req, res) => {
  const { std, div, date } = req.query;
  const start = new Date(date);
  start.setHours(0, 0, 0, 0);
  const end = new Date(date);
  end.setHours(23, 59, 59, 999);
  const attendances = await Attendance.find({
    std,
    div,
    date: { $gte: start, $lte: end },
    smsSent: true,
  });
  const lockedRolls = attendances.map((a) => a.roll);
  res.json({ locked: lockedRolls });
});

app.post('/attendance', async (req, res) => {
  const { date, attendance } = req.body;
  const attendanceDate = new Date(date);

  let success = 0;
  let failed = 0;

  for (const entry of attendance) {
    const existing = await Attendance.findOne({
      studentId: entry.studentId,
      date: {
        $gte: new Date(attendanceDate.setHours(0, 0, 0, 0)),
        $lte: new Date(attendanceDate.setHours(23, 59, 59, 999)),
      },
    });

    if (existing) continue;

    const newEntry = await Attendance.create({ ...entry, date: attendanceDate });

    if (!entry.present) {
      try {
        const smsRes = await fetch(GUPSHUP_URL, {
          method: 'POST',
          headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
          body: new URLSearchParams({
            userid: GUPSHUP_USER,
            password: GUPSHUP_PASSWORD,
            send_to: entry.mobile,
            v: '1.1',
            msg_type: 'TEXT',
            method: 'SENDMESSAGE',
            auth_scheme: 'PLAIN',
            msg: `Dear Parent, your child ${entry.name} was absent today.`,
          }),
        });

        const smsBody = await smsRes.text();
        const successBool = smsBody.includes('success');
        if (successBool) {
          newEntry.smsSent = true;
          await newEntry.save();
          success++;
        } else {
          failed++;
        }
      } catch {
        failed++;
      }
    }
  }

  res.json({ success: true, smsSummary: { sent: success, failed } });
});

app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});
