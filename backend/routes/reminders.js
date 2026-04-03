const express = require('express');
const router = express.Router();
const auth = require('../middleware/auth');
const Reminder = require('../models/Reminder');

// @route   GET api/reminders
// @desc    Get all reminders for current user
// @access  Private
router.get('/', auth, async (req, res) => {
    try {
        const reminders = await Reminder.find({ user: req.user.id }).sort({ time: 1 });
        res.json(reminders);
    } catch (err) {
        console.error(err.message);
        res.status(500).send('Server Error');
    }
});

// @route   POST api/reminders
// @desc    Add a new reminder
// @access  Private
router.post('/', auth, async (req, res) => {
    const { patientName, medicineName, condition, dosage, time } = req.body;

    try {
        const newReminder = new Reminder({
            user: req.user.id,
            patientName,
            medicineName,
            condition,
            dosage,
            time
        });

        const reminder = await newReminder.save();
        res.json(reminder);
    } catch (err) {
        console.error(err.message);
        res.status(500).send('Server Error');
    }
});

// @route   PUT api/reminders/:id
// @desc    Update a reminder
// @access  Private
router.put('/:id', auth, async (req, res) => {
    const { patientName, medicineName, condition, dosage, time } = req.body;

    // Build reminder object
    const reminderFields = {};
    if (patientName) reminderFields.patientName = patientName;
    if (medicineName) reminderFields.medicineName = medicineName;
    if (condition) reminderFields.condition = condition;
    if (dosage) reminderFields.dosage = dosage;
    if (time) reminderFields.time = time;

    try {
        let reminder = await Reminder.findById(req.params.id);

        if (!reminder) return res.status(404).json({ msg: 'Reminder not found' });

        // Make sure user owns the reminder
        if (reminder.user.toString() !== req.user.id) {
            return res.status(401).json({ msg: 'Not authorized' });
        }

        reminder = await Reminder.findByIdAndUpdate(
            req.params.id,
            { $set: reminderFields },
            { new: true }
        );

        res.json(reminder);
    } catch (err) {
        console.error(err.message);
        res.status(500).send('Server Error');
    }
});

// @route   DELETE api/reminders/:id
// @desc    Delete a reminder
// @access  Private
router.delete('/:id', auth, async (req, res) => {
    try {
        const reminder = await Reminder.findById(req.params.id);

        if (!reminder) {
            return res.status(404).json({ msg: 'Reminder not found' });
        }

        // Make sure user owns the reminder
        if (reminder.user.toString() !== req.user.id) {
            return res.status(401).json({ msg: 'Not authorized' });
        }

        await Reminder.findByIdAndDelete(req.params.id);
        res.json({ msg: 'Reminder removed' });
    } catch (err) {
        console.error(err.message);
        if (err.kind === 'ObjectId') {
            return res.status(404).json({ msg: 'Reminder not found' });
        }
        res.status(500).send('Server Error');
    }
});

module.exports = router;
