import 'dart:convert';
import 'package:flutter/material.dart';
import '../config/config.dart';

class ProfileImageUtil {
  /// Gets a properly formatted image URL from a profile image path
  static String getFullImageUrl(String? imagePath) {
    if (imagePath == null || imagePath.isEmpty) return '';
    
    // If it's already a full URL (Cloudinary or data URL), return it as is
    if (imagePath.startsWith('http') || imagePath.startsWith('https') || imagePath.startsWith('data:')) {
      return imagePath;
    }
    
    // Remove any leading slashes and add the correct base URL
    final cleanPath = imagePath.startsWith('/') ? imagePath.substring(1) : imagePath;
    
    // Extract the base server URL without the /api path
    final serverUrl = Config.apiUrl.replaceAll('/api', '');
    
    // If the path already contains 'uploads', don't add it again
    if (cleanPath.startsWith('uploads/')) {
      return '$serverUrl/$cleanPath';
    } else {
      return '$serverUrl/uploads/$cleanPath';
    }
  }

  /// Creates an ImageProvider from a profile image URL
  static ImageProvider? getProfileImageProvider(String? imageUrl) {
    if (imageUrl == null || imageUrl.isEmpty) {
      return null;
    }
    
    // Format the URL properly
    final formattedUrl = getFullImageUrl(imageUrl);
    
    // Handle data URLs (base64 encoded images)
    if (formattedUrl.startsWith('data:image')) {
      try {
        final base64String = formattedUrl.split(',').last;
        return MemoryImage(base64Decode(base64String));
      } catch (e) {
        print('Error decoding base64 image: $e');
        return null;
      }
    }
    
    // Handle network images
    return NetworkImage(formattedUrl);
  }
  
  /// Widget for displaying profile image with proper error handling
  static Widget buildProfileImage({
    required String? imageUrl,
    double radius = 40,
    double? width,
    double? height,
  }) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: Colors.grey[300],
      backgroundImage: imageUrl != null && imageUrl.isNotEmpty
          ? getProfileImageProvider(imageUrl)
          : null,
      child: imageUrl == null || imageUrl.isEmpty
          ? Icon(
              Icons.person,
              size: radius,
              color: Colors.grey[600],
            )
          : null,
    );
  }
}
