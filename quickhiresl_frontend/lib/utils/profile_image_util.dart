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
  /// This method now returns a non-nullable ImageProvider
  static ImageProvider getProfileImageProvider(String? imageUrl) {
    if (imageUrl == null || imageUrl.isEmpty) {
      // Return a placeholder image provider
      return const AssetImage('assets/placeholder.png');
    }
    
    // Format the URL properly
    final formattedUrl = getFullImageUrl(imageUrl);
    
    // Add cache-busting parameter to avoid Android caching issues
    final cacheBustedUrl = "$formattedUrl?t=${DateTime.now().millisecondsSinceEpoch}";
    
    // Handle data URLs (base64 encoded images)
    if (formattedUrl.startsWith('data:image')) {
      try {
        final base64String = formattedUrl.split(',').last;
        return MemoryImage(base64Decode(base64String));
      } catch (e) {
        print('Error decoding base64 image: $e');
        return const AssetImage('assets/placeholder.png');
      }
    }
    
    // Handle network images
    return NetworkImage(cacheBustedUrl);
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

  /// Widget for displaying circular profile image with proper error handling
  static Widget circularProfileImage({
    required String? imageUrl,
    required double radius,
    required String fallbackText,
    Color? backgroundColor,
    Color? textColor,
  }) {
    final double size = radius * 2;
    
    if (imageUrl == null || imageUrl.isEmpty) {
      return CircleAvatar(
        backgroundColor: backgroundColor ?? Colors.blue,
        radius: radius,
        child: Text(
          fallbackText.isNotEmpty ? fallbackText[0].toUpperCase() : '?',
          style: TextStyle(
            color: textColor ?? Colors.white,
            fontSize: radius * 0.75,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }
    
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: backgroundColor?.withOpacity(0.2) ?? Colors.blue.withOpacity(0.2),
      ),
      child: ClipOval(
        child: Image(
          image: getProfileImageProvider(imageUrl),
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            print('Error loading profile image: $error');
            return CircleAvatar(
              backgroundColor: backgroundColor ?? Colors.blue,
              radius: radius,
              child: Text(
                fallbackText.isNotEmpty ? fallbackText[0].toUpperCase() : '?',
                style: TextStyle(
                  color: textColor ?? Colors.white,
                  fontSize: radius * 0.75,
                  fontWeight: FontWeight.bold,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
