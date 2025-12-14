// ===============================
// FILE: index.cjs (Node.js backend)
// ===============================

import express from 'express';
import cors from 'cors';
import compression from 'compression';
import mongoose from 'mongoose';
import dotenv from 'dotenv';
import fetch from 'node-fetch';

dotenv.config();

const app = express();
app.use(cors());
app.use(compression());
app.use(express.json());

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
  const students = await Student.find({ std, div });
  res.json({ students });
});

app.get('/divisions', async (req, res) => {
  const { std } = req.query;
  const divisions = await Student.find({ std }).distinct('div');
  res.json({ divisions });
});

app.get('/attendance/check-lock', async (req, res) => {
  const { std, div, date } = req.query;
  const attendances = await Attendance.find({ std, div, date });
  const locked = attendances.filter(a => a.smsSent).map(a => a.roll);
  res.json({ locked });
});

app.post('/attendance', async (req, res) => {
  const { date, attendance } = req.body;

  let sent = 0;
  let failed = 0;

  for (const entry of attendance) {
    const filter = {
      studentId: entry.studentId,
      std: entry.std,
      div: entry.div,
      roll: entry.roll,
      date,
    };

    const existing = await Attendance.findOne(filter);

    if (existing) continue; // skip if already saved

    const doc = await Attendance.create({ ...entry, date });

    if (!entry.present) {
      try {
        const url = `${GUPSHUP_URL}?method=sendMessage&send_to=${entry.mobile}&msg=Dear Parent, your child ${entry.name} is absent today.&msg_type=TEXT&userid=${GUPSHUP_USER}&auth_scheme=plain&password=${GUPSHUP_PASSWORD}&v=1.1&format=JSON`;
        const smsRes = await fetch(url);
        const json = await smsRes.json();
        if (json.response.status === 'success') {
          doc.smsSent = true;
          sent++;
        } else {
          failed++;
        }
        await doc.save();
      } catch (e) {
        failed++;
      }
    }
  }

  res.json({ success: true, smsSummary: { sent, failed } });
});

app.listen(PORT, () => {
  console.log(`🚀 Vidyakunj Backend running on port ${PORT}`);
});
