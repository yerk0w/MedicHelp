const mongoose = require('mongoose');

const HealthEntrySchema = new mongoose.Schema({
    userId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User',
        required: true
    },
    entryDate: {
        type: Date,
        default: Date.now
    },
    medications: [
        {
            name: String,
            taken: Boolean
        }
    ],
    headacheLevel: {
        type: Number,
        min: 0,
        max: 10
    },
    symptomTags: {
        type: [String]
    },
    lifestyleTags: {
        type: [String]
    },
    notes: {
        type: String,
        trim: true
    }
});

module.exports = mongoose.model('HealthEntry', HealthEntrySchema);