require('dotenv').config();
const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');

const app = express();

// Middleware
app.use(cors());
app.use(express.json({ limit: '50mb' }));
app.use(express.urlencoded({ limit: '50mb', extended: true }));

// Request Logger
app.use((req, res, next) => {
    console.log(`[${new Date().toLocaleTimeString()}] ${req.method} ${req.url}`);
    next();
});

// Ping Route for Connectivity Testing
app.get('/ping', (req, res) => {
    res.json({
        status: 'ok',
        serverId: 'CARECONNECT-LOCAL-SERVER-V1',
        message: 'Server is reachable!',
        time: new Date().toLocaleTimeString()
    });
});

// Routes
app.use('/api/auth', require('./routes/auth'));
app.use('/api/chats', require('./routes/chats'));
app.use('/api/contacts', require('./routes/contacts'));
app.use('/api/reminders', require('./routes/reminders'));
app.use('/api/donors', require('./routes/donors'));
app.use('/api/blood-requests', require('./routes/bloodRequests'));
app.use('/api/vaccinations', require('./routes/vaccinations'));

// 404 Handler
app.use((req, res, next) => {
    console.log(`404 - Not Found: ${req.method} ${req.url}`);
    res.status(404).json({ msg: 'Route not found' });
});

// Global Error Handler
app.use((err, req, res, next) => {
    console.error('SERVER ERROR:', err);
    if (err.stack) console.error(err.stack);
    res.status(500).json({ msg: 'Server Error', error: err.message });
});

// Database Connection
const PORT = process.env.PORT || 5000;
mongoose.connect(process.env.MONGO_URI)
    .then(() => {
        console.log('MongoDB Connected to:', mongoose.connection.name);
        app.listen(PORT, '0.0.0.0', () => {
            console.log(`🚀 Server running on all interfaces at PORT: ${PORT}`);
            console.log(`📡 Access locally at: http://localhost:${PORT}`);
            console.log(`🌍 Access from mobile at: http://172.16.126.183:${PORT}`);
        });
    })
    .catch(err => {
        console.error('❌ MongoDB connection error:', err);
        process.exit(1);
    });
