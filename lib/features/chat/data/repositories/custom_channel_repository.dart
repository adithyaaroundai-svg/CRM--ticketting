import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/custom_channel.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CustomChannelRepository {
  final SupabaseClient _client;

  CustomChannelRepository(this._client);

  /// Fetches all channels the user is allowed to see (public or member of)
  Future<List<CustomChannel>> getChannels(String currentUserId) async {
    final response = await _client
        .from('custom_channels')
        .select('*, channel_members(user_id)')
        .order('created_at', ascending: true);

    return response.where((json) {
      final isPrivate = json['is_private'] as bool? ?? false;
      if (!isPrivate) return true; // public channels are visible to everyone
      
      // The creator can always see their own channel
      if (json['created_by'] == currentUserId) return true;
      
      final members = json['channel_members'] as List<dynamic>? ?? [];
      final isMember = members.any((m) => m['user_id'] == currentUserId);
      return isMember;
    }).map((json) => CustomChannel.fromJson(json)).toList();
  }

  /// Create a new channel and automatically add members to it
  Future<CustomChannel> createChannel({
    required String name,
    required bool isPrivate,
    required String createdBy,
    required List<String> memberIds,
  }) async {
    // 1. Create the channel
    final response = await _client.from('custom_channels').insert({
      'name': name,
      'is_private': isPrivate,
      'created_by': createdBy,
    }).select().single();

    final channel = CustomChannel.fromJson(response);

    // 2. Add members if any (including the creator, usually)
    if (memberIds.isNotEmpty) {
      final membersPayload = memberIds.map((userId) => {
        'channel_id': channel.id,
        'user_id': userId,
      }).toList();

      await _client.from('channel_members').insert(membersPayload);
    }

    // Return the channel with the memberIds properly attached
    // so the UI can immediately use them for calls without needing a refresh.
    return CustomChannel(
      id: channel.id,
      name: channel.name,
      isPrivate: channel.isPrivate,
      createdBy: channel.createdBy,
      createdAt: channel.createdAt,
      memberIds: memberIds,
    );
  }
}

final customChannelRepositoryProvider = Provider<CustomChannelRepository>((ref) {
  return CustomChannelRepository(Supabase.instance.client);
});
