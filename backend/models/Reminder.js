const mongoose = require('mongoose');

const ReminderSchema = new mongoose.Schema({
    user: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User',
        required: true
    },
    patientName: {
        type: String,
        required: true
    },
    medicineName: {
        type: String,
        required: true
    },
    condition: {
        type: String,
        required: true
    },
    dosage: {
        type: String, // e.g., "500 mg"
        required: true
    },
    time: {
        type: String, // Format "HH:mm" (24h)
        required: true
    },
    createdAt: {
        type: Date,
        default: Date.now
    }
});

module.exports = mongoose.model('Reminder', ReminderSchema);
