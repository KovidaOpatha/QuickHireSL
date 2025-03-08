class Config {
  // For physical device testing, use your computer's IP address
  // For emulator testing, you can use 10.0.2.2 which points to your computer's localhost
  // Comment/uncomment the appropriate line based on your testing environment
  
  // For physical device (using your computer's WiFi IP)
  static const String apiUrl = 'http://192.168.1.16:3000/api';
  
  // For emulator testing
  // static const String apiUrl = 'http://10.0.2.2:3000/api';
  
  // For local development on the same machine
  // static const String apiUrl = 'http://localhost:3000/api';
}
