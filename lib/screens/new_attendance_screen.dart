// ===============================
// FILE: index.cjs
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

app.get('/divisions', async (req, res) => {
  const { std } = req.query;
  const divs = await Student.distinct('div', { std });
  res.json({ divisions: divs });
});

app.get('/students', async (req, res) => {
  const { std, div } = req.query;
  const students = await Student.find({ std, div });
  res.json({ students });
});

app.get('/attendance/check-lock', async (req, res) => {
  const { std, div, date } = req.query;
  const d = new Date(date);
  const attendances = await Attendance.find({ std, div, date: { $gte: new Date(d.setHours(0, 0, 0, 0)), $lte: new Date(d.setHours(23, 59, 59, 999)) }, smsSent: true });
  const locked = attendances.map(a => a.roll);
  res.json({ locked });
});

app.post('/attendance', async (req, res) => {
  const { date, attendance } = req.body;
  const dateObj = new Date(date);

  for (const record of attendance) {
    const filter = { studentId: record.studentId, date: { $gte: new Date(dateObj.setHours(0, 0, 0, 0)), $lte: new Date(dateObj.setHours(23, 59, 59, 999)) } };
    await Attendance.findOneAndUpdate(filter, record, { upsert: true });
  }

  let sent = 0;
  let failed = 0;

  for (const a of attendance) {
    if (!a.present) {
      const alreadySent = await Attendance.findOne({ studentId: a.studentId, date: { $gte: new Date(dateObj.setHours(0, 0, 0, 0)), $lte: new Date(dateObj.setHours(23, 59, 59, 999)) }, smsSent: true });
      if (alreadySent) continue;

      const message = `Dear Parents,Your child, ${a.name} remained absent in school today.,Vidyakunj School`;
      const params = new URLSearchParams({
        method: 'sendMessage',
        send_to: `91${a.mobile}`,
        msg: message,
        msg_type: 'TEXT',
        userid: GUPSHUP_USER,
        password: GUPSHUP_PASSWORD,
        auth_scheme: 'PLAIN',
        v: '1.1',
      });

      try {
        const smsRes = await fetch(`${GUPSHUP_URL}?${params.toString()}`);
        const text = await smsRes.text();
        if (text.includes('success')) {
          await Attendance.updateOne({ studentId: a.studentId, date: { $gte: new Date(dateObj.setHours(0, 0, 0, 0)), $lte: new Date(dateObj.setHours(23, 59, 59, 999)) } }, { $set: { smsSent: true } });
          sent++;
        } else {
          failed++;
        }
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
