# QuickHireSL

## Smart Job Matching Platform

QuickHireSL is a comprehensive job matching platform designed to connect job seekers and employers in Sri Lanka. The platform features user authentication, job posting, application tracking, and a community forum.

## Key Features

- **Smart Job Matching Algorithm**: Matches job seekers with jobs based on location (35%), job category (35%), and availability (30%)
- **Role-Based User Experience**: Tailored interfaces for students (job seekers) and job owners (employers)
- **Profile Management**: Complete profile creation and editing with profile image upload functionality
- **Job Management**: Post, search, filter, and apply for jobs with real-time updates
- **Application Tracking**: Track job applications with status updates and feedback
- **Community Forum**: Engage with other users through posts and comments
- **Feedback System**: Rate and review job experiences
- **Responsive Design**: Works on multiple device sizes and platforms

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
   node app.js
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

## Architecture and Technical Details

### Frontend (Flutter)

- **State Management**: Provider pattern for efficient state management
- **API Integration**: RESTful API integration with HTTP package
- **UI Components**: Custom widgets for consistent UI/UX
- **Image Handling**: Profile image loading with caching and error handling
- **Pull-to-Refresh**: Implemented across job listings for real-time updates

### Backend (Express.js)

- **API Endpoints**: RESTful API endpoints for all application features
- **Authentication**: JWT-based authentication system
- **Database**: MongoDB for flexible document storage
- **File Upload**: Multipart request handling for profile images
- **Error Handling**: Consistent error response format

## MongoDB Integration

The application uses MongoDB for data storage with the following implementations:

- **Job Applications**:
  - Structured schema with fields for applicant details, job reference, and status tracking
  - Validation for required fields like fullName, contact information, and job ID
  - MongoDB transactions for critical operations like submitting applications
  - Express.js endpoints for application submission, retrieval, and status management
  - Consistent error handling with appropriate HTTP status codes

- **User Profiles**:
  - Role-specific information storage (student vs. job owner details)
  - Profile image storage and retrieval
  - Authentication data with secure password storage

- **Job Listings**:
  - Standardized job categories for improved matching
  - Location information using standardized locations
  - Availability dates with support for time slots and full-day availability
  - Job matching algorithm data

- **Feedback System**:
  - User feedback with proper attribution (fixed from "Anonymous User" display)
  - Application-specific feedback
  - API endpoints for retrieving feedback by user ID and application ID

## Recent Enhancements

- **Profile Image System**: Enhanced profile image loading with caching and fallbacks
- **Job Matching Algorithm**: Optimized to focus on location (35%), job category (35%), and availability (30%)
- **Standardized Job Categories**: Improved matching between job postings and user preferences
- **Availability Date Matching**: Support for date and time slot matching
- **User Interface Improvements**: Streamlined registration process and profile management
- **Pull-to-Refresh**: Added to improve user experience when viewing job listings
- **Role-Based UI Controls**: Tailored interface elements based on user role

## Deployment

### Backend Deployment

The Express.js backend is deployed on Azure App Service at:
- https://quickhiresl2-d8e9g7h6b0c5emgx.southeastasia-01.azurewebsites.net/

### MongoDB Hosting

We are using MongoDB Atlas for database hosting, which provides:
- 512MB storage (sufficient for testing)
- Public access with proper security controls
- Connection string that works from anywhere

## Testing

The application includes:

- **Performance Testing**: Using Autocannon for API endpoint testing
- **Database Performance Testing**: For both read and write operations
- **Usability Testing**: For evaluating user interaction effectiveness

## License

[MIT License](LICENSE)
