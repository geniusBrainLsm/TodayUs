const express = require('express');
const cors = require('cors');
const app = express();
const PORT = 8080;

app.use(cors());
app.use(express.json());

// Mock JWT token
const MOCK_JWT = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxIiwiZW1haWwiOiJ0ZXN0QGV4YW1wbGUuY29tIiwiaWF0IjoxNjE2MjM5MDIyfQ.test';

// Mock user data
const mockUser = {
  id: 1,
  email: 'test@example.com',
  name: 'Test User',
  nickname: 'tester',
  nicknameSet: true,
  profileImageUrl: 'https://example.com/avatar.jpg',
  provider: 'GOOGLE',
  role: 'USER',
  createdAt: '2023-01-01T00:00:00.000000'
};

// Authentication endpoints
app.post('/api/auth/google', (req, res) => {
  console.log('Google login request received');
  res.json({ token: MOCK_JWT });
});

app.post('/api/auth/kakao', (req, res) => {
  console.log('Kakao login request received');
  res.json({ token: MOCK_JWT });
});

app.get('/api/auth/me', (req, res) => {
  console.log('Get user info request received');
  res.json(mockUser);
});

app.get('/api/auth/onboarding-status', (req, res) => {
  console.log('Onboarding status request received');
  res.json({
    hasAnniversary: false,
    hasNickname: true,
    hasCoupleConnection: false,
    nextStep: 'couple_connection'
  });
});

// Anniversary endpoints
app.get('/api/anniversary', (req, res) => {
  console.log('Get anniversary request received');
  res.status(204).send(); // No content = no anniversary set
});

app.post('/api/anniversary', (req, res) => {
  console.log('Set anniversary request received:', req.body);
  res.json({
    anniversaryDate: req.body.anniversaryDate,
    daysSince: 1,
    formattedDate: '2024년 1월 1일',
    daysDisplay: 'D+1',
    canEdit: true,
    setterName: 'Test User'
  });
});

// Couple endpoints
app.get('/api/couples/info', (req, res) => {
  console.log('Get couple info request received');
  res.status(204).send(); // No couple connected
});

app.post('/api/couples/invite-code', (req, res) => {
  console.log('Generate invite code request received');
  res.json({ inviteCode: 'TEST123' });
});

// Diary endpoints
app.get('/api/diaries', (req, res) => {
  console.log('Get diaries request received');
  res.json([]);
});

app.post('/api/diaries', (req, res) => {
  console.log('Create diary request received:', req.body);
  res.json({
    id: 1,
    title: req.body.title,
    content: req.body.content,
    diaryDate: req.body.diaryDate,
    moodEmoji: req.body.moodEmoji,
    imageUrl: req.body.imageUrl,
    createdAt: new Date().toISOString()
  });
});

// Error handling
app.use((err, req, res, next) => {
  console.error(err.stack);
  res.status(500).json({ error: 'Something went wrong!' });
});

app.listen(PORT, () => {
  console.log(`🚀 Mock TodayUs Backend Server running on http://localhost:${PORT}`);
  console.log('📱 Ready to serve Flutter app requests!');
});