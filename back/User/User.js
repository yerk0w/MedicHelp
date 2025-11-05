const mongoose = require("mongoose");

const UserSchema = new mongoose.Schema({
  name: {
    type: String,
    required: true,
  },
  email: {
    type: String,
    required: true,
    unique: true,
  },
  password: {
    type: String,
    required: true,
  },
  role: {
    type: String,
    enum: ["doctor", "patient"],
    default: "patient",
  },
  assignedDoctor: {
    type: mongoose.Schema.Types.ObjectId,
    ref: "User",
    default: null,
  },
  registeredAt: {
    type: Date,
    default: Date.now,
  },
  medicalCard: {
    type: Object,
    default: {
      fullName: "",
      birthDate: "",
      bloodType: "",
      allergies: "",
      chronicDiseases: "",
      emergencyContact: "",
      insuranceNumber: "",
      additionalInfo: "",
    },
  },
});

module.exports = mongoose.model("User", UserSchema);
