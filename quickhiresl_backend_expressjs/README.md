# QuickHireSL Backend API

This is the backend API for the QuickHireSL application, a platform connecting job seekers and employers in Sri Lanka.

## Deployment Information

### Azure Deployment

The API is deployed on Azure App Service at:
- https://quickhiresl2-d8e9g7h6b0c5emgx.southeastasia-01.azurewebsites.net/

### API Health Check

You can verify the API is running by accessing:
- https://quickhiresl2-d8e9g7h6b0c5emgx.southeastasia-01.azurewebsites.net/api/health

### API Version

Get the current API version:
- https://quickhiresl2-d8e9g7h6b0c5emgx.southeastasia-01.azurewebsites.net/api/version

## Environment Configuration

The application requires the following environment variables:

```
PORT=3000
MONGODB_URI=mongodb+srv://<username>:<password>@<cluster>.<id>.mongodb.net/<database>
JWT_SECRET=<your_jwt_secret>
NODE_ENV=production
API_URL=https://quickhiresl2-d8e9g7h6b0c5emgx.southeastasia-01.azurewebsites.net
```

## API Documentation

### Authentication Endpoints

- `POST /api/auth/register` - Register a new user
- `POST /api/auth/login` - Login a user
- `GET /api/auth/verify` - Verify JWT token

### User Endpoints

- `GET /api/users/:userId` - Get user profile
- `PUT /api/users/:userId` - Update user profile
- `GET /api/users/:userId/job-preferences` - Get user job preferences
- `PUT /api/users/:userId/job-preferences` - Update user job preferences

### Job Endpoints

- `GET /api/jobs` - Get all jobs
- `GET /api/jobs/:jobId` - Get job details
- `POST /api/jobs` - Create a new job
- `PUT /api/jobs/:jobId` - Update a job
- `DELETE /api/jobs/:jobId` - Delete a job

### Application Endpoints

- `GET /api/applications` - Get all applications
- `GET /api/applications/:applicationId` - Get application details
- `POST /api/applications` - Create a new application
- `PUT /api/applications/:applicationId` - Update an application
- `DELETE /api/applications/:applicationId` - Delete an application

### Feedback Endpoints

- `GET /api/feedback/user/:userId` - Get feedback for a user
- `GET /api/feedback/application/:applicationId` - Get feedback for an application
- `POST /api/feedback` - Create new feedback

### Chat Endpoints

- `GET /api/jobs/:jobId/chat` - Get chat for a job
- `POST /api/jobs/:jobId/chat` - Add message to job chat

## Development

To run the application locally:

```bash
npm install
npm run dev
```

## Deployment

The application is deployed using GitHub Actions. See `.github/workflows/deployment2_quickhiresl2.yml` for details.
