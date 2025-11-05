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
  registeredAt: {
    type: Date,
    required: true,
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
