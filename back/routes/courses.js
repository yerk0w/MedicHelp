const express = require("express");
const router = express.Router();
const mongoose = require("mongoose");
const auth = require("../middleware/auth");
const TreatmentCourse = require("../User/TreatmentCourse");
const Medication = require("../User/Medication");
const User = require("../User/User");

const canAccessCourse = (course, user) => {
  if (!course) {
    return false;
  }

  if (course.userId.toString() === user.id) {
    return true;
  }

  if (
    user.role === "doctor" &&
    course.doctorId &&
    course.doctorId.toString() === user.id
  ) {
    return true;
  }

  return false;
};

router.post("/", auth, async (req, res) => {
  try {
    const { name, mainSymptom, startDate, endDate, patientId } = req.body;

    if (!name || !mainSymptom) {
      return res
        .status(400)
        .json({ message: "Название и основной симптом обязательны" });
    }

    let ownerId = req.user.id;
    let doctorId = null;

    if (req.user.role === "doctor") {
      if (!patientId || !mongoose.Types.ObjectId.isValid(patientId)) {
        return res
          .status(400)
          .json({ message: "Укажите корректного пациента для курса" });
      }

      const patient = await User.findOne({
        _id: patientId,
        role: "patient",
        assignedDoctor: req.user.id,
      });

      if (!patient) {
        return res.status(404).json({ message: "Пациент не найден" });
      }

      ownerId = patient._id;
      doctorId = req.user.id;
    }

    const newCourse = new TreatmentCourse({
      userId: ownerId,
      doctorId,
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

router.get("/", auth, async (req, res) => {
  try {
    let query = {};
    let cursor;

    if (req.user.role === "doctor") {
      query = { doctorId: req.user.id };
      const { patientId } = req.query;
      if (patientId) {
        if (!mongoose.Types.ObjectId.isValid(patientId)) {
          return res
            .status(400)
            .json({ message: "Некорректный идентификатор пациента" });
        }

        const patient = await User.findOne({
          _id: patientId,
          role: "patient",
          assignedDoctor: req.user.id,
        });

        if (!patient) {
          return res.status(404).json({ message: "Пациент не найден" });
        }

        query.userId = patient._id;
      }

      cursor = TreatmentCourse.find(query)
        .sort({ startDate: -1 })
        .populate("userId", "name email");
    } else {
      query = { userId: req.user.id };
      cursor = TreatmentCourse.find(query).sort({ startDate: -1 });
    }

    const courses = await cursor;
    res.json(courses);
  } catch (err) {
    console.error(err.message);
    res.status(500).send("Ошибка сервера");
  }
});

router.get("/:courseId", auth, async (req, res) => {
  try {
    const course = await TreatmentCourse.findById(req.params.courseId).populate(
      "userId",
      "name email",
    );

    if (!course) {
      return res.status(404).json({ message: "Курс не найден" });
    }

    if (!canAccessCourse(course, req.user)) {
      return res.status(403).json({ message: "Доступ запрещен" });
    }

    const medications = await Medication.find({
      courseId: req.params.courseId,
    });

    res.json({ course, medications });
  } catch (err) {
    console.error(err.message);
    res.status(500).send("Ошибка сервера");
  }
});

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

    if (!canAccessCourse(course, req.user)) {
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

    if (!canAccessCourse(course, req.user)) {
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

router.delete("/:courseId", auth, async (req, res) => {
  try {
    const course = await TreatmentCourse.findById(req.params.courseId);

    if (!course) {
      return res.status(404).json({ message: "Курс не найден" });
    }

    if (!canAccessCourse(course, req.user)) {
      return res.status(403).json({ message: "Доступ запрещен" });
    }

    await Medication.deleteMany({ courseId: req.params.courseId });

    await TreatmentCourse.findByIdAndDelete(req.params.courseId);

    res.status(200).json({ message: "Курс успешно удален" });
  } catch (err) {
    console.error(err.message);
    res.status(500).send("Ошибка сервера");
  }
});

router.put("/:courseId/medications/:medId", auth, async (req, res) => {
  try {
    const { name, dosage, schedule } = req.body;

    const course = await TreatmentCourse.findById(req.params.courseId);
    if (!course) {
      return res.status(404).json({ message: "Курс не найден" });
    }
    if (!canAccessCourse(course, req.user)) {
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

router.delete("/:courseId/medications/:medId", auth, async (req, res) => {
  try {
    const course = await TreatmentCourse.findById(req.params.courseId);
    if (!course) {
      return res.status(404).json({ message: "Курс не найден" });
    }
    if (!canAccessCourse(course, req.user)) {
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
