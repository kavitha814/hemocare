const mongoose = require('mongoose');

const BloodRequestSchema = new mongoose.Schema({
    requesterId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User',
        required: true
    },
    donorId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User',
        required: true
    },
    status: {
        type: String,
        enum: ['pending', 'approved', 'declined'],
        default: 'pending'
    },
    createdAt: {
        type: Date,
        default: Date.now
    },
    hiddenFromRequester: {
        type: Boolean,
        default: false
    },
    hiddenFromDonor: {
        type: Boolean,
        default: false
    }
});

// Avoid multiple pending requests between same users
BloodRequestSchema.index({ requesterId: 1, donorId: 1, status: 1 });

module.exports = mongoose.model('BloodRequest', BloodRequestSchema);
