require('dotenv').config();
const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const rateLimit = require('express-rate-limit');
const admin = require('firebase-admin');
const mongoose = require('mongoose');
const verifyToken = require('./middleware/auth');
const path = require('path');
const fs = require('fs');
const multer = require('multer');
const cloudinary = require('cloudinary').v2;

// 1. Initialize Firebase Admin SDK (Only used for Token Verification)
const serviceAccountPath = path.join(__dirname, 'service-account-key.json');
let initialized = false;

if (fs.existsSync(serviceAccountPath)) {
  try {
    admin.initializeApp({
      credential: admin.credential.cert(require(serviceAccountPath))
    });
    console.log('Firebase Admin SDK initialized using local service-account-key.json');
    initialized = true;
  } catch (e) {
    console.error('Failed to initialize Firebase Admin with service-account-key.json:', e.message);
  }
}

if (!initialized) {
  delete process.env.GOOGLE_APPLICATION_CREDENTIALS;
  try {
    admin.initializeApp({
      projectId: 'gridpooled'
    });
    console.log('Firebase Admin SDK initialized using default credentials for project gridpooled');
  } catch (e) {
    console.log('Firebase Admin init warning:', e.message);
    if (!admin.apps.length) {
        admin.initializeApp({ projectId: 'gridpooled' });
    }
  }
}

// 2. Configure Cloudinary
cloudinary.config({
  cloud_name: process.env.CLOUDINARY_CLOUD_NAME,
  api_key: process.env.CLOUDINARY_API_KEY,
  api_secret: process.env.CLOUDINARY_API_SECRET,
});

const cloudinaryConfigured = !!(
  process.env.CLOUDINARY_CLOUD_NAME &&
  process.env.CLOUDINARY_API_KEY &&
  process.env.CLOUDINARY_API_SECRET
);

if (cloudinaryConfigured) {
  console.log('Cloudinary configured successfully');
} else {
  console.warn('Cloudinary credentials missing — image upload will be disabled');
}

// Multer setup for in-memory file storage
const upload = multer({
  storage: multer.memoryStorage(),
  limits: { fileSize: 10 * 1024 * 1024 }, // 10MB max
  fileFilter: (req, file, cb) => {
    if (file.mimetype.startsWith('image/')) {
      cb(null, true);
    } else {
      cb(new Error('Only image files are allowed'), false);
    }
  }
});

// 3. Connect to MongoDB
const MONGODB_URI = process.env.MONGODB_URI || 'mongodb://127.0.0.1:27017/gridpool';
mongoose.connect(MONGODB_URI)
  .then(() => console.log('Connected to MongoDB'))
  .catch(err => console.error('MongoDB connection error:', err));

// Global JSON transforms for Mongoose models to match frontend expectations
mongoose.set('toJSON', {
  virtuals: true,
  transform: (doc, ret) => {
    if (ret._id && !ret.id) {
      ret.id = ret._id.toString();
    }
    delete ret._id;
    delete ret.__v;
    return ret;
  }
});

// 4. Define MongoDB Schemas and Models
const userSchema = new mongoose.Schema({
  uid: { type: String, required: true, unique: true },
  name: { type: String, required: true },
  email: { type: String, required: true },
  avatarUrl: { type: String, required: true },
  upiId: { type: String, default: null },
  onboardingCompleted: { type: Boolean, default: false },
  notificationPreference: { type: Boolean, default: true },
  createdAt: { type: Date, default: Date.now }
});
userSchema.virtual('id').get(function() {
  return this.uid;
});
const User = mongoose.model('User', userSchema);

const poolSchema = new mongoose.Schema({
  name: { type: String, required: true, maxlength: 200 },
  description: { type: String, required: true, maxlength: 2000 },
  currency: { type: String, default: 'INR', enum: ['INR', 'USD', 'EUR', 'GBP'] },
  upiId: { type: String, default: null },
  inviteCode: { type: String, default: '' },
  createdBy: { type: String, required: true },
  createdAt: { type: Date, default: Date.now },
  memberIds: [{ type: String }],
  memberCount: { type: Number, default: 1 },
  totalCollected: { type: Number, default: 0.0 },
  totalSpent: { type: Number, default: 0.0 },
  currentBalance: { type: Number, default: 0.0 },
  pendingAmount: { type: Number, default: 0.0 },
  frequency: { type: String, enum: ['once', 'weekly', 'monthly', 'quarterly', 'yearly', 'custom'], default: 'once' },
  customInterval: { type: String, default: null },
  expectedContribution: { type: Number, default: 0.0, min: 0 }
});
const Pool = mongoose.model('Pool', poolSchema);

const poolMemberSchema = new mongoose.Schema({
  poolId: { type: mongoose.Schema.Types.ObjectId, ref: 'Pool', required: true },
  userId: { type: String, required: true },
  name: { type: String, required: true },
  email: { type: String, default: '' },
  avatarUrl: { type: String, default: '' },
  role: { type: String, default: 'member' },
  isCustom: { type: Boolean, default: false },
  addedBy: { type: String, default: null },
  joinedAt: { type: Date, default: Date.now },
  approvedBy: { type: String, default: null },
  dueAmount: { type: Number, default: 0.0 },
  lastDueAppliedAt: { type: Date, default: Date.now }
});
poolMemberSchema.index({ poolId: 1, userId: 1 }, { unique: true });
poolMemberSchema.virtual('id').get(function() {
  return this.userId;
});
const PoolMember = mongoose.model('PoolMember', poolMemberSchema);

const joinRequestSchema = new mongoose.Schema({
  poolId: { type: mongoose.Schema.Types.ObjectId, ref: 'Pool', required: true },
  userId: { type: String, required: true },
  userName: { type: String, required: true },
  userEmail: { type: String, required: true },
  userAvatarUrl: { type: String, required: true },
  status: { type: String, default: 'pending' },
  createdAt: { type: Date, default: Date.now },
  reviewedAt: { type: Date, default: null },
  reviewedBy: { type: String, default: null }
});
joinRequestSchema.index({ poolId: 1, userId: 1 }, { unique: true });
joinRequestSchema.virtual('id').get(function() {
  return this.userId;
});
const JoinRequest = mongoose.model('JoinRequest', joinRequestSchema);

const paymentRequestSchema = new mongoose.Schema({
  poolId: { type: mongoose.Schema.Types.ObjectId, ref: 'Pool', required: true },
  userId: { type: String, required: true },
  name: { type: String, required: true },
  amount: { type: Number, required: true, min: 0.01 },
  screenshotUrl: { type: String, required: true },
  status: { type: String, enum: ['PENDING', 'APPROVED', 'REJECTED'], default: 'PENDING' },
  submittedAt: { type: Date, default: Date.now },
  reviewedAt: { type: Date, default: null },
  reviewedBy: { type: String, default: null }
});
paymentRequestSchema.virtual('id').get(function() { return this._id.toHexString(); });
paymentRequestSchema.set('toJSON', { virtuals: true });
const PaymentRequest = mongoose.model('PaymentRequest', paymentRequestSchema);


const contributionSchema = new mongoose.Schema({
  poolId: { type: mongoose.Schema.Types.ObjectId, ref: 'Pool', required: true },
  title: { type: String, required: true },
  defaultAmount: { type: Number, required: true },
  memberAmounts: { type: Map, of: Number, default: {} },
  createdBy: { type: String, required: true },
  createdAt: { type: Date, default: Date.now },
  paidByMembers: [{ type: String }]
});
const Contribution = mongoose.model('Contribution', contributionSchema);

const expenseSchema = new mongoose.Schema({
  poolId: { type: mongoose.Schema.Types.ObjectId, ref: 'Pool', required: true },
  title: { type: String, required: true, maxlength: 500 },
  amount: { type: Number, required: true, min: 0.01 },
  category: { type: String, default: 'Other' },
  note: { type: String, default: '', maxlength: 2000 },
  receiptUrl: { type: String, default: null },
  createdBy: { type: String, required: true },
  createdAt: { type: Date, default: Date.now }
});
const Expense = mongoose.model('Expense', expenseSchema);

const ledgerEntrySchema = new mongoose.Schema({
  poolId: { type: mongoose.Schema.Types.ObjectId, ref: 'Pool', required: true },
  type: { type: String, required: true },
  amount: { type: Number, required: true },
  timestamp: { type: Date, default: Date.now },
  createdBy: { type: String, required: true },
  description: { type: String, required: true },
  relatedContributionId: { type: String, default: null },
  relatedExpenseId: { type: String, default: null }
});
const LedgerEntry = mongoose.model('LedgerEntry', ledgerEntrySchema);

const poolInviteSchema = new mongoose.Schema({
  code: { type: String, required: true, unique: true },
  poolId: { type: mongoose.Schema.Types.ObjectId, ref: 'Pool', required: true },
  active: { type: Boolean, default: true },
  createdBy: { type: String, required: true },
  createdAt: { type: Date, default: Date.now }
});
const PoolInvite = mongoose.model('PoolInvite', poolInviteSchema);

// 5. Initialize Express Application
const app = express();

// Security: Helmet sets various HTTP security headers
app.use(helmet());

// Security: CORS — restrict to known origins (update for production)
const allowedOrigins = process.env.ALLOWED_ORIGINS
  ? process.env.ALLOWED_ORIGINS.split(',')
  : ['http://localhost:3000', 'http://10.0.2.2:3000'];
app.use(cors({
  origin: function (origin, callback) {
    // Allow requests with no origin (mobile apps, curl, etc.)
    if (!origin) return callback(null, true);
    if (allowedOrigins.includes(origin)) {
      return callback(null, true);
    }
    return callback(null, true); // For mobile app - adjust for web deployment
  },
  methods: ['GET', 'POST', 'PUT', 'DELETE'],
  allowedHeaders: ['Content-Type', 'Authorization'],
}));

// Security: Rate limiting — 100 requests per minute per IP
const apiLimiter = rateLimit({
  windowMs: 60 * 1000,
  max: 100,
  standardHeaders: true,
  legacyHeaders: false,
  message: { error: 'Too many requests, please try again later.' }
});
app.use('/api', apiLimiter);

// Security: Limit request body size
app.use(express.json({ limit: '100kb' }));

// Apply token verification middleware
app.use('/api', verifyToken);

// 6. Helper Functions

// Reusable admin/owner authorization check
async function requireAdminOrOwner(poolId, userId, session = null) {
  const query = PoolMember.findOne({ poolId, userId });
  const callerMember = session ? await query.session(session) : await query;
  if (!callerMember || (callerMember.role !== 'owner' && callerMember.role !== 'admin')) {
    return null;
  }
  return callerMember;
}

// Reusable pool membership check
async function requireMembership(poolId, userId) {
  const pool = await Pool.findById(poolId);
  if (!pool) return null;
  if (!pool.memberIds.includes(userId)) return null;
  return pool;
}

async function generateInviteCode(poolId, ownerId, session = null) {
  const alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  for (let attempt = 0; attempt < 5; attempt++) {
    let code = '';
    for (let i = 0; i < 6; i++) {
      code += alphabet[Math.floor(Math.random() * alphabet.length)];
    }
    
    const existingInvite = await PoolInvite.findOne({ code });
    if (!existingInvite) {
      const createOpts = session ? { session } : {};
      await PoolInvite.create([{
        poolId,
        code,
        active: true,
        createdBy: ownerId
      }], createOpts);
      return code;
    }
  }
  throw new Error('Could not generate unique invite code');
}

// Shared user upsert logic — used by both ensureUserExists and /users/sync
async function upsertUser({ uid, name, email, avatarUrl, onboardingCompleted }) {
  let user = await User.findOne({ uid });
  if (!user) {
    if (email) {
      user = await User.findOne({ email });
      if (user) {
        user.uid = uid;
        if (name) user.name = name;
        if (avatarUrl) user.avatarUrl = avatarUrl;
        await user.save();
        return user;
      }
    }

    user = await User.create({
      uid,
      name: name || 'Unknown User',
      email: email || '',
      avatarUrl: avatarUrl || '',
      onboardingCompleted: onboardingCompleted || false
    });
  }
  return user;
}

async function ensureUserExists(firebaseUser) {
  return upsertUser({
    uid: firebaseUser.uid,
    name: firebaseUser.name,
    email: firebaseUser.email,
    avatarUrl: firebaseUser.picture,
  });
}

// Shared user profile update logic — used by /users/profile POST and /users/onboarding/complete
function applyProfileUpdates(user, { name, upiId, notificationPreference, avatarUrl }) {
  if (name !== undefined && name.trim().length > 0) {
    user.name = name.trim();
  }
  if (upiId !== undefined) {
    user.upiId = upiId && upiId.trim().length > 0 ? upiId.trim() : null;
  }
  if (notificationPreference !== undefined) {
    user.notificationPreference = !!notificationPreference;
  }
  if (avatarUrl !== undefined && avatarUrl.trim().length > 0) {
    user.avatarUrl = avatarUrl.trim();
  }
}

// Cloudinary upload helper
function uploadToCloudinary(fileBuffer, folder = 'gridpool') {
  return new Promise((resolve, reject) => {
    const uploadStream = cloudinary.uploader.upload_stream(
      {
        folder,
        resource_type: 'image',
        transformation: [
          { width: 1200, height: 1200, crop: 'limit' },
          { quality: 'auto', fetch_format: 'auto' }
        ]
      },
      (error, result) => {
        if (error) reject(error);
        else resolve(result);
      }
    );
    uploadStream.end(fileBuffer);
  });
}

// Lazy evaluation for due amounts — idempotent via absolute $set instead of $inc
async function applyDueUpdates(poolId, members) {
  const pool = await Pool.findById(poolId);
  if (!pool || pool.frequency === 'once' || pool.expectedContribution <= 0) return members;

  const now = new Date();
  const bulkOps = [];
  const updatedMembers = [];

  let totalPendingDue = 0;

  for (let member of members) {
    let lastApplied = member.lastDueAppliedAt || member.joinedAt || now;
    let periodsPassed = 0;
    
    // For days-based calculation
    const diffTime = Math.max(0, now - lastApplied);
    const diffDays = Math.floor(diffTime / (1000 * 60 * 60 * 24));
    
    // For months-based calculation
    let monthsDiff = (now.getFullYear() - lastApplied.getFullYear()) * 12;
    monthsDiff -= lastApplied.getMonth();
    monthsDiff += now.getMonth();
    if (now.getDate() < lastApplied.getDate()) {
      monthsDiff--;
    }
    monthsDiff = Math.max(0, monthsDiff);

    if (pool.frequency === 'weekly') {
      periodsPassed = Math.floor(diffDays / 7);
    } else if (pool.frequency === 'monthly') {
      periodsPassed = monthsDiff;
    } else if (pool.frequency === 'quarterly') {
      periodsPassed = Math.floor(monthsDiff / 3);
    } else if (pool.frequency === 'yearly') {
      periodsPassed = Math.floor(monthsDiff / 12);
    } else if (pool.frequency === 'custom' && pool.customInterval) {
      const intervalDays = parseInt(pool.customInterval);
      if (intervalDays > 0) {
        periodsPassed = Math.floor(diffDays / intervalDays);
      }
    }

    if (periodsPassed > 0) {
      const additionalDue = periodsPassed * pool.expectedContribution;
      member.dueAmount = (member.dueAmount || 0) + additionalDue;
      
      let newDate = new Date(lastApplied);
      if (pool.frequency === 'weekly') {
        newDate.setDate(newDate.getDate() + (periodsPassed * 7));
      } else if (pool.frequency === 'monthly') {
        newDate.setMonth(newDate.getMonth() + periodsPassed);
      } else if (pool.frequency === 'quarterly') {
        newDate.setMonth(newDate.getMonth() + (periodsPassed * 3));
      } else if (pool.frequency === 'yearly') {
        newDate.setFullYear(newDate.getFullYear() + periodsPassed);
      } else if (pool.frequency === 'custom' && pool.customInterval) {
        const intervalDays = parseInt(pool.customInterval);
        newDate.setDate(newDate.getDate() + (periodsPassed * intervalDays));
      }
      
      member.lastDueAppliedAt = newDate;

      // Use absolute $set instead of relative $inc to prevent race condition doubling
      bulkOps.push({
        updateOne: {
          filter: { _id: member._id },
          update: { $set: { dueAmount: member.dueAmount, lastDueAppliedAt: member.lastDueAppliedAt } }
        }
      });
    }

    // Accumulate all member dues for idempotent pool update
    totalPendingDue += (member.dueAmount || 0);
    updatedMembers.push(member);
  }

  if (bulkOps.length > 0) {
    await PoolMember.bulkWrite(bulkOps);
    // Use absolute $set for pendingAmount to avoid race condition doubling
    await Pool.findByIdAndUpdate(poolId, {
      $set: { pendingAmount: totalPendingDue }
    });
  }

  return updatedMembers;
}

// 7. Image Upload Route
app.post('/api/upload', upload.single('image'), async (req, res) => {
  try {
    if (!cloudinaryConfigured) {
      return res.status(503).json({ error: 'Image upload is not configured. Please set Cloudinary credentials.' });
    }

    if (!req.file) {
      return res.status(400).json({ error: 'No image file provided' });
    }

    const folder = req.body.folder || 'gridpool';
    const result = await uploadToCloudinary(req.file.buffer, folder);

    res.json({
      url: result.secure_url,
      publicId: result.public_id,
      width: result.width,
      height: result.height,
    });
  } catch (error) {
    console.error('Upload error:', error);
    res.status(500).json({ error: 'Failed to upload image' });
  }
});

// 8. User Profile Routes
app.post('/api/users/sync', async (req, res) => {
  try {
    const { name, email, avatarUrl } = req.body;
    let user = await User.findOne({ uid: req.user.uid });
    
    if (!user) {
      user = await upsertUser({
        uid: req.user.uid,
        name,
        email,
        avatarUrl,
      });
    } else {
      user.name = name;
      user.email = email;
      user.avatarUrl = avatarUrl;
      await user.save();
    }
    res.json(user);
  } catch (error) {
    console.error('Error syncing user:', error);
    res.status(500).json({ error: 'Failed to sync user profile' });
  }
});

app.get('/api/users/profile', async (req, res) => {
  try {
    const user = await ensureUserExists(req.user);
    res.json(user);
  } catch (error) {
    console.error('Error fetching user profile:', error);
    res.status(500).json({ error: 'Failed to fetch user profile' });
  }
});

app.post('/api/users/profile', async (req, res) => {
  try {
    const user = await ensureUserExists(req.user);
    applyProfileUpdates(user, req.body);
    await user.save();
    res.json(user);
  } catch (error) {
    console.error('Error updating user profile:', error);
    res.status(500).json({ error: 'Failed to update user profile' });
  }
});

app.post('/api/users/onboarding/complete', async (req, res) => {
  try {
    const user = await ensureUserExists(req.user);
    applyProfileUpdates(user, req.body);
    user.onboardingCompleted = true;
    await user.save();
    res.json(user);
  } catch (error) {
    console.error('Error completing onboarding:', error);
    res.status(500).json({ error: 'Failed to complete onboarding' });
  }
});


// 9. Pool Management Routes
app.post('/api/pools/create', async (req, res) => {
  const session = await mongoose.startSession();
  try {
    session.startTransaction();
    const { name, description, upiId, currency = 'INR', ownerName, ownerEmail, ownerAvatarUrl, frequency = 'once', customInterval = null, expectedContribution = 0.0 } = req.body;
    const userId = req.user.uid;

    // Input validation
    if (!name || typeof name !== 'string' || name.trim().length === 0) {
      await session.abortTransaction(); session.endSession();
      return res.status(400).json({ error: 'Pool name is required' });
    }
    if (!description || typeof description !== 'string' || description.trim().length === 0) {
      await session.abortTransaction(); session.endSession();
      return res.status(400).json({ error: 'Pool description is required' });
    }
    const parsedContribution = parseFloat(expectedContribution || 0.0);
    if (isNaN(parsedContribution) || parsedContribution < 0) {
      await session.abortTransaction(); session.endSession();
      return res.status(400).json({ error: 'Expected contribution must be a non-negative number' });
    }
    if (frequency === 'custom' && customInterval) {
      const intervalDays = parseInt(customInterval);
      if (isNaN(intervalDays) || intervalDays <= 0) {
        await session.abortTransaction(); session.endSession();
        return res.status(400).json({ error: 'Custom interval must be a positive number of days' });
      }
    }

    const pool = new Pool({
      name: name.trim(),
      description: description.trim(),
      currency,
      upiId: upiId ? upiId.trim() : null,
      createdBy: userId,
      memberIds: [userId],
      memberCount: 1,
      frequency,
      customInterval: customInterval ? customInterval.trim() : null,
      expectedContribution: parsedContribution
    });
    await pool.save({ session });
    const poolId = pool._id.toString();

    const ownerMember = new PoolMember({
      poolId: pool._id,
      userId,
      name: ownerName,
      email: ownerEmail,
      avatarUrl: ownerAvatarUrl,
      role: 'owner',
      dueAmount: parsedContribution,
      lastDueAppliedAt: new Date()
    });
    await ownerMember.save({ session });

    // Pass session so invite is part of the transaction
    const inviteCode = await generateInviteCode(poolId, userId, session);
    pool.inviteCode = inviteCode;
    await pool.save({ session });

    await session.commitTransaction();
    session.endSession();
    
    res.json(pool);
  } catch (error) {
    await session.abortTransaction();
    session.endSession();
    console.error('Error creating pool:', error);
    res.status(500).json({ error: 'Failed to create pool' });
  }
});

app.post('/api/pools/join', async (req, res) => {
  try {
    const { inviteCode, userName, userEmail, userAvatarUrl } = req.body;
    const userId = req.user.uid;

    // Input validation
    if (!inviteCode || typeof inviteCode !== 'string' || inviteCode.trim().length === 0) {
      return res.status(400).json({ error: 'Invite code is required' });
    }

    const invite = await PoolInvite.findOne({ code: inviteCode.trim(), active: true });
    if (!invite) {
      return res.status(404).json({ error: 'Invite code not found or inactive' });
    }

    const poolId = invite.poolId;

    const existingMember = await PoolMember.findOne({ poolId, userId });
    if (existingMember) {
      return res.status(400).json({ error: 'You are already a member of this pool' });
    }

    await JoinRequest.findOneAndUpdate(
      { poolId, userId },
      {
        userName,
        userEmail,
        userAvatarUrl,
        status: 'pending',
        createdAt: new Date()
      },
      { upsert: true, new: true }
    );

    res.json({ message: 'Join request submitted successfully', poolId: poolId.toString() });
  } catch (error) {
    console.error('Error joining pool:', error);
    res.status(500).json({ error: 'Failed to submit join request' });
  }
});

app.get('/api/pools', async (req, res) => {
  try {
    const pools = await Pool.find({ memberIds: req.user.uid }).sort({ createdAt: -1 });
    res.json(pools);
  } catch (error) {
    console.error('Error fetching pools:', error);
    res.status(500).json({ error: 'Failed to fetch pools' });
  }
});

// Authorization: Only pool members can view members
app.get('/api/pools/:poolId/members', async (req, res) => {
  try {
    const pool = await requireMembership(req.params.poolId, req.user.uid);
    if (!pool) {
      return res.status(403).json({ error: 'You are not a member of this pool' });
    }
    let members = await PoolMember.find({ poolId: req.params.poolId }).sort({ joinedAt: 1 });
    members = await applyDueUpdates(req.params.poolId, members);
    res.json(members);
  } catch (error) {
    console.error('Error fetching members:', error);
    res.status(500).json({ error: 'Failed to fetch members' });
  }
});

// Authorization: Only admin/owner can view join requests
app.get('/api/pools/:poolId/join-requests', async (req, res) => {
  try {
    const caller = await requireAdminOrOwner(req.params.poolId, req.user.uid);
    if (!caller) {
      return res.status(403).json({ error: 'Only pool admins or owners can view join requests' });
    }
    const requests = await JoinRequest.find({ poolId: req.params.poolId, status: 'pending' }).sort({ createdAt: -1 });
    res.json(requests);
  } catch (error) {
    console.error('Error fetching join requests:', error);
    res.status(500).json({ error: 'Failed to fetch join requests' });
  }
});

// Authorization: Only admin/owner can approve join requests
app.post('/api/pools/:poolId/join-requests/approve', async (req, res) => {
  const session = await mongoose.startSession();
  try {
    session.startTransaction();
    const { poolId } = req.params;
    const { userId } = req.body;
    const approverId = req.user.uid;

    // Authorization check
    const caller = await requireAdminOrOwner(poolId, approverId, session);
    if (!caller) {
      await session.abortTransaction(); session.endSession();
      return res.status(403).json({ error: 'Only pool admins or owners can approve join requests' });
    }

    const pool = await Pool.findById(poolId).session(session);
    if (!pool) {
      await session.abortTransaction(); session.endSession();
      return res.status(404).json({ error: 'Pool not found' });
    }

    if (!userId || typeof userId !== 'string') {
      await session.abortTransaction(); session.endSession();
      return res.status(400).json({ error: 'User ID is required' });
    }

    const joinRequest = await JoinRequest.findOne({ poolId, userId, status: 'pending' }).session(session);
    if (!joinRequest) {
      await session.abortTransaction(); session.endSession();
      return res.status(404).json({ error: 'Pending join request not found' });
    }

    const newMember = new PoolMember({
      poolId,
      userId,
      name: joinRequest.userName,
      email: joinRequest.userEmail,
      avatarUrl: joinRequest.userAvatarUrl,
      role: 'member',
      approvedBy: approverId,
      dueAmount: pool.expectedContribution,
      lastDueAppliedAt: new Date()
    });
    await newMember.save({ session });

    pool.memberIds.push(userId);
    pool.memberCount += 1;
    await pool.save({ session });

    joinRequest.status = 'approved';
    joinRequest.reviewedAt = new Date();
    joinRequest.reviewedBy = approverId;
    await joinRequest.save({ session });

    await session.commitTransaction();
    session.endSession();

    res.json({ message: 'Join request approved successfully' });
  } catch (error) {
    await session.abortTransaction();
    session.endSession();
    console.error('Error approving join request:', error);
    res.status(500).json({ error: 'Failed to approve join request' });
  }
});

// Authorization: Only admin/owner can reject join requests
app.post('/api/pools/:poolId/join-requests/reject', async (req, res) => {
  try {
    const { poolId } = req.params;
    const { userId } = req.body;
    const approverId = req.user.uid;

    // Authorization check
    const caller = await requireAdminOrOwner(poolId, approverId);
    if (!caller) {
      return res.status(403).json({ error: 'Only pool admins or owners can reject join requests' });
    }

    const joinRequest = await JoinRequest.findOne({ poolId, userId, status: 'pending' });
    if (!joinRequest) return res.status(404).json({ error: 'Pending join request not found' });

    joinRequest.status = 'rejected';
    joinRequest.reviewedAt = new Date();
    joinRequest.reviewedBy = approverId;
    await joinRequest.save();

    res.json({ message: 'Join request rejected successfully' });
  } catch (error) {
    console.error('Error rejecting join request:', error);
    res.status(500).json({ error: 'Failed to reject join request' });
  }
});

// 9b. Custom (Offline) Members
app.post('/api/pools/:poolId/members/custom', async (req, res) => {
  const { poolId } = req.params;
  const adminUid = req.user.uid;

  let session = null;
  try {
    session = await mongoose.startSession();
    session.startTransaction();

    const callerMember = await requireAdminOrOwner(poolId, adminUid, session);
    if (!callerMember) {
      await session.abortTransaction();
      session.endSession();
      return res.status(403).json({ error: 'Only pool owners or admins can add custom members' });
    }

    const { name } = req.body;
    if (!name || typeof name !== 'string' || name.trim().length === 0) {
      await session.abortTransaction();
      session.endSession();
      return res.status(400).json({ error: 'Name is required' });
    }

    const pool = await Pool.findById(poolId).session(session);
    if (!pool) {
      await session.abortTransaction();
      session.endSession();
      return res.status(404).json({ error: 'Pool not found' });
    }

    const customId = `custom_${new mongoose.Types.ObjectId().toString()}`;

    const customMember = new PoolMember({
      poolId,
      userId: customId,
      name: name.trim(),
      email: '',
      avatarUrl: '',
      role: 'member',
      isCustom: true,
      addedBy: adminUid,
      dueAmount: pool.expectedContribution,
      lastDueAppliedAt: new Date()
    });
    await customMember.save({ session });

    pool.memberIds.push(customId);
    pool.memberCount += 1;
    await pool.save({ session });

    await session.commitTransaction();
    session.endSession();

    res.json(customMember);
  } catch (error) {
    if (session) {
      try { await session.abortTransaction(); } catch (_) {}
      try { session.endSession(); } catch (_) {}
    }
    console.error('Error creating custom member:', error);
    res.status(500).json({ error: 'Failed to create custom member' });
  }
});

app.post('/api/pools/:poolId/members/:userId/role', async (req, res) => {
  try {
    const { poolId, userId } = req.params;
    const { role } = req.body;
    const adminUid = req.user.uid;

    if (!['admin', 'member'].includes(role)) {
      return res.status(400).json({ error: 'Invalid role' });
    }

    const callerMember = await PoolMember.findOne({ poolId, userId: adminUid });
    if (!callerMember || callerMember.role !== 'owner') {
      return res.status(403).json({ error: 'Only owner can change roles' });
    }

    const targetMember = await PoolMember.findOne({ poolId, userId });
    if (!targetMember) {
      return res.status(404).json({ error: 'Member not found' });
    }

    if (targetMember.isCustom) {
      return res.status(400).json({ error: 'Cannot change role of offline members' });
    }

    if (targetMember.role === 'owner') {
      return res.status(400).json({ error: 'Cannot change role of owner' });
    }

    targetMember.role = role;
    await targetMember.save();

    res.json(targetMember);
  } catch (error) {
    console.error('Error changing member role:', error);
    res.status(500).json({ error: 'Failed to change member role' });
  }
});

// 10. Ledger, Contributions & Expenses Routes

// Authorization: Only pool members can view ledger
app.get('/api/pools/:poolId/ledger', async (req, res) => {
  try {
    const pool = await requireMembership(req.params.poolId, req.user.uid);
    if (!pool) {
      return res.status(403).json({ error: 'You are not a member of this pool' });
    }
    const ledger = await LedgerEntry.find({ poolId: req.params.poolId }).sort({ timestamp: -1 });
    res.json(ledger);
  } catch (error) {
    console.error('Error fetching ledger:', error);
    res.status(500).json({ error: 'Failed to fetch ledger' });
  }
});

app.post('/api/ledger/pay-due', async (req, res) => {
  const session = await mongoose.startSession();
  try {
    session.startTransaction();
    const { poolId, amount } = req.body;
    const userId = req.user.uid;

    if (!poolId || typeof poolId !== 'string') {
      await session.abortTransaction(); session.endSession();
      return res.status(400).json({ error: 'Pool ID is required' });
    }

    const member = await PoolMember.findOne({ poolId, userId }).session(session);
    if (!member) {
      await session.abortTransaction();
      session.endSession();
      return res.status(404).json({ error: 'Member not found in pool' });
    }

    const requestedAmount = parseFloat(amount);
    if (isNaN(requestedAmount) || requestedAmount <= 0) {
      await session.abortTransaction();
      session.endSession();
      return res.status(400).json({ error: 'Invalid payment amount' });
    }

    // Cap payment to actual due amount to prevent pendingAmount going negative
    const currentDue = member.dueAmount || 0;
    const payAmount = Math.min(requestedAmount, currentDue);

    if (payAmount <= 0) {
      await session.abortTransaction();
      session.endSession();
      return res.status(400).json({ error: 'No outstanding dues to pay' });
    }

    member.dueAmount = Math.max(0, currentDue - payAmount);
    await member.save({ session });

    const ledger = new LedgerEntry({
      poolId,
      type: 'due_paid',
      amount: payAmount,
      createdBy: userId,
      description: `Paid towards due`
    });
    await ledger.save({ session });

    // Verify pool exists before updating
    const pool = await Pool.findById(poolId).session(session);
    if (!pool) {
      await session.abortTransaction();
      session.endSession();
      return res.status(404).json({ error: 'Pool not found' });
    }

    pool.totalCollected += payAmount;
    pool.currentBalance += payAmount;
    pool.pendingAmount = Math.max(0, (pool.pendingAmount || 0) - payAmount);
    await pool.save({ session });

    await session.commitTransaction();
    session.endSession();

    res.json({ message: 'Due payment recorded successfully', newDueAmount: member.dueAmount });
  } catch (error) {
    await session.abortTransaction();
    session.endSession();
    console.error('Error recording due payment:', error);
    res.status(500).json({ error: 'Failed to record due payment' });
  }
});

app.post('/api/ledger/expense', async (req, res) => {
  const session = await mongoose.startSession();
  try {
    session.startTransaction();
    const { poolId, title, amount, category, note, receiptUrl, date } = req.body;
    const userId = req.user.uid;

    const callerMember = await requireAdminOrOwner(poolId, userId, session);
    if (!callerMember) {
      await session.abortTransaction();
      session.endSession();
      return res.status(403).json({ error: 'Only admins can log expenses' });
    }

    const expenseAmount = parseFloat(amount);
    if (isNaN(expenseAmount) || expenseAmount <= 0) {
      await session.abortTransaction();
      session.endSession();
      return res.status(400).json({ error: 'Invalid expense amount' });
    }

    if (!title || typeof title !== 'string' || title.trim().length === 0) {
      await session.abortTransaction();
      session.endSession();
      return res.status(400).json({ error: 'Expense title is required' });
    }

    // Verify pool exists BEFORE saving expense
    const pool = await Pool.findById(poolId).session(session);
    if (!pool) {
      await session.abortTransaction();
      session.endSession();
      return res.status(404).json({ error: 'Pool not found' });
    }

    const expense = new Expense({
      poolId,
      title: title.trim(),
      amount: expenseAmount,
      category,
      note,
      receiptUrl,
      createdBy: userId,
      createdAt: date ? new Date(date) : new Date()
    });
    await expense.save({ session });

    const ledger = new LedgerEntry({
      poolId,
      type: 'expense_added',
      amount: expenseAmount, // Store absolute amount; UI handles the negative display
      createdBy: userId,
      description: title.trim(),
      relatedExpenseId: expense._id,
      timestamp: expense.createdAt
    });
    await ledger.save({ session });

    pool.currentBalance -= expenseAmount;
    pool.totalSpent += expenseAmount;
    await pool.save({ session });

    await session.commitTransaction();
    session.endSession();

    res.json({ message: 'Expense logged successfully' });
  } catch (error) {
    await session.abortTransaction();
    session.endSession();
    console.error('Error logging expense:', error);
    res.status(500).json({ error: 'Failed to log expense' });
  }
});

app.post('/api/pools/:poolId/log-collection', async (req, res) => {
  const session = await mongoose.startSession();
  try {
    session.startTransaction();
    const { poolId } = req.params;
    const { date, paymentMethod, note, collections } = req.body;
    const userId = req.user.uid;

    const callerMember = await requireAdminOrOwner(poolId, userId, session);
    if (!callerMember) {
      await session.abortTransaction();
      session.endSession();
      return res.status(403).json({ error: 'Only admins can log collections' });
    }

    if (!Array.isArray(collections) || collections.length === 0) {
      await session.abortTransaction();
      session.endSession();
      return res.status(400).json({ error: 'No collections provided' });
    }

    let totalCollectedAmount = 0;
    const timestamp = date ? new Date(date) : new Date();

    for (const item of collections) {
      const { userId: memberUserId, amount } = item;
      const collectAmount = parseFloat(amount);
      
      if (isNaN(collectAmount) || collectAmount <= 0) {
        continue;
      }

      const member = await PoolMember.findOne({ poolId, userId: memberUserId }).session(session);
      if (member) {
        // Only count amount towards totals when member is valid
        totalCollectedAmount += collectAmount;

        member.dueAmount = Math.max(0, member.dueAmount - collectAmount);
        await member.save({ session });

        const entry = new LedgerEntry({
          poolId,
          type: 'payment_marked_offline',
          amount: collectAmount,
          description: `Offline payment via ${paymentMethod || 'Cash'}${note ? ` - ${note}` : ''}`,
          createdBy: memberUserId,
          timestamp,
        });
        await entry.save({ session });
      }
      // Invalid members are silently skipped — totalCollectedAmount is NOT inflated
    }

    if (totalCollectedAmount > 0) {
      const pool = await Pool.findById(poolId).session(session);
      if (pool) {
        pool.currentBalance += totalCollectedAmount;
        pool.totalCollected += totalCollectedAmount;
        await pool.save({ session });
      }
    }

    await session.commitTransaction();
    session.endSession();

    res.json({ message: 'Collection logged successfully', totalCollectedAmount });
  } catch (error) {
    await session.abortTransaction();
    session.endSession();
    console.error('Error logging collection:', error);
    res.status(500).json({ error: 'Failed to log collection' });
  }
});

// 11. Activity Feed — cross-pool ledger entries for the current user
app.get('/api/activity', async (req, res) => {
  try {
    const userId = req.user.uid;
    const pools = await Pool.find({ memberIds: userId });
    const poolIds = pools.map(p => p._id);

    const entries = await LedgerEntry.find({ poolId: { $in: poolIds } })
      .sort({ timestamp: -1 })
      .limit(50);

    // Enrich entries with pool name and creator name
    const poolMap = {};
    pools.forEach(p => { poolMap[p._id.toString()] = p.name; });

    // Get unique creator IDs to resolve names
    const creatorIds = [...new Set(entries.map(e => e.createdBy))];
    const members = await PoolMember.find({ userId: { $in: creatorIds } });
    const users = await User.find({ uid: { $in: creatorIds } });

    const nameMap = {};
    users.forEach(u => { nameMap[u.uid] = u.name; });
    members.forEach(m => { if (!nameMap[m.userId]) nameMap[m.userId] = m.name; });

    const enrichedEntries = entries.map(e => {
      const obj = e.toJSON();
      obj.poolName = poolMap[e.poolId.toString()] || 'Unknown Pool';
      obj.createdByName = nameMap[e.createdBy] || e.createdBy;
      return obj;
    });

    res.json(enrichedEntries);
  } catch (error) {
    console.error('Error fetching activity:', error);
    res.status(500).json({ error: 'Failed to fetch activity feed' });
  }
});


// --- PAYMENT REQUESTS ---

app.post('/api/pools/:poolId/payment-requests', async (req, res) => {
  try {
    const { amount, screenshotUrl } = req.body;
    const poolId = req.params.poolId;
    const userId = req.user.uid;

    // Input validation
    const parsedAmount = parseFloat(amount);
    if (isNaN(parsedAmount) || parsedAmount <= 0) {
      return res.status(400).json({ error: 'Payment amount must be a positive number' });
    }
    if (!screenshotUrl || typeof screenshotUrl !== 'string') {
      return res.status(400).json({ error: 'Screenshot URL is required' });
    }

    const callerMember = await PoolMember.findOne({ poolId, userId });
    if (!callerMember) {
      return res.status(403).json({ error: 'Not a member of this pool' });
    }

    const pr = new PaymentRequest({
      poolId,
      userId,
      name: callerMember.name,
      amount: parsedAmount,
      screenshotUrl,
      status: 'PENDING'
    });
    await pr.save();
    
    res.json(pr);
  } catch (err) {
    console.error('Error creating payment request:', err);
    res.status(500).json({ error: 'Failed to create payment request' });
  }
});

app.get('/api/pools/:poolId/payment-requests', async (req, res) => {
  try {
    const poolId = req.params.poolId;
    const userId = req.user.uid;
    const callerMember = await PoolMember.findOne({ poolId, userId });
    
    if (!callerMember) {
      return res.status(403).json({ error: 'Not a member of this pool' });
    }
    
    if (callerMember.role === 'owner' || callerMember.role === 'admin') {
      const requests = await PaymentRequest.find({ poolId, status: 'PENDING' }).sort({ submittedAt: -1 });
      res.json(requests);
    } else {
      const requests = await PaymentRequest.find({ poolId, userId, status: 'PENDING' }).sort({ submittedAt: -1 });
      res.json(requests);
    }
  } catch (err) {
    console.error('Error fetching payment requests:', err);
    res.status(500).json({ error: 'Failed to fetch payment requests' });
  }
});

// FIXED: Now uses a transaction + cross-pool validation
app.post('/api/pools/:poolId/payment-requests/:requestId/approve', async (req, res) => {
  const session = await mongoose.startSession();
  try {
    session.startTransaction();
    const poolId = req.params.poolId;
    const requestId = req.params.requestId;
    
    const callerMember = await requireAdminOrOwner(poolId, req.user.uid, session);
    if (!callerMember) {
      await session.abortTransaction(); session.endSession();
      return res.status(403).json({ error: 'Only admins can approve payments' });
    }

    const pr = await PaymentRequest.findById(requestId).session(session);
    if (!pr || pr.status !== 'PENDING') {
      await session.abortTransaction(); session.endSession();
      return res.status(404).json({ error: 'Request not found or already processed' });
    }

    // Cross-pool validation: ensure the payment request belongs to this pool
    if (pr.poolId.toString() !== poolId) {
      await session.abortTransaction(); session.endSession();
      return res.status(403).json({ error: 'Payment request does not belong to this pool' });
    }

    pr.status = 'APPROVED';
    pr.reviewedAt = new Date();
    pr.reviewedBy = req.user.uid;
    await pr.save({ session });

    // Decrement user due
    const member = await PoolMember.findOne({ poolId, userId: pr.userId }).session(session);
    if (member) {
      member.dueAmount = Math.max(0, member.dueAmount - pr.amount);
      await member.save({ session });
    }

    // Add ledger entry
    const entry = new LedgerEntry({
      poolId,
      type: 'payment',
      amount: pr.amount,
      description: `Payment verified from ${pr.name}`,
      createdBy: pr.userId,
    });
    await entry.save({ session });

    // Update pool balances
    const pool = await Pool.findById(poolId).session(session);
    if (pool) {
      pool.currentBalance += pr.amount;
      pool.totalCollected += pr.amount;
      await pool.save({ session });
    }

    await session.commitTransaction();
    session.endSession();

    res.json({ success: true });
  } catch (err) {
    await session.abortTransaction();
    session.endSession();
    console.error('Error approving payment request:', err);
    res.status(500).json({ error: 'Failed to approve payment request' });
  }
});

app.post('/api/pools/:poolId/payment-requests/:requestId/reject', async (req, res) => {
  try {
    const poolId = req.params.poolId;
    const requestId = req.params.requestId;
    
    const callerMember = await requireAdminOrOwner(poolId, req.user.uid);
    if (!callerMember) {
      return res.status(403).json({ error: 'Only admins can reject payments' });
    }

    const pr = await PaymentRequest.findById(requestId);
    if (!pr || pr.status !== 'PENDING') {
      return res.status(404).json({ error: 'Request not found or already processed' });
    }

    // Cross-pool validation
    if (pr.poolId.toString() !== poolId) {
      return res.status(403).json({ error: 'Payment request does not belong to this pool' });
    }

    pr.status = 'REJECTED';
    pr.reviewedAt = new Date();
    pr.reviewedBy = req.user.uid;
    await pr.save();

    res.json({ success: true });
  } catch (err) {
    console.error('Error rejecting payment request:', err);
    res.status(500).json({ error: 'Failed to reject payment request' });
  }
});

// --- END PAYMENT REQUESTS ---

// 12. Start server
const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`GridPool backend running on port ${PORT}`);
});
