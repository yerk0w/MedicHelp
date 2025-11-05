const express = require("express");
const mongoose = require("mongoose");
const router = express.Router();
const auth = require("../middleware/auth");
const User = require("../User/User");
const ChatMessage = require("../User/ChatMessage");

const resolveParticipants = async (req, res) => {
  const isDoctor = req.user?.role === "doctor";
  const isPatient = req.user?.role === "patient";

  if (!isDoctor && !isPatient) {
    res.status(403).json({ message: "Роль не поддерживается" });
    return null;
  }

  let doctor;
  let patient;

  if (isDoctor) {
    const { patientId } = req.query.patientId ? req.query : req.body;
    if (!patientId || !mongoose.Types.ObjectId.isValid(patientId)) {
      res.status(400).json({ message: "Укажите корректного пациента" });
      return null;
    }

    patient = await User.findOne({
      _id: patientId,
      role: "patient",
      assignedDoctor: req.user.id,
    }).select("name email assignedDoctor");

    if (!patient) {
      res.status(404).json({ message: "Пациент не найден" });
      return null;
    }

    doctor = await User.findById(req.user.id).select("name email");
    if (!doctor) {
      res.status(404).json({ message: "Врач не найден" });
      return null;
    }
  } else {
    patient = await User.findById(req.user.id).select(
      "name email assignedDoctor",
    );

    if (!patient) {
      res.status(404).json({ message: "Пациент не найден" });
      return null;
    }

    if (!patient.assignedDoctor) {
      res.status(400).json({
        message: "К пациенту не привязан врач. Обратитесь в клинику.",
      });
      return null;
    }

    doctor = await User.findById(patient.assignedDoctor).select("name email");
    if (!doctor) {
      res.status(404).json({ message: "Врач не найден" });
      return null;
    }
  }

  return { doctor, patient, isDoctor, isPatient };
};

router.get("/", auth, async (req, res) => {
  try {
    const context = await resolveParticipants(req, res);
    if (!context) {
      return;
    }

    const { doctor, patient } = context;

    const messages = await ChatMessage.find({
      doctorId: doctor._id,
      patientId: patient._id,
    })
      .sort({ createdAt: 1 })
      .lean();

    res.json({
      doctor: {
        id: doctor._id,
        name: doctor.name,
        email: doctor.email,
      },
      patient: {
        id: patient._id,
        name: patient.name,
        email: patient.email,
      },
      messages: messages.map((msg) => ({
        id: msg._id,
        senderRole: msg.senderRole,
        senderId: msg.senderId,
        content: msg.content,
        createdAt: msg.createdAt,
        readAt: msg.readAt,
      })),
    });
  } catch (error) {
    console.error("Ошибка при получении сообщений:", error);
    res.status(500).json({ message: "Ошибка сервера" });
  }
});

router.post("/", auth, async (req, res) => {
  try {
    const context = await resolveParticipants(req, res);
    if (!context) {
      return;
    }

    const { doctor, patient, isDoctor, isPatient } = context;
    const { message } = req.body;

    if (!message || !message.trim()) {
      return res.status(400).json({ message: "Сообщение не может быть пустым" });
    }

    const chatMessage = new ChatMessage({
      doctorId: doctor._id,
      patientId: patient._id,
      senderId: isDoctor ? doctor._id : patient._id,
      senderRole: isDoctor ? "doctor" : "patient",
      content: message.trim(),
    });

    const savedMessage = await chatMessage.save();

    res.status(201).json({
      id: savedMessage._id,
      senderRole: savedMessage.senderRole,
      senderId: savedMessage.senderId,
      content: savedMessage.content,
      createdAt: savedMessage.createdAt,
      readAt: savedMessage.readAt,
    });
  } catch (error) {
    console.error("Ошибка при отправке сообщения:", error);
    res.status(500).json({ message: "Ошибка сервера" });
  }
});

module.exports = router;
