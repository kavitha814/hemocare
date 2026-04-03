const mongoose = require('mongoose');

const vaccinationSchema = new mongoose.Schema({
    user: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User',
        required: true
    },
    vaccineName: {
        type: String,
        required: true
    },
    isCompleted: {
        type: Boolean,
        default: false
    },
    completionDate: {
        type: Date
    },
    timestamp: {
        type: Date,
        default: Date.now
    }
});

// Compound index to ensure uniqueness per user per vaccine
vaccinationSchema.index({ user: 1, vaccineName: 1 }, { unique: true });

module.exports = mongoose.model('Vaccination', vaccinationSchema);
