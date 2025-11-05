const express = require("express");
const router = express.Router();
const auth = require("../middleware/auth");
const User = require("../User/User");

router.get("/", auth, async (req, res) => {
  try {
    const user = await User.findById(req.user.id).select("-password");
    if (!user) {
      return res.status(404).json({ message: "Пользователь не найден" });
    }

    let assignedDoctorInfo = null;
    if (user.assignedDoctor) {
      const doctor = await User.findById(user.assignedDoctor).select(
        "name email",
      );
      if (doctor) {
        assignedDoctorInfo = {
          id: doctor._id,
          name: doctor.name,
          email: doctor.email,
        };
      }
    }
    res.json({
      name: user.name,
      email: user.email,
      role: user.role,
      assignedDoctor: user.assignedDoctor,
      assignedDoctorInfo,
      medicalCard: user.medicalCard,
    });
  } catch (err) {
    console.error(err.message);
    res.status(500).json({ message: "Ошибка сервера" });
  }
});

router.put("/", auth, async (req, res) => {
  try {
    const user = await User.findById(req.user.id);
    if (!user) {
      return res.status(404).json({ message: "Пользователь не найден" });
    }

    const sanitizedCard = {
      fullName: req.body.fullName || "",
      birthDate: req.body.birthDate || "",
      bloodType: req.body.bloodType || "",
      allergies: req.body.allergies || "",
      chronicDiseases: req.body.chronicDiseases || "",
      emergencyContact: req.body.emergencyContact || "",
      insuranceNumber: req.body.insuranceNumber || "",
      additionalInfo: req.body.additionalInfo || "",
    };

    const maxLengths = {
      fullName: 100,
      birthDate: 20,
      bloodType: 10,
      allergies: 500,
      chronicDiseases: 500,
      emergencyContact: 50,
      insuranceNumber: 50,
      additionalInfo: 1000,
    };

    for (const [key, value] of Object.entries(sanitizedCard)) {
      if (typeof value === "string" && value.length > maxLengths[key]) {
        sanitizedCard[key] = value.substring(0, maxLengths[key]);
      }
    }

    user.medicalCard = sanitizedCard;
    await user.save();

    res.status(200).json(user.medicalCard);
  } catch (err) {
    console.error(err.message);
    res.status(500).json({ message: "Ошибка сервера" });
  }
});

module.exports = router;
