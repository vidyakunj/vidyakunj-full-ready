// ===============================
// FILE: index.cjs
// ===============================

const express = require('express');
const cors = require('cors');
const compression = require('compression');
const mongoose = require('mongoose');
const bodyParser = require('body-parser');
const dotenv = require('dotenv');
const axios = require('axios');

dotenv.config();

const app = express();
const PORT = process.env.PORT || 10000;
const MONGO_URL = process.env.MONGO_URL;
const GUPSHUP_URL = process.env.GUPSHUP_URL;
const GUPSHUP_USER = process.env.GUPSHUP_USER;
const GUPSHUP_PASSWORD = process.env.GUPSHUP_PASSWORD;

// Middleware
app.use(cors());
app.use(compression());
app.use(bodyParser.json());

// MongoDB Connect
mongoose.connect(MONGO_URL, {
  useNewUrlParser: true,
  useUnifiedTopology: true,
});

const db = mongoose.connection;
db.on('error', console.error.bind(console, 'MongoDB connection error:'));
db.once('open', () => console.log('✅ MongoDB Connected'));

// Schemas
const studentSchema = new mongoose.Schema({
  name: String,
  roll: Number,
  std: String,
  div: String,
  mobile: String,
});
const Student = mongoose.model('Student', studentSchema);

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
const Attendance = mongoose.model('Attendance', attendanceSchema);

const teacherSchema = new mongoose.Schema({
  username: String,
  password: String,
});
const Teacher = mongoose.model('Teacher', teacherSchema);

// ========== Routes ==========

app.post('/login', async (req, res) => {
  const { username, password } = req.body;
  const teacher = await Teacher.findOne({ username, password });
  res.json({ success: !!teacher });
});

app.get('/divisions', async (req, res) => {
  const std = req.query.std;
  const divisions = await Student.find({ std }).distinct('div');
  res.json({ divisions });
});

app.get('/students', async (req, res) => {
  const { std, div } = req.query;
  const students = await Student.find({ std, div }).sort('roll');
  res.json({ students });
});

app.get('/attendance/check-lock', async (req, res) => {
  const { std, div, date } = req.query;
  const attendances = await Attendance.find({ std, div, date: new Date(date), smsSent: true });
  const locked = attendances.map((a) => a.roll);
  res.json({ locked });
});

app.post('/attendance', async (req, res) => {
  const { date, attendance } = req.body;
  const parsedDate = new Date(date);

  let sent = 0;
  let failed = 0;

  for (const entry of attendance) {
    const { studentId, std, div, roll, name, mobile, present } = entry;

    let existing = await Attendance.findOne({ studentId, date: parsedDate });
    if (existing) continue;

    const saved = await Attendance.create({ ...entry, date: parsedDate });

    if (!present && !saved.smsSent && mobile) {
      const message = `Dear Parents, Your child, ${name} remained absent in school today. - Vidyakunj School`;
      const smsUrl = `${GUPSHUP_URL}?method=sendMessage&send_to=${mobile}&msg=${encodeURIComponent(message)}&msg_type=TEXT&userid=${GUPSHUP_USER}&password=${GUPSHUP_PASSWORD}&auth_scheme=PLAIN&v=1.1`;

      try {
        const smsRes = await axios.get(smsUrl);
        const success = smsRes.data.response?.status === 'success';

        if (success) {
          sent++;
          saved.smsSent = true;
          await saved.save();
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

// ========== Start Server ==========

app.listen(PORT, () => {
  console.log(`🚀 Vidyakunj Backend running on port ${PORT}`);
});
