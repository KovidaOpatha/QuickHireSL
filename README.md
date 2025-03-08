# QuickHireSL

## Smart Job Matching Platform

QuickHireSL is a comprehensive job matching platform designed to connect job seekers and employers in Sri Lanka. The platform features user authentication, job posting, application tracking, and a community forum.

## Project Structure

This repository contains both the frontend and backend components of the QuickHireSL platform:

- **quickhiresl_frontend**: Flutter mobile application
- **quickhiresl_backend_expressjs**: Express.js backend API server with MongoDB integration

## Setup Instructions

### Backend Setup

1. **Navigate to the backend directory**:
   ```bash
   cd quickhiresl_backend_expressjs
   ```

2. **Install dependencies**:
   ```bash
   npm install
   ```

3. **Configure environment variables**:
   - Copy the example environment file: `cp .env.example .env`
   - Edit the `.env` file with your MongoDB connection string and other settings

4. **Start the development server**:
   ```bash
   npm run dev
   ```
   The server will start on the port specified in your .env file (default: 3000)

### Frontend Setup

1. **Navigate to the frontend directory**:
   ```bash
   cd quickhiresl_frontend
   ```

2. **Install Flutter dependencies**:
   ```bash
   flutter pub get
   ```

3. **Configure API connection**:
   - Open `lib/config/config.dart`
   - Update the API URL based on your environment:
     - For physical device testing: Use your computer's IP address
     - For emulator: Use `10.0.2.2` (Android) or `localhost` (iOS)
     - For production: Use your hosted backend URL

4. **Run the application**:
   ```bash
   flutter run
   ```

## MongoDB Integration

The application uses MongoDB to store:
- User profiles and authentication data
- Job listings and details
- Job applications and their status
- Community forum posts and comments

The database schema includes proper validation and indexing for efficient queries, particularly for job searches and application tracking.

## Deployment

### Backend Deployment Options

The Express.js backend can be deployed to various platforms:

1. **Render**: Free tier available, easy deployment from GitHub
2. **Railway**: Generous free tier with $5 monthly credits
3. **Fly.io**: Free tier with 3 small VMs
4. **Heroku**: Paid options with good scaling capabilities

### MongoDB Hosting

We recommend using MongoDB Atlas (free tier available) for database hosting, which provides:
- 512MB storage (sufficient for testing)
- Public access with proper security controls
- Connection string that works from anywhere

## Contributing

To contribute to this project:

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request

## License

[MIT License](LICENSE)
