const mongoose = require("mongoose");

const HealthEntrySchema = new mongoose.Schema({
  userId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: "User",
    required: true,
  },
  entryDate: {
    type: Date,
    default: Date.now,
  },
  courseId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: "TreatmentCourse",
  },
  medications: [
    {
      name: String,
      taken: Boolean,
    },
  ],
  medicationsTaken: [
    {
      medId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: "Medication",
      },
      status: {
        type: String,
        enum: ["taken", "skipped"],
      },
    },
  ],
  symptoms: [String],
  headacheLevel: {
    type: Number,
    min: 0,
    max: 10,
  },
  symptomTags: {
    type: [String],
  },
  lifestyleTags: {
    type: [String],
  },
  notes: {
    type: String,
    trim: true,
  },
});

module.exports = mongoose.model("HealthEntry", HealthEntrySchema);
