class Config {
  // =====================================================================
  // IMPORTANT: CONFIGURATION SETUP
  // =====================================================================
  // Choose the appropriate API URL configuration based on your environment:
  // 1. For physical device testing: Use your computer's IP address
  // 2. For emulator testing: Use 10.0.2.2 (points to your computer's localhost)
  // 3. For local development: Use localhost
  // 4. For production: Use your deployed backend URL
  //
  // INSTRUCTIONS FOR NEW DEVELOPERS:
  // - Uncomment the appropriate line below based on your testing environment
  // - For physical device testing, replace 192.168.1.16 with your computer's IP
  // - If using a hosted backend, replace the entire URL with your backend URL
  // =====================================================================
  
  // CHOOSE ONE OF THESE OPTIONS:
  
  // Option 1: For physical device testing (replace with your computer's IP)
  static const String apiUrl = 'http://192.168.1.16:3000/api';
  
  // Option 2: For Android emulator testing
  // static const String apiUrl = 'http://10.0.2.2:3000/api';
  
  // Option 3: For local development on the same machine
  // static const String apiUrl = 'http://localhost:3000/api';
  
  // Option 4: For production with hosted backend
  // static const String apiUrl = 'https://your-backend-url.com/api';
}
