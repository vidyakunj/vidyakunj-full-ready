/*
  Patch: Fixes attendance/check-lock endpoint to return all locked roll numbers for a given class/date
*/

app.get("/attendance/check-lock", async (req, res) => {
  const { std, div, date } = req.query;

  if (!std || !div || !date) {
    return res.status(400).json({ error: "Missing required query params" });
  }

  try {
    const start = new Date(date);
    start.setHours(0, 0, 0, 0);
    const end = new Date(date);
    end.setHours(23, 59, 59, 999);

    const records = await Attendance.find({
      std,
      div,
      date: { $gte: start, $lte: end },
      present: false // only lock absent entries
    });

    const locked = records.map((r) => r.roll);

    res.json({ locked });
  } catch (err) {
    console.error("Check lock error", err);
    res.status(500).json({ error: "Internal server error" });
  }
});
