const express = require('express');
const router = express.Router();
const Chat = require('../models/Chat');
const auth = require('../middleware/auth');
const mongoose = require('mongoose');

// @route   POST api/chats
// @desc    Save a chat message
router.post('/', auth, async (req, res) => {
    const { text, isUser, sessionId, title, urgency, urgencyReason, urgencyAction, urgencyWarning } = req.body;

    try {
        const newChat = new Chat({
            user: req.user.id,
            text,
            isUser,
            sessionId,
            title,
            urgency: urgency || 'none',
            urgencyReason: urgencyReason || '',
            urgencyAction: urgencyAction || '',
            urgencyWarning: urgencyWarning || ''
        });

        const chat = await newChat.save();
        res.json(chat);
    } catch (err) {
        console.error(err.message);
        res.status(500).send('Server Error');
    }
});

// @route   GET api/chats/sessions
// @desc    Get all unique chat sessions for a user
router.get('/sessions', auth, async (req, res) => {
    try {
        const sessions = await Chat.aggregate([
            { $match: { user: new mongoose.Types.ObjectId(req.user.id) } },
            {
                $group: {
                    _id: { $ifNull: ["$sessionId", "legacy_session"] },
                    title: { $first: { $ifNull: ["$title", "Previous History"] } },
                    isPinned: { $max: "$isPinned" },
                    lastUpdated: { $max: "$timestamp" }
                }
            },
            { $sort: { isPinned: -1, lastUpdated: -1 } }
        ]);
        res.json(sessions);
    } catch (err) {
        console.error("Aggregation Error:", err.message);
        res.status(500).send('Server Error');
    }
});

// @route   PUT api/chats/session/:sessionId/rename
// @desc    Rename a chat session
router.put('/session/:sessionId/rename', auth, async (req, res) => {
    try {
        const { title } = req.body;
        const query = { user: req.user.id };
        if (req.params.sessionId === "legacy_session") {
            query.sessionId = { $exists: false };
        } else {
            query.sessionId = req.params.sessionId;
        }

        await Chat.updateMany(query, { title });
        res.json({ msg: 'Session renamed' });
    } catch (err) {
        console.error(err.message);
        res.status(500).send('Server Error');
    }
});

// @route   PUT api/chats/session/:sessionId/pin
// @desc    Toggle pin status for a chat session
router.put('/session/:sessionId/pin', auth, async (req, res) => {
    try {
        const { isPinned } = req.body;
        const query = { user: req.user.id };
        if (req.params.sessionId === "legacy_session") {
            query.sessionId = { $exists: false };
        } else {
            query.sessionId = req.params.sessionId;
        }

        await Chat.updateMany(query, { isPinned });
        res.json({ msg: isPinned ? 'Session pinned' : 'Session unpinned' });
    } catch (err) {
        console.error(err.message);
        res.status(500).send('Server Error');
    }
});

// @route   DELETE api/chats/session/:sessionId
// @desc    Delete a whole chat session
router.delete('/session/:sessionId', auth, async (req, res) => {
    try {
        const query = { user: req.user.id };
        if (req.params.sessionId === "legacy_session") {
            query.sessionId = { $exists: false };
        } else {
            query.sessionId = req.params.sessionId;
        }

        await Chat.deleteMany(query);
        res.json({ msg: 'Session deleted' });
    } catch (err) {
        console.error(err.message);
        res.status(500).send('Server Error');
    }
});

// @route   GET api/chats/session/:sessionId
// @desc    Get all messages for a specific session
router.get('/session/:sessionId', auth, async (req, res) => {
    try {
        const query = { user: req.user.id };
        if (req.params.sessionId === "legacy_session") {
            query.sessionId = { $exists: false };
        } else {
            query.sessionId = req.params.sessionId;
        }

        const chats = await Chat.find(query).sort({ timestamp: 1 });
        res.json(chats);
    } catch (err) {
        console.error(err.message);
        res.status(500).send('Server Error');
    }
});

// @route   GET api/chats
// @desc    Get all chat messages for a user (old way, keeping for compat)
router.get('/', auth, async (req, res) => {
    try {
        const chats = await Chat.find({ user: req.user.id }).sort({ timestamp: 1 });
        res.json(chats);
    } catch (err) {
        console.error(err.message);
        res.status(500).send('Server Error');
    }
});

// @route   DELETE api/chats/:id
// @desc    Delete a chat message
router.delete('/:id', auth, async (req, res) => {
    try {
        const chat = await Chat.findById(req.params.id);

        if (!chat) {
            return res.status(404).json({ msg: 'Chat not found' });
        }

        // Check user
        if (chat.user.toString() !== req.user.id) {
            return res.status(401).json({ msg: 'User not authorized' });
        }

        await chat.deleteOne();

        res.json({ msg: 'Chat removed' });
    } catch (err) {
        console.error(err.message);
        if (err.kind === 'ObjectId') {
            return res.status(404).json({ msg: 'Chat not found' });
        }
        res.status(500).send('Server Error');
    }
});

module.exports = router;
