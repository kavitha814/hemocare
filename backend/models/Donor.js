const mongoose = require('mongoose');

const DonorSchema = new mongoose.Schema({
    userId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User',
        required: true,
        unique: true
    },
    fullName: {
        type: String,
        required: true
    },
    location: {
        type: String,
        required: true
    },
    bloodGroup: {
        type: String,
        required: true
    },
    dob: {
        type: Date,
        required: true
    },
    lastDonation: {
        type: Date
    },
    isInterested: {
        type: Boolean,
        default: true
    },
    createdAt: {
        type: Date,
        default: Date.now
    }
});

module.exports = mongoose.model('Donor', DonorSchema);
