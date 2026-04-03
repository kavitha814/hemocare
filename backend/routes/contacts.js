const express = require('express');
const router = express.Router();
const Contact = require('../models/Contact');
const auth = require('../middleware/auth');

// @route   GET api/contacts
// @desc    Get all user contacts
router.get('/', auth, async (req, res) => {
    try {
        const contacts = await Contact.find({ user: req.user.id }).sort({ createdAt: -1 });
        res.json(contacts);
    } catch (err) {
        console.error(err.message);
        res.status(500).send('Server Error');
    }
});

// @route   POST api/contacts
// @desc    Add new contact
router.post('/', auth, async (req, res) => {
    const { name, phone } = req.body;

    try {
        const newContact = new Contact({
            name,
            phone,
            user: req.user.id
        });

        const contact = await newContact.save();
        res.json(contact);
    } catch (err) {
        console.error(err.message);
        res.status(500).send('Server Error');
    }
});

// @route   PUT api/contacts/:id
// @desc    Update contact
router.put('/:id', auth, async (req, res) => {
    const { name, phone } = req.body;

    const contactFields = {};
    if (name) contactFields.name = name;
    if (phone) contactFields.phone = phone;

    try {
        let contact = await Contact.findById(req.params.id);

        if (!contact) return res.status(404).json({ msg: 'Contact not found' });

        // Make sure user owns contact
        if (contact.user.toString() !== req.user.id) {
            return res.status(401).json({ msg: 'Not authorized' });
        }

        contact = await Contact.findByIdAndUpdate(
            req.params.id,
            { $set: contactFields },
            { new: true }
        );

        res.json(contact);
    } catch (err) {
        console.error(err.message);
        res.status(500).send('Server Error');
    }
});

// @route   DELETE api/contacts/:id
// @desc    Delete contact
router.delete('/:id', auth, async (req, res) => {
    try {
        let contact = await Contact.findById(req.params.id);

        if (!contact) return res.status(404).json({ msg: 'Contact not found' });

        // Make sure user owns contact
        if (contact.user.toString() !== req.user.id) {
            return res.status(401).json({ msg: 'Not authorized' });
        }

        await Contact.findByIdAndDelete(req.params.id);

        res.json({ msg: 'Contact removed' });
    } catch (err) {
        console.error(err.message);
        res.status(500).send('Server Error');
    }
});

module.exports = router;
