const mongoose = require("mongoose");

const MedicationSchema = new mongoose.Schema({
  courseId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: "TreatmentCourse",
    required: true,
  },
  name: {
    type: String,
    required: true,
  },
  dosage: {
    type: String,
    required: true,
  },
  schedule: {
    type: [String],
    required: true,
  },
});

module.exports = mongoose.model("Medication", MedicationSchema);
