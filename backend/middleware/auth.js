const admin = require('firebase-admin');

// Middleware to verify Firebase Auth tokens
async function verifyToken(req, res, next) {
  const authHeader = req.headers.authorization;
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return res.status(401).json({ error: 'Unauthorized: Missing or invalid Bearer token' });
  }

  const idToken = authHeader.split('Bearer ')[1];

  try {
    const decodedToken = await admin.auth().verifyIdToken(idToken);
    req.user = decodedToken;
    next();
  } catch (error) {
    console.error('Token verification failed for request:', req.method, req.originalUrl);
    return res.status(403).json({ error: 'Unauthorized: Invalid token' });
  }
}

module.exports = verifyToken;
