const express = require('express');
const router = express.Router();
const Vaccination = require('../models/Vaccination');
const auth = require('../middleware/auth');

// @route   GET api/vaccinations
// @desc    Get all vaccination records for the current user
router.get('/', auth, async (req, res) => {
    try {
        const vaccinations = await Vaccination.find({ user: req.user.id });
        res.json(vaccinations);
    } catch (err) {
        console.error(err.message);
        res.status(500).send('Server Error');
    }
});

// @route   POST api/vaccinations/toggle
// @desc    Toggle vaccination completion status
router.post('/toggle', auth, async (req, res) => {
    const { vaccineName, isCompleted } = req.body;

    try {
        let record = await Vaccination.findOne({ user: req.user.id, vaccineName });

        if (record) {
            record.isCompleted = isCompleted;
            record.completionDate = isCompleted ? new Date() : null;
            await record.save();
        } else {
            record = new Vaccination({
                user: req.user.id,
                vaccineName,
                isCompleted,
                completionDate: isCompleted ? new Date() : null
            });
            await record.save();
        }

        res.json(record);
    } catch (err) {
        console.error(err.message);
        res.status(500).send('Server Error');
    }
});

module.exports = router;
