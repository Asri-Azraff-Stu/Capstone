# ProjectFlow

ProjectFlow is a full-stack project management application designed to track tasks, manage workflows, and collaborate on software development projects. It features a responsive web frontend, a secure RESTful API backend, and a cross-platform mobile application.

This project was built to demonstrate proficiency in full-stack development, API design, and information security best practices.

## Architecture

The application follows a standard **Client-Server Architecture**:
- **Frontend (Web):** A responsive Single Page Application (SPA) utilizing vanilla HTML, CSS, and JavaScript with Tailwind CSS for rapid styling. The web client communicates with the backend via a REST API using the `fetch` API.
- **Frontend (Mobile):** A cross-platform mobile application built with **Flutter**, using the `provider` package for state management and `http` for API requests.
- **Backend (API):** A **Node.js** server utilizing the **Express.js** framework. It exposes RESTful endpoints for user authentication and CRUD operations.
- **Database:** A relational database (**MySQL/MariaDB**) serving as the single source of truth, interacted with via the `mysql2/promise` library.

## Tech Stack

- **Frontend:** HTML5, CSS3, JavaScript (ES6+), Tailwind CSS
- **Backend:** Node.js, Express.js
- **Mobile:** Flutter (Dart)
- **Database:** MySQL
- **Security & Auth:** JSON Web Tokens (`jsonwebtoken`), bcrypt (`bcryptjs`), CORS

## Security Features

As a project designed with security in mind, ProjectFlow implements the following safeguards:
1. **Password Hashing:** Passwords are never stored in plaintext. `bcryptjs` is used with a salt factor of 10 to securely hash passwords before they hit the database.
2. **Stateless Authentication:** User sessions are managed via JSON Web Tokens (JWT). The tokens are signed with a highly secure, server-side secret.
3. **Environment Variable Enforcement:** The application strictly enforces the use of environment variables for sensitive configurations (such as `JWT_SECRET` and database credentials). The server will refuse to start (`process.exit(1)`) if a JWT secret is not explicitly provided in the environment, preventing accidental fallback to easily guessable keys.
4. **CORS Configuration:** Cross-Origin Resource Sharing is configured to restrict unauthorized domains from accessing the API endpoints.

## Running Locally

### Prerequisites
- Node.js (v14 or higher)
- MySQL Server (e.g., XAMPP, MAMP, or standalone MySQL)
- Flutter SDK (for running the mobile app)

### Database Setup
1. Start your MySQL server.
2. Create a new database named `projectflow_db`.
3. Import the provided `projectflow_db.sql` file to set up the schema and seed data.

### Backend Setup
1. Navigate to the root directory.
2. Install dependencies:
   ```bash
   npm install
   ```
3. Copy the example environment file and configure it:
   ```bash
   cp .env.example .env
   ```
4. Open `.env` and fill in your database credentials and a strong `JWT_SECRET`.
5. Start the server:
   ```bash
   npm start
   ```

### Web Frontend
The web frontend consists of static files (`index.html`, `login.html`, `scripts.js`, etc.). You can open `login.html` directly in your browser or serve it using any static file server (like Live Server in VS Code).

Note: For the frontend to successfully hit the backend, ensure your backend server is running on the port configured in `scripts.js` (default: 3000).*

### Mobile App
1. Navigate to the mobile app directory:
   ```bash
   cd projectflow_mobile
   ```
2. Install Flutter dependencies:
   ```bash
   flutter pub get
   ```
3. Run the app on your preferred emulator or connected device:
   ```bash
   flutter run --dart-define=API_URL=http://10.0.2.2:3000/api
   ```
