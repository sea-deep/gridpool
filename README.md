# GridPool — Collaborative Financial Ledger & Pool Manager

GridPool is a secure, full-stack, collaborative financial pool management application. It serves as a transparent digital ledger for co-living spaces, apartment flats, PG circles, clubs, college groups, and community projects. Groups can pool money, automatically track dynamic periodic dues, record and split shared expenses, log cash collections, and verify online payments with screenshot proof uploads.

---

## Key Features & Business Logic

### 1. Manual UPI Payment Flow with Verification
Unlike automated/unverified transaction triggers, GridPool uses a secure manual proof-of-payment workflow:
* **Dynamic QR Generation**: The mobile app constructs and displays a standard UPI payment QR code (`upi://pay?pa=...`) based on the pool's UPI ID, member balance due, and pre-filled payee/note details.
* **Clipboard copy**: Provides a convenient copy button to copy the pool's target UPI ID.
* **Manual Transfer**: Users switch to their preferred external UPI client (GPay, PhonePe, Paytm, BHIM, etc.) to complete the transaction.
* **Screenshot Verification**: Users capture and upload a transaction receipt screenshot (stored on Cloudinary). An administrator (owner/admin) reviews the screenshot and approves it, which then updates pool balances, reduces member dues, and records a verified ledger entry.

### 2. Dynamic Lazy Dues Engine
* Member dues are evaluated and updated on-the-fly when fetching member lists, eliminating database processing overhead.
* Dues accumulate periods passed since `lastDueAppliedAt` (or `joinedAt`) based on the pool's contribution schedule (`weekly`, `monthly`, `quarterly`, `yearly`, or `custom` interval days).
* **Idempotency**: Dues are applied using absolute Mongo `$set` operations in a bulk write context rather than relative `$inc` modifiers. This prevents concurrent client requests or network retries from duplicating dues.

### 3. Role-Based Access Control (RBAC) & Security
* **Owner**: Full administrative access, controls invite codes, approves/rejects join requests, alters member roles, deletes the pool (which drops associated collections in a transaction).
* **Admin**: Approves join requests, payment verifications, and records expenses or cash collections.
* **Member**: Views the pool balances, member list, and transaction timeline, and submits payment requests.
* **Custom Members**: Admins can add manual offline members (cash-only pg mates, etc.) to calculate their share of dues and record manual collection logs.
* **Security Middleware**: Authenticates endpoints via Firebase Token Verification, enforces rate limiting, limits payload sizes to 100kb, and sets safe headers via Helmet.

### 4. Immutable Ledger Timeline
* Every transaction (inflows like payments/cash logs, and outflows like expenses) is recorded as a `LedgerEntry`.
* All core financial adjustments are wrapped in Mongoose database transactions (`session.startTransaction()`) to guarantee consistency.
* Includes a balance reconciliation tool (`fix_balances.js`) that reconstructs pool balances directly from ledger history.

---

## Tech Stack

### Backend
* **Runtime**: Node.js, Express
* **Database**: MongoDB (Mongoose ODM)
* **Authentication**: Firebase Admin SDK (Token verification)
* **File Storage**: Cloudinary (for receipt/screenshot image hosting)

### Frontend
* **Framework**: Flutter (Cross-platform Android, iOS, Web, Desktop)
* **State Management**: Riverpod (dynamic stream caching and REST API polling)
* **Navigation & Routing**: GoRouter
* **UI Design System**: Material Design 3 (Material You Violet Theme, tonal surfaces, pill shapes, glassmorphism, hover scale/shadow animations).

---

## Project Structure

```
├── backend/
│   ├── middleware/        # Authentication & verifyToken logic
│   ├── index.js           # API Server routes, schemas, transactions
│   ├── fix_balances.js    # Ledger reconciliation and balance fix script
│   └── package.json       # Node dependencies
├── frontend/
│   ├── lib/
│   │   ├── models/        # Dart data models (Pool, PoolMember, LedgerEntry, etc.)
│   │   ├── providers/     # Riverpod state controllers (auth, dashboard)
│   │   ├── router/        # GoRouter navigation paths
│   │   ├── screens/       # Flutter application views
│   │   ├── services/      # API communication, UPI utilities, and uploads
│   │   ├── theme/         # Material You design tokens and colors
│   │   └── widgets/       # Styled components (AppSurface, AppButton, etc.)
│   └── pubspec.yaml       # Flutter packages & dependencies
└── docs/
    ├── design.txt         # Material Design 3 spec guidelines
    ├── idea.txt           # Project description & MVP specifications
    └── ledger_logic.txt   # Core transaction ledger maintenance logic
```

---

## Getting Started

### Prerequisites
* Node.js (v18+)
* Flutter SDK (3.10+)
* MongoDB instance (local or Atlas)
* Firebase project (with service account JSON config)
* Cloudinary account

### Backend Setup
1. Navigate to the backend directory:
   ```bash
   cd backend
   ```
2. Install dependencies:
   ```bash
   npm install
   ```
3. Set up the environment variables by creating a `.env` file matching `.env.example`:
   ```env
   PORT=3000
   MONGODB_URI=mongodb://127.0.0.1:27017/gridpool
   CLOUDINARY_CLOUD_NAME=your_cloud_name
   CLOUDINARY_API_KEY=your_api_key
   CLOUDINARY_API_SECRET=your_api_secret
   ```
4. Place your Firebase `service-account-key.json` file in the `backend/` root directory.
5. Launch the development server:
   ```bash
   npm run dev
   ```

### Frontend Setup
1. Navigate to the frontend directory:
   ```bash
   cd frontend
   ```
2. Install dependencies:
   ```bash
   flutter pub get
   ```
3. Create a `.env` file inside `frontend/assets/` pointing to your local or deployed API base url:
   ```env
   API_BASE_URL=http://10.0.2.2:3000/api
   ```
4. Run the application:
   ```bash
   flutter run
   ```

---

## Reconciliation Utility
In case of pool sync issues or balance drift, run the reconciliation script on the database server:
```bash
cd backend
node fix_balances.js
```
This utility aggregates all credits from `LedgerEntry` items and calibrates the pool's cached balances accordingly.
