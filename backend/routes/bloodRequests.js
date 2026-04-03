const express = require('express');
const router = express.Router();
const auth = require('../middleware/auth');
const BloodRequest = require('../models/BloodRequest');
const User = require('../models/User');
const { sendPushNotification } = require('../utils/notifications');

// @route   POST api/blood-requests
// @desc    Create a blood request
router.post('/', auth, async (req, res) => {
    const { donorId } = req.body;
    console.log(`\n[NEW BLOOD REQUEST] Requester: ${req.user.id}, Donor: ${donorId}`);

    try {
        // Check if a pending request already exists
        const existing = await BloodRequest.findOne({
            requesterId: req.user.id,
            donorId,
            status: 'pending'
        });

        if (existing) {
            return res.status(400).json({ msg: 'Request already pending' });
        }

        const request = new BloodRequest({
            requesterId: req.user.id,
            donorId
        });

        await request.save();

        // Send Notification to Donor
        const donor = await User.findById(donorId);
        const requester = await User.findById(req.user.id);
        if (donor && donor.fcmToken) {
            console.log(`Sending Push Notification to Donor: ${donor.fullName} (Token: ${donor.fcmToken.substring(0, 10)}...)`);
            await sendPushNotification(
                donor.fcmToken,
                "New Blood Request",
                `${requester.fullName} needs your blood group!`,
                { type: 'blood_request', requestId: request._id.toString() }
            );
        } else {
            console.log(`Donor ${donorId} has no FCM token registered.`);
        }

        res.json(request);
    } catch (err) {
        console.error(err.message);
        res.status(500).send('Server Error');
    }
});

// @route   GET api/blood-requests/received
// @desc    Get requests received as a donor
router.get('/received', auth, async (req, res) => {
    try {
        const requests = await BloodRequest.find({
            donorId: req.user.id,
            hiddenFromDonor: { $ne: true }
        })
            .populate('requesterId', 'fullName bloodGroup profileImage phone')
            .sort({ createdAt: -1 });

        // Map to ensure phone is only shown if requester wants (or based on business logic)
        // Here we show it if status is approved as per user request
        const mappedRequests = requests.map(r => {
            const reqObj = r.toObject();
            if (reqObj.status !== 'approved' && reqObj.requesterId) {
                delete reqObj.requesterId.phone;
            }
            return reqObj;
        });

        res.json(mappedRequests);
    } catch (err) {
        console.error(err.message);
        res.status(500).send('Server Error');
    }
});

// @route   GET api/blood-requests/sent
// @desc    Get requests sent by the current user
router.get('/sent', auth, async (req, res) => {
    try {
        const requests = await BloodRequest.find({
            requesterId: req.user.id,
            hiddenFromRequester: { $ne: true }
        })
            .populate('donorId', 'fullName bloodGroup profileImage phone')
            .sort({ createdAt: -1 });

        const mappedRequests = requests.map(r => {
            const reqObj = r.toObject();
            if (reqObj.status !== 'approved' && reqObj.donorId) {
                delete reqObj.donorId.phone;
            }
            return reqObj;
        });

        res.json(mappedRequests);
    } catch (err) {
        console.error(err.message);
        res.status(500).send('Server Error');
    }
});

// @route   GET api/blood-requests/count
// @desc    Get count of pending received requests
router.get('/count', auth, async (req, res) => {
    try {
        const count = await BloodRequest.countDocuments({
            donorId: req.user.id,
            status: 'pending'
        });
        res.json({ count });
    } catch (err) {
        console.error(err.message);
        res.status(500).send('Server Error');
    }
});

// @route   PUT api/blood-requests/:id
// @desc    Update request status
router.put('/:id', auth, async (req, res) => {
    const { status } = req.body;

    try {
        let request = await BloodRequest.findById(req.params.id);
        console.log(`[UPDATE] Found Request: ${request ? 'YES' : 'NO'}`);
        if (!request) return res.status(404).json({ msg: 'Request not found' });

        console.log(`[UPDATE] Auth Check - DonorID (DB): ${request.donorId}, UserID (Token): ${req.user.id}`);
        // Ensure only the donor can update
        if (request.donorId.toString() !== req.user.id) {
            return res.status(401).json({ msg: 'Not authorized' });
        }

        request.status = status;
        await request.save();
        console.log(`[UPDATE] Status saved as: ${status}`);

        // Send Notification to Requester if approved/declined
        const requester = await User.findById(request.requesterId);
        const donor = await User.findById(req.user.id);
        console.log(`[NOTIFY] Requester: ${requester ? requester.fullName : 'NOT FOUND'}`);
        console.log(`[NOTIFY] Requester FCM Token: ${requester?.fcmToken ? 'PRESENT' : 'MISSING'}`);

        if (requester && requester.fcmToken) {
            const statusMsg = status === 'approved' ? 'approved' : 'declined';
            console.log(`[NOTIFY] Triggering Push to ${requester.fullName} for ${statusMsg}`);
            await sendPushNotification(
                requester.fcmToken,
                "Blood Request Update",
                `${donor.fullName} has ${statusMsg} your request.`,
                { type: 'request_update', requestId: request._id.toString(), status }
            );
        }

        res.json(request);
    } catch (err) {
        console.error(err.message);
        res.status(500).send('Server Error');
    }
});

// @route   DELETE api/blood-requests/:id
// @desc    Hide request from user's view (soft delete)
router.delete('/:id', auth, async (req, res) => {
    try {
        let request = await BloodRequest.findById(req.params.id);
        if (!request) return res.status(404).json({ msg: 'Request not found' });

        // Check if user is requester or donor
        const isRequester = request.requesterId.toString() === req.user.id;
        const isDonor = request.donorId.toString() === req.user.id;

        if (!isRequester && !isDonor) {
            return res.status(401).json({ msg: 'Not authorized' });
        }

        if (isRequester) {
            request.hiddenFromRequester = true;
        }
        if (isDonor) {
            request.hiddenFromDonor = true;
        }

        // If hidden from both, we could optionally delete from DB, 
        // but keeping it for audit/history is safer.
        await request.save();

        res.json({ msg: 'Request removed' });
    } catch (err) {
        console.error(err.message);
        res.status(500).send('Server Error');
    }
});

module.exports = router;
