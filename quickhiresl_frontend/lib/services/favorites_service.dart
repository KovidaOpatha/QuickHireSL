import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/job.dart';

class FavoritesService {
  final storage = const FlutterSecureStorage();
  static const String _favoritesKey = 'favorite_jobs';
  static const String _userFavoritesPrefix = 'user_favorites_';

  // Get user-specific favorites key
  Future<String> _getUserFavoritesKey() async {
    final userId = await storage.read(key: 'user_id');
    return userId != null ? '$_userFavoritesPrefix$userId' : _favoritesKey;
  }

  // Get all favorite job IDs
  Future<List<String>> getFavoriteJobIds() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = await _getUserFavoritesKey();
      final favoritesList = prefs.getStringList(key) ?? [];
      return favoritesList;
    } catch (e) {
      print('Error getting favorite jobs: $e');
      return [];
    }
  }

  // Check if a job is favorited
  Future<bool> isJobFavorite(String jobId) async {
    final favorites = await getFavoriteJobIds();
    return favorites.contains(jobId);
  }

  // Toggle favorite status of a job
  Future<bool> toggleFavorite(String jobId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = await _getUserFavoritesKey();
      final favorites = prefs.getStringList(key) ?? [];
      
      final isCurrentlyFavorite = favorites.contains(jobId);
      
      if (isCurrentlyFavorite) {
        favorites.remove(jobId);
      } else {
        favorites.add(jobId);
      }
      
      await prefs.setStringList(key, favorites);
      return !isCurrentlyFavorite; // Return new favorite status
    } catch (e) {
      print('Error toggling favorite: $e');
      return false;
    }
  }

  // Get all favorite jobs (full job objects)
  Future<List<Job>> getFavoriteJobs(List<Job> allJobs) async {
    final favoriteIds = await getFavoriteJobIds();
    return allJobs.where((job) => job.id != null && favoriteIds.contains(job.id)).toList();
  }
}
