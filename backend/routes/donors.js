const express = require('express');
const router = express.Router();
const auth = require('../middleware/auth');
const Donor = require('../models/Donor');

// @route   POST api/donors
// @desc    Register as a donor
router.post('/', auth, async (req, res) => {
    const { fullName, location, bloodGroup, dob, lastDonation, isInterested } = req.body;

    try {
        // Check if user is already registered as a donor
        let donor = await Donor.findOne({ userId: req.user.id });
        if (donor) {
            return res.status(400).json({ msg: 'You are already registered as a donor' });
        }

        donor = new Donor({
            userId: req.user.id,
            fullName,
            location,
            bloodGroup,
            dob,
            lastDonation,
            isInterested
        });

        await donor.save();
        res.json(donor);
    } catch (err) {
        console.error(err.message);
        res.status(500).send('Server Error');
    }
});

// @route   GET api/donors/check
// @desc    Check if user is registered as a donor
router.get('/check', auth, async (req, res) => {
    try {
        const donor = await Donor.findOne({ userId: req.user.id });
        res.json({ isRegistered: !!donor, donor });
    } catch (err) {
        console.error(err.message);
        res.status(500).send('Server Error');
    }
});

// @route   GET api/donors
// @desc    Get all compatible donors (excluding self)
router.get('/', auth, async (req, res) => {
    const { bloodGroup } = req.query;

    try {
        let query = {
            userId: { $ne: req.user.id }, // Exclude self
            isInterested: true
        };

        if (bloodGroup) {
            query.bloodGroup = bloodGroup;
        }

        const donors = await Donor.find(query)
            .select('fullName location bloodGroup lastDonation userId')
            .sort({ createdAt: -1 });

        res.json(donors);
    } catch (err) {
        console.error(err.message);
        res.status(500).send('Server Error');
    }
});

// @route   PUT api/donors
// @desc    Update donor information
router.put('/', auth, async (req, res) => {
    const { location, lastDonation } = req.body;

    try {
        let donor = await Donor.findOne({ userId: req.user.id });
        if (!donor) {
            return res.status(404).json({ msg: 'Donor profile not found' });
        }

        // Update fields
        if (location) donor.location = location;
        if (lastDonation) donor.lastDonation = lastDonation;

        await donor.save();
        res.json(donor);
    } catch (err) {
        console.error(err.message);
        res.status(500).send('Server Error');
    }
});

// @route   DELETE api/donors
// @desc    Revoke donor status
router.delete('/', auth, async (req, res) => {
    try {
        const donor = await Donor.findOneAndDelete({ userId: req.user.id });
        if (!donor) {
            return res.status(404).json({ msg: 'Donor profile not found' });
        }
        res.json({ msg: 'Donor status revoked successfully' });
    } catch (err) {
        console.error(err.message);
        res.status(500).send('Server Error');
    }
});

module.exports = router;
