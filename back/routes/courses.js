const express = require("express");
const router = express.Router();
const auth = require("../middleware/auth");
const TreatmentCourse = require("../User/TreatmentCourse");
const Medication = require("../User/Medication");

// POST /api/courses - Создать новый курс лечения
router.post("/", auth, async (req, res) => {
  try {
    const { name, mainSymptom, startDate, endDate } = req.body;

    if (!name || !mainSymptom) {
      return res
        .status(400)
        .json({ message: "Название и основной симптом обязательны" });
    }

    const newCourse = new TreatmentCourse({
      userId: req.user.id,
      name,
      mainSymptom,
      startDate: startDate || Date.now(),
      endDate,
    });

    const savedCourse = await newCourse.save();
    res.status(201).json(savedCourse);
  } catch (err) {
    console.error(err.message);
    res.status(500).send("Ошибка сервера");
  }
});

// GET /api/courses - Получить все курсы пользователя
router.get("/", auth, async (req, res) => {
  try {
    const courses = await TreatmentCourse.find({ userId: req.user.id }).sort({
      startDate: -1,
    });
    res.json(courses);
  } catch (err) {
    console.error(err.message);
    res.status(500).send("Ошибка сервера");
  }
});

// GET /api/courses/:courseId - Получить один курс со всеми лекарствами
router.get("/:courseId", auth, async (req, res) => {
  try {
    const course = await TreatmentCourse.findById(req.params.courseId);

    if (!course) {
      return res.status(404).json({ message: "Курс не найден" });
    }

    if (course.userId.toString() !== req.user.id) {
      return res.status(403).json({ message: "Доступ запрещен" });
    }

    const medications = await Medication.find({
      courseId: req.params.courseId,
    });

    res.json({
      course,
      medications,
    });
  } catch (err) {
    console.error(err.message);
    res.status(500).send("Ошибка сервера");
  }
});

// POST /api/courses/:courseId/medications - Добавить лекарство в курс
router.post("/:courseId/medications", auth, async (req, res) => {
  try {
    const { name, dosage, schedule } = req.body;

    if (!name || !dosage || !schedule) {
      return res
        .status(400)
        .json({ message: "Название, дозировка и расписание обязательны" });
    }

    const course = await TreatmentCourse.findById(req.params.courseId);

    if (!course) {
      return res.status(404).json({ message: "Курс не найден" });
    }

    if (course.userId.toString() !== req.user.id) {
      return res.status(403).json({ message: "Доступ запрещен" });
    }

    const newMedication = new Medication({
      courseId: req.params.courseId,
      name,
      dosage,
      schedule,
    });

    const savedMedication = await newMedication.save();
    res.status(201).json(savedMedication);
  } catch (err) {
    console.error(err.message);
    res.status(500).send("Ошибка сервера");
  }
});

router.put("/:courseId", auth, async (req, res) => {
  try {
    const { name, mainSymptom, startDate, endDate } = req.body;

    const course = await TreatmentCourse.findById(req.params.courseId);

    if (!course) {
      return res.status(404).json({ message: "Курс не найден" });
    }

    if (course.userId.toString() !== req.user.id) {
      return res.status(403).json({ message: "Доступ запрещен" });
    }

    if (name) course.name = name;
    if (mainSymptom) course.mainSymptom = mainSymptom;
    if (startDate) course.startDate = startDate;
    if (endDate) course.endDate = endDate;

    const updatedCourse = await course.save();
    res.status(200).json(updatedCourse);
  } catch (err) {
    console.error(err.message);
    res.status(500).send("Ошибка сервера");
  }
});

// DELETE /api/courses/:courseId - Удалить курс лечения
router.delete("/:courseId", auth, async (req, res) => {
  try {
    const course = await TreatmentCourse.findById(req.params.courseId);

    if (!course) {
      return res.status(404).json({ message: "Курс не найден" });
    }

    if (course.userId.toString() !== req.user.id) {
      return res.status(403).json({ message: "Доступ запрещен" });
    }

    // Удаляем все связанные лекарства
    await Medication.deleteMany({ courseId: req.params.courseId });

    await TreatmentCourse.findByIdAndDelete(req.params.courseId);

    res.status(200).json({ message: "Курс успешно удален" });
  } catch (err) {
    console.error(err.message);
    res.status(500).send("Ошибка сервера");
  }
});

// PUT /api/courses/:courseId/medications/:medId - Обновить лекарство
router.put("/:courseId/medications/:medId", auth, async (req, res) => {
  try {
    const { name, dosage, schedule } = req.body;

    const course = await TreatmentCourse.findById(req.params.courseId);
    if (!course) {
      return res.status(404).json({ message: "Курс не найден" });
    }
    if (course.userId.toString() !== req.user.id) {
      return res.status(403).json({ message: "Доступ запрещен" });
    }

    const medication = await Medication.findById(req.params.medId);
    if (!medication) {
      return res.status(404).json({ message: "Лекарство не найдено" });
    }

    if (name) medication.name = name;
    if (dosage) medication.dosage = dosage;
    if (schedule) medication.schedule = schedule;

    const updatedMedication = await medication.save();
    res.status(200).json(updatedMedication);
  } catch (err) {
    console.error(err.message);
    res.status(500).send("Ошибка сервера");
  }
});

// DELETE /api/courses/:courseId/medications/:medId - Удалить лекарство
router.delete("/:courseId/medications/:medId", auth, async (req, res) => {
  try {
    const course = await TreatmentCourse.findById(req.params.courseId);
    if (!course) {
      return res.status(404).json({ message: "Курс не найден" });
    }
    if (course.userId.toString() !== req.user.id) {
      return res.status(403).json({ message: "Доступ запрещен" });
    }

    const medication = await Medication.findByIdAndDelete(req.params.medId);
    if (!medication) {
      return res.status(404).json({ message: "Лекарство не найдено" });
    }

    res.status(200).json({ message: "Лекарство успешно удалено" });
  } catch (err) {
    console.error(err.message);
    res.status(500).send("Ошибка сервера");
  }
});

module.exports = router;
