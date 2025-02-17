import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

Future<dynamic> makeAuthenticatedRequest() async {
  const storage = FlutterSecureStorage();
  final token = await storage.read(key: 'jwt_token');
  final response = await http.get(
    Uri.parse('your-api-endpoint'),
    headers: {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json'
    },
  );
  return jsonDecode(response.body);
}
