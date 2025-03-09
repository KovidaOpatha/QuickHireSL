class ApiConfig {
  static const String baseUrl = 'https://quickhiresl-ang6d9bzaqfyf6fc.canadacentral-01.azurewebsites.net';
  
  // Auth endpoints
  static const String login = '$baseUrl/api/auth/login';
  static const String register = '$baseUrl/api/auth/register';
  static const String forgotPassword = '$baseUrl/api/auth/forgot-password';
  static const String resetPassword = '$baseUrl/api/auth/reset-password';
  
  // User endpoints
  static const String users = '$baseUrl/api/users';
  static const String updateRole = '$baseUrl/api/users/role';
  static const String getUserProfile = '$baseUrl/api/users/profile';
  static const String verifyUserData = '$baseUrl/api/users/verify';
  
  // Job endpoints
  static const String jobs = '$baseUrl/api/jobs';
  static const String searchJobs = '$baseUrl/api/jobs/search';
  static const String jobCategories = '$baseUrl/api/jobs/categories';
  
  // Application endpoints
  static const String applications = '$baseUrl/api/applications';
  static const String applicationStatus = '$baseUrl/api/applications/status';
  
  // Notification endpoints
  static const String notifications = '$baseUrl/api/notifications';
  
  // Helper method for getting base API URL
  static String getApiUrl() {
    return '$baseUrl/api';
  }
}