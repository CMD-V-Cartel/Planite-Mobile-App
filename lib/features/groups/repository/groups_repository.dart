import 'dart:developer';

import 'package:cursor_hack/features/groups/models/group_model.dart';
import 'package:cursor_hack/services/network/api_urls.dart';
import 'package:cursor_hack/services/storage/storage_service.dart';
import 'package:dio/dio.dart';

class GroupsRepository {
  final Dio _dio = Dio(BaseOptions(
    baseUrl: ApiUrls.baseUrl,
    connectTimeout: const Duration(seconds: 12),
    receiveTimeout: const Duration(seconds: 12),
    contentType: Headers.jsonContentType,
  ));

  Future<Options> _authOptions() async {
    final token = await StorageService.instance.getToken();
    return Options(headers: {
      if (token != null) 'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    });
  }

  // ---------------------------------------------------------------------------
  // Groups
  // ---------------------------------------------------------------------------

  /// GET /groups — returns all groups the current user belongs to.
  Future<List<Group>> getMyGroups() async {
    try {
      final response = await _dio.get(
        ApiUrls.createGroup,
        options: await _authOptions(),
      );
      final data = response.data as Map<String, dynamic>;
      final list = data['groups'] as List<dynamic>;
      return list
          .map((e) => Group.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      log('getMyGroups error: ${e.response?.data}');
      throw _extractError(e, 'Failed to load groups');
    }
  }

  /// POST /groups
  Future<Group> createGroup({required String name}) async {
    try {
      final response = await _dio.post(
        ApiUrls.createGroup,
        data: {'name': name},
        options: await _authOptions(),
      );
      final data = response.data as Map<String, dynamic>;
      return Group.fromJson(data['group'] as Map<String, dynamic>);
    } on DioException catch (e) {
      log('createGroup error: ${e.response?.data}');
      throw _extractError(e, 'Failed to create group');
    }
  }

  /// DELETE /groups/{group_id}
  Future<void> deleteGroup({required int groupId}) async {
    try {
      await _dio.delete(
        ApiUrls.deleteGroup(groupId),
        options: await _authOptions(),
      );
    } on DioException catch (e) {
      log('deleteGroup error: ${e.response?.data}');
      throw _extractError(e, 'Failed to delete group');
    }
  }

  // ---------------------------------------------------------------------------
  // Members
  // ---------------------------------------------------------------------------

  /// DELETE /groups/{group_id}/members/{user_id}
  Future<void> removeMember({
    required int groupId,
    required int userId,
  }) async {
    try {
      await _dio.delete(
        ApiUrls.removeMember(groupId, userId),
        options: await _authOptions(),
      );
    } on DioException catch (e) {
      log('removeMember error: ${e.response?.data}');
      throw _extractError(e, 'Failed to remove member');
    }
  }

  /// GET /groups/{group_id}/members
  Future<List<GroupMembership>> getGroupMembers({
    required int groupId,
  }) async {
    try {
      final response = await _dio.get(
        ApiUrls.groupMembers(groupId),
        options: await _authOptions(),
      );
      final data = response.data as Map<String, dynamic>;
      final list = data['members'] as List<dynamic>;
      return list
          .map((e) => GroupMembership.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      log('getGroupMembers error: ${e.response?.data}');
      throw _extractError(e, 'Failed to load members');
    }
  }

  // ---------------------------------------------------------------------------
  // Invites
  // ---------------------------------------------------------------------------

  /// POST /groups/{group_id}/invite
  Future<GroupInvite> inviteToGroup({
    required int groupId,
    required String inviteeEmail,
  }) async {
    try {
      final response = await _dio.post(
        ApiUrls.inviteToGroup(groupId),
        data: {'invitee_email': inviteeEmail},
        options: await _authOptions(),
      );
      final data = response.data as Map<String, dynamic>;
      return GroupInvite.fromJson(data['invite'] as Map<String, dynamic>);
    } on DioException catch (e) {
      log('inviteToGroup error: ${e.response?.data}');
      throw _extractError(e, 'Failed to send invite');
    }
  }

  /// GET /invites/me
  Future<List<GroupInvite>> getMyInvites() async {
    try {
      final response = await _dio.get(
        ApiUrls.myInvites,
        options: await _authOptions(),
      );
      final data = response.data as Map<String, dynamic>;
      final list = data['invites'] as List<dynamic>;
      return list
          .map((e) => GroupInvite.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      log('getMyInvites error: ${e.response?.data}');
      throw _extractError(e, 'Failed to load invites');
    }
  }

  /// POST /invites/{invite_id}/respond
  Future<GroupInvite> respondToInvite({
    required int inviteId,
    required String action,
  }) async {
    try {
      final response = await _dio.post(
        ApiUrls.respondInvite(inviteId),
        data: {'action': action},
        options: await _authOptions(),
      );
      final data = response.data as Map<String, dynamic>;
      return GroupInvite.fromJson(data['invite'] as Map<String, dynamic>);
    } on DioException catch (e) {
      log('respondToInvite error: ${e.response?.data}');
      throw _extractError(e, 'Failed to respond to invite');
    }
  }

  // ---------------------------------------------------------------------------
  // Event Proposals
  // ---------------------------------------------------------------------------

  /// GET /event-proposals/group/{group_id}
  Future<List<EventProposal>> getGroupProposals({
    required int groupId,
  }) async {
    try {
      final response = await _dio.get(
        ApiUrls.groupProposals(groupId),
        options: await _authOptions(),
      );
      final list = response.data as List<dynamic>;
      return list
          .map((e) => EventProposal.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      log('getGroupProposals error: ${e.response?.data}');
      throw _extractError(e, 'Failed to load proposals');
    }
  }

  /// POST /event-proposals/{proposal_id}/respond
  Future<Map<String, dynamic>> respondToProposal({
    required int proposalId,
    required String action,
  }) async {
    try {
      final response = await _dio.post(
        ApiUrls.respondProposal(proposalId),
        data: {'action': action},
        options: await _authOptions(),
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      log('respondToProposal error: ${e.response?.data}');
      throw _extractError(e, 'Failed to respond to proposal');
    }
  }

  String _extractError(DioException e, String fallback) {
    final detail = e.response?.data;
    if (detail is Map<String, dynamic> && detail['detail'] != null) {
      return detail['detail'].toString();
    }
    return fallback;
  }
}
