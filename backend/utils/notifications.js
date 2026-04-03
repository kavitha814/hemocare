const admin = require('firebase-admin');

const path = require('path');

// Initialize Firebase Admin
if (!admin.apps.length) {
    try {
        let credential;

        // Priority 1: Environment Variable (Perfect for Render)
        if (process.env.FIREBASE_SERVICE_ACCOUNT) {
            const serviceAccount = JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT);
            credential = admin.credential.cert(serviceAccount);
            console.log('Firebase Admin Initialized from Environment Variable');
        }
        // Priority 2: Local File (Development)
        else {
            try {
                const serviceAccount = require('../serviceAccountKey.json');
                credential = admin.credential.cert(serviceAccount);
                console.log('Firebase Admin Initialized from local file');
            } catch (fileErr) {
                console.warn('Firebase Admin: Local serviceAccountKey.json not found.');
            }
        }

        if (credential) {
            admin.initializeApp({ credential });
        }
    } catch (error) {
        console.error('Firebase Admin Initialization Error:', error.message);
    }
}

const sendPushNotification = async (token, title, body, data = {}) => {
    if (!token) return;

    const message = {
        notification: {
            title,
            body
        },
        android: {
            priority: 'high',
            notification: {
                channel_id: 'instant_alerts',
                click_action: 'FLUTTER_NOTIFICATION_CLICK'
            }
        },
        data,
        token
    };

    try {
        const response = await admin.messaging().send(message);
        console.log('Successfully sent message:', response);
        return response;
    } catch (error) {
        console.error('Error sending message:', error);
    }
};

module.exports = { sendPushNotification };
