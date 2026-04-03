const express = require('express');
const router = express.Router();
const jwt = require('jsonwebtoken');
const User = require('../models/User');
const Chat = require('../models/Chat');
const Contact = require('../models/Contact');
const Reminder = require('../models/Reminder');
const auth = require('../middleware/auth');

// @route   POST api/auth/register
// @desc    Register user
// @route   POST api/auth/register
// @desc    Register user
router.post('/register', async (req, res, next) => {
    console.log('--- Register Attempt ---');
    console.log('Body:', req.body);

    const { username, email, password, fullName, phone, bloodGroup, profileImage, fcmToken } = req.body;

    try {
        if (!username || !email || !password) {
            return res.status(400).json({ msg: 'Please provide required fields' });
        }

        // Normalize email and username
        const normalizedEmail = email.toLowerCase().trim();
        const normalizedUsername = username.toLowerCase().trim();

        if (!normalizedEmail.endsWith('@gmail.com')) {
            console.log('Invalid email domain:', normalizedEmail);
            return res.status(400).json({ msg: 'Only @gmail.com email addresses are allowed' });
        }

        let user = await User.findOne({ $or: [{ email: normalizedEmail }, { username: normalizedUsername }] });
        if (user) {
            console.log('User already exists (email or username taken)');
            const field = user.email.toLowerCase() === normalizedEmail ? 'Email' : 'Username';
            return res.status(400).json({ msg: `${field} is already taken` });
        }

        user = new User({
            username: normalizedUsername,
            email: normalizedEmail,
            password,
            fullName,
            phone,
            bloodGroup,
            profileImage,
            fcmToken
        });

        console.log('Saving user...');
        await user.save();
        console.log('User saved successfully');

        const payload = { user: { id: user.id } };

        jwt.sign(
            payload,
            process.env.JWT_SECRET,
            { expiresIn: '30d' },
            (err, token) => {
                if (err) {
                    console.error('JWT Signing Error:', err);
                    return res.status(500).json({ msg: 'Error generating token' });
                }
                res.json({
                    token, user: {
                        id: user.id,
                        username: user.username,
                        email: user.email,
                        fullName: user.fullName,
                        phone: user.phone,
                        bloodGroup: user.bloodGroup,
                        profileImage: user.profileImage
                    }
                });
            }
        );
    } catch (err) {
        console.error('Registration Catch Block Error:', err);
        res.status(500).json({ msg: 'Registration failed', error: err.message });
    }
});

// @route   POST api/auth/login
// @desc    Authenticate user & get token
router.post('/login', async (req, res) => {
    const { username, password, fcmToken } = req.body;
    console.log('--- Login Attempt ---');
    console.log('Username provided:', username);

    try {
        // Find user by username OR email to be more flexible
        let user = await User.findOne({
            $or: [{ username }, { email: username }]
        });

        if (!user) {
            console.log('User not found in database');
            console.log(`[AUTH] Login Failed: User ${username} not found.`);
            return res.status(400).json({ msg: 'Invalid Credentials' });
        }

        console.log('User found, comparing passwords...');
        const isMatch = await user.comparePassword(password);
        console.log('Password match result:', isMatch);

        if (!isMatch) {
            console.log(`[AUTH] Login Failed: Incorrect password for ${user.username}.`);
            return res.status(400).json({ msg: 'Invalid Credentials' });
        }

        // Update FCM Token if provided
        if (fcmToken) {
            user.fcmToken = fcmToken;
            await user.save();
            console.log(`[AUTH] User ${user.username} logged in. FCM Token updated: ${fcmToken.substring(0, 10)}...`);
        } else {
            console.log(`[AUTH] User ${user.username} logged in. (No FCM Token provided)`);
        }

        const payload = { user: { id: user.id } };

        jwt.sign(
            payload,
            process.env.JWT_SECRET,
            { expiresIn: '30d' },
            (err, token) => {
                if (err) {
                    console.error('JWT Signing Error:', err);
                    return res.status(500).json({ msg: 'Error generating token' });
                }
                res.json({
                    token, user: {
                        id: user.id,
                        username: user.username,
                        email: user.email,
                        fullName: user.fullName,
                        phone: user.phone,
                        bloodGroup: user.bloodGroup,
                        profileImage: user.profileImage
                    }
                });
            }
        );
    } catch (err) {
        console.error('Login Catch Block Error:', err);
        res.status(500).json({ msg: 'Server Error' });
    }
});

// @route   GET api/auth/profile
// @desc    Get current user profile
router.get('/profile', auth, async (req, res) => {
    try {
        const user = await User.findById(req.user.id).select('-password');
        res.json(user);
    } catch (err) {
        console.error(err.message);
        res.status(500).send('Server Error');
    }
});

// @route   PUT api/auth/profile
// @desc    Update user profile
router.put('/profile', auth, async (req, res) => {
    const { fullName, email, phone, bloodGroup, profileImage } = req.body;

    const profileFields = {};
    if (fullName) profileFields.fullName = fullName;
    if (email) profileFields.email = email;
    if (phone) profileFields.phone = phone;
    if (bloodGroup) profileFields.bloodGroup = bloodGroup;
    if (profileImage) profileFields.profileImage = profileImage;

    try {
        let user = await User.findById(req.user.id);
        if (!user) return res.status(404).json({ msg: 'User not found' });

        user = await User.findByIdAndUpdate(
            req.user.id,
            { $set: profileFields },
            { new: true }
        ).select('-password');

        res.json(user);
    } catch (err) {
        console.error(err.message);
        res.status(500).send('Server Error');
    }
});

// @route   DELETE api/auth/
// @desc    Delete user account and all associated data
router.delete('/', auth, async (req, res) => {
    const { password } = req.body;

    if (!password) {
        return res.status(400).json({ msg: 'Please provide your password to delete your account' });
    }

    try {
        const user = await User.findById(req.user.id);
        if (!user) {
            return res.status(404).json({ msg: 'User not found' });
        }

        // Verify password
        const isMatch = await user.comparePassword(password);
        if (!isMatch) {
            return res.status(400).json({ msg: 'Invalid password. Account deletion aborted.' });
        }

        console.log(`--- Deleting Account for User: ${user.username} ---`);

        // Delete associated data
        await Promise.all([
            Chat.deleteMany({ user: user.id }),
            Contact.deleteMany({ user: user.id }),
            Reminder.deleteMany({ user: user.id }),
            User.findByIdAndDelete(req.user.id)
        ]);

        console.log(`Account and data deleted successfully for ${user.username}`);
        res.json({ msg: 'Account deleted successfully' });
    } catch (err) {
        console.error('Account Deletion Error:', err.message);
        res.status(500).send('Server Error');
    }
});

module.exports = router;
