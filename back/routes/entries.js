const express = require("express");
const router = express.Router();
const auth = require("../middleware/auth");
const HealthEntry = require("../User/HealthEntry");

router.post("/", auth, async (req, res) => {
  try {
    const {
      entryDate,
      courseId,
      medications,
      medicationsTaken,
      symptoms,
      headacheLevel,
      symptomTags,
      lifestyleTags,
      notes,
    } = req.body;

    const start = new Date();
    start.setHours(0, 0, 0, 0);
    const end = new Date();
    end.setHours(23, 59, 59, 999);

    let entry = await HealthEntry.findOne({
      userId: req.user.id,
      entryDate: { $gte: start, $lte: end },
    });

    if (entry) {
      entry.courseId = courseId;
      entry.medications = medications;
      entry.medicationsTaken = medicationsTaken;
      entry.symptoms = symptoms;
      entry.headacheLevel = headacheLevel;
      entry.symptomTags = symptomTags;
      entry.lifestyleTags = lifestyleTags;
      entry.notes = notes;
      entry.entryDate = entryDate || new Date();
    } else {
      entry = new HealthEntry({
        userId: req.user.id,
        entryDate: entryDate || new Date(),
        courseId,
        medications,
        medicationsTaken,
        symptoms,
        headacheLevel,
        symptomTags,
        lifestyleTags,
        notes,
      });
    }

    const savedEntry = await entry.save();
    res.status(201).json(savedEntry);
  } catch (err) {
    console.error(err.message);
    res.status(500).send("Ошибка сервера");
  }
});

router.get("/today", auth, async (req, res) => {
  try {
    const start = new Date();
    start.setHours(0, 0, 0, 0);
    const end = new Date();
    end.setHours(23, 59, 59, 999);

    const entry = await HealthEntry.findOne({
      userId: req.user.id,
      entryDate: { $gte: start, $lte: end },
    }).sort({ entryDate: -1 });

    if (!entry) {
      return res.status(404).json({ message: "Записей на сегодня нет" });
    }

    res.json(entry.medications || []);
  } catch (err) {
    console.error(err.message);
    res.status(500).send("Ошибка сервера");
  }
});

module.exports = router;
