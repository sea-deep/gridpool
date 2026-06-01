const mongoose = require('mongoose');
require('dotenv').config();

const MONGODB_URI = process.env.MONGODB_URI || 'mongodb://127.0.0.1:27017/gridpool';

const poolSchema = new mongoose.Schema({
  totalCollected: { type: Number, default: 0.0 },
  currentBalance: { type: Number, default: 0.0 },
}, { strict: false });
const Pool = mongoose.model('Pool', poolSchema);

const ledgerEntrySchema = new mongoose.Schema({
  poolId: { type: mongoose.Schema.Types.ObjectId, ref: 'Pool', required: true },
  amount: { type: Number, required: true },
  type: { type: String, required: true }
});
const LedgerEntry = mongoose.model('LedgerEntry', ledgerEntrySchema);

async function fixBalances() {
  await mongoose.connect(MONGODB_URI);
  console.log('Connected to MongoDB');

  const pools = await Pool.find({});
  for (const pool of pools) {
    const entries = await LedgerEntry.find({ poolId: pool._id });
    
    let totalCollected = 0;
    
    for (const entry of entries) {
      if (['payment', 'due_paid', 'contributionPaid', 'paymentMarkedOffline'].includes(entry.type) || (entry.type === 'manualAdjustment' && entry.amount > 0)) {
        totalCollected += entry.amount;
      }
    }
    
    pool.totalCollected = totalCollected;
    pool.currentBalance = totalCollected; // Simplified, assuming no expenses yet
    
    await pool.save();
    console.log(`Updated pool ${pool._id} - totalCollected: ${totalCollected}`);
  }
  
  await mongoose.disconnect();
  console.log('Done');
}

fixBalances().catch(console.error);
