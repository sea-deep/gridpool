# GridPool

GridPool is a robust, full-stack financial pool management application. It allows users to create pools, invite members, log expenses, collect dues, and manage offline/online payments with an integrated ledger and activity feed.

## Tech Stack
- **Backend**: Node.js, Express, MongoDB (Mongoose)
- **Frontend**: Flutter, Riverpod (State Management), GoRouter (Navigation)
- **Authentication**: Firebase Auth (Google Sign-In)
- **Storage**: Cloudinary (Receipt/Screenshot uploads)

## Security Features
- **Idempotent Financial Operations**: MongoDB `$set` atomic operations instead of `$inc` to prevent race conditions during concurrent requests.
- **Strict Role-Based Access Control (RBAC)**: Enforced `owner`, `admin`, and `member` roles for sensitive ledger actions.
- **Input Validation & Sanitization**: Comprehensive input bounds checking and error masking to prevent information disclosure.
- **Rate Limiting & Helmet**: DDoS prevention and strict HTTP headers via Express middleware.

## Getting Started

### Backend
1. Navigate to the backend directory:
   ```bash
   cd backend
   ```
2. Install dependencies:
   ```bash
   npm install
   ```
3. Set up the environment variables:
   Copy `.env.example` to `.env` and fill in your MongoDB URI, Cloudinary keys, and Firebase service account key.
4. Run the development server:
   ```bash
   npm run dev
   ```

### Frontend
1. Navigate to the frontend directory:
   ```bash
   cd frontend
   ```
2. Get Flutter dependencies:
   ```bash
   flutter pub get
   ```
3. Create an `.env` file in `frontend/assets/` containing your backend URL (e.g., `API_BASE_URL=http://10.0.2.2:3000/api`).
4. Run the app:
   ```bash
   flutter run
   ```

## License
MIT
