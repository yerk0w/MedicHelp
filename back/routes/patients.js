const express = require("express");
const bcrypt = require("bcrypt");
const crypto = require("crypto");
const mongoose = require("mongoose");
const router = express.Router();
const auth = require("../middleware/auth");
const User = require("../User/User");
const TreatmentCourse = require("../User/TreatmentCourse");
const HealthEntry = require("../User/HealthEntry");

const validateEmail = (email) => {
  const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
  return emailRegex.test(email);
};

const validatePassword = (password) => password && password.length >= 6;

router.get("/", auth, async (req, res) => {
  try {
    if (req.user?.role !== "doctor") {
      return res
        .status(403)
        .json({ message: "Только врач может просматривать список пациентов" });
    }

    const patients = await User.find({
      assignedDoctor: req.user.id,
      role: "patient",
    }).select("name email medicalCard");

    const patientIds = patients.map((p) => p._id);

    const courses = await TreatmentCourse.find({
      userId: { $in: patientIds },
    }).select("userId endDate");

    const courseMap = new Map();
    courses.forEach((course) => {
      const key = course.userId.toString();
      const stats =
        courseMap.get(key) || {
          total: 0,
          active: 0,
        };

      stats.total += 1;
      if (!course.endDate || course.endDate >= new Date()) {
        stats.active += 1;
      }

      courseMap.set(key, stats);
    });

    const latestEntries = await HealthEntry.aggregate([
      {
        $match: {
          userId: { $in: patientIds },
        },
      },
      {
        $sort: { entryDate: -1 },
      },
      {
        $group: {
          _id: "$userId",
          entryDate: { $first: "$entryDate" },
        },
      },
    ]);

    const entryMap = new Map(
      latestEntries.map((item) => [item._id.toString(), item.entryDate]),
    );

    const response = patients.map((patient) => {
      const key = patient._id.toString();
      const courseStats = courseMap.get(key) || { total: 0, active: 0 };
      return {
        id: key,
        name: patient.name,
        email: patient.email,
        lastEntryDate: entryMap.get(key) || null,
        totalCourses: courseStats.total,
        activeCourses: courseStats.active,
      };
    });

    res.json(response);
  } catch (error) {
    console.error("Ошибка при получении списка пациентов:", error);
    res.status(500).json({ message: "Ошибка сервера" });
  }
});

router.post("/", auth, async (req, res) => {
  try {
    if (req.user?.role !== "doctor") {
      return res
        .status(403)
        .json({ message: "Только врач может добавлять пациентов" });
    }

    const { name, email, temporaryPassword } = req.body;

    if (!name || !email) {
      return res
        .status(400)
        .json({ message: "Имя и email пациента обязательны" });
    }

    if (name.trim().length < 2) {
      return res
        .status(400)
        .json({ message: "Имя должно содержать минимум 2 символа" });
    }

    if (!validateEmail(email)) {
      return res.status(400).json({ message: "Неверный формат email" });
    }

    const existingUser = await User.findOne({ email: email.toLowerCase() });
    if (existingUser) {
      return res
        .status(400)
        .json({ message: "Пациент с таким email уже существует" });
    }

    let plainPassword = temporaryPassword;
    if (plainPassword) {
      if (!validatePassword(plainPassword)) {
        return res
          .status(400)
          .json({ message: "Пароль должен содержать минимум 6 символов" });
      }
    } else {
      plainPassword = crypto.randomBytes(4).toString("hex");
    }

    const salt = await bcrypt.genSalt(10);
    const hashedPassword = await bcrypt.hash(plainPassword, salt);

    const patient = new User({
      name: name.trim(),
      email: email.toLowerCase(),
      password: hashedPassword,
      role: "patient",
      assignedDoctor: req.user.id,
    });

    const savedPatient = await patient.save();

    res.status(201).json({
      message:
        "Пациент добавлен. Передайте временный пароль клиенту для первого входа.",
      patientId: savedPatient._id,
      temporaryPassword: plainPassword,
    });
  } catch (error) {
    console.error("Ошибка при добавлении пациента:", error);
    res.status(500).json({ message: "Ошибка сервера" });
  }
});

router.get("/:patientId", auth, async (req, res) => {
  try {
    if (req.user?.role !== "doctor") {
      return res
        .status(403)
        .json({ message: "Только врач может просматривать данные пациента" });
    }

    const { patientId } = req.params;

    if (!mongoose.Types.ObjectId.isValid(patientId)) {
      return res.status(400).json({ message: "Некорректный идентификатор" });
    }

    const patient = await User.findOne({
      _id: patientId,
      role: "patient",
      assignedDoctor: req.user.id,
    }).select("-password");

    if (!patient) {
      return res.status(404).json({ message: "Пациент не найден" });
    }

    res.json({
      id: patient._id,
      name: patient.name,
      email: patient.email,
      medicalCard: patient.medicalCard,
      registeredAt: patient.registeredAt,
    });
  } catch (error) {
    console.error("Ошибка при получении пациента:", error);
    res.status(500).json({ message: "Ошибка сервера" });
  }
});

module.exports = router;
