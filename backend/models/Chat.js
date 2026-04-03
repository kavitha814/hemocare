const mongoose = require('mongoose');

const chatSchema = new mongoose.Schema({
    user: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User',
        required: true
    },
    text: {
        type: String,
        required: true
    },
    isUser: {
        type: Boolean,
        required: true
    },
    sessionId: {
        type: String,
        required: true
    },
    title: {
        type: String,
        default: "New Chat"
    },
    isPinned: {
        type: Boolean,
        default: false
    },
    urgency: {
        type: String,
        enum: ['none', 'low', 'medium', 'high'],
        default: 'none'
    },
    urgencyReason: {
        type: String,
        default: ''
    },
    urgencyAction: {
        type: String,
        default: ''
    },
    urgencyWarning: {
        type: String,
        default: ''
    },
    timestamp: {
        type: Date,
        default: Date.now
    }
});

module.exports = mongoose.model('Chat', chatSchema);
