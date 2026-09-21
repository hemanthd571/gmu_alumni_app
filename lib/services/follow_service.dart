import '../services/api_service.dart';

class FollowService {
  /// Toggle follow status for a user
  static Future<Map<String, dynamic>> toggleFollow({
    required int followerId,
    required int followingId,
  }) async {
    try {
      final response = await ApiService.post(
        '/follows/follow.php',
        data: {
          'follower_id': followerId,
          'following_id': followingId,
        },
      );

      return {
        'success': response.data['success'] ?? false,
        'is_following': response.data['is_following'] ?? false,
        'message': response.data['message'] ?? '',
      };
    } catch (e) {
      print('❌ Follow Service Error: $e');
      return {
        'success': false,
        'is_following': false,
        'message': 'Failed to update follow status',
      };
    }
  }

  /// Get list of users that the current user is following (detailed)
  static Future<List<Map<String, dynamic>>> getFollowingDetails(int userId) async {
    try {
      final response = await ApiService.get(
        '/follows/following.php?user_id=$userId',
      );

      if (response.data['success']) {
        final List<dynamic> data = response.data['data'] ?? [];
        print('📡 Follow API Raw Data: $data');
        return data.map((item) => {
          'id': int.parse(item['following_id'].toString()),
          'name': item['name'] ?? 'User',
          'profile_picture': item['profile_picture'],
        }).toList();
      }
      return [];
    } catch (e) {
      print('❌ Get Following Details Error: $e');
      return [];
    }
  }

  /// Get list of user IDs that the current user is following
  static Future<List<int>> getFollowingList(int userId) async {
    try {
      final response = await ApiService.get(
        '/follows/following.php?user_id=$userId',
      );

      if (response.data['success']) {
        final List<dynamic> data = response.data['data'] ?? [];
        return data.map((item) => int.parse(item['following_id'].toString())).toList();
      }
      return [];
    } catch (e) {
      print('❌ Get Following List Error: $e');
      return [];
    }
  }

  /// Check if user is following another user
  static Future<bool> isFollowing({
    required int followerId,
    required int followingId,
  }) async {
    try {
      final response = await ApiService.get(
        '/follows/check.php?follower_id=$followerId&following_id=$followingId',
      );

      return response.data['is_following'] ?? false;
    } catch (e) {
      print('❌ Check Following Error: $e');
      return false;
    }
  }
}
