import 'package:cursor_hack/features/groups/models/group_model.dart';
import 'package:cursor_hack/features/groups/repository/groups_repository.dart';
import 'package:flutter/foundation.dart';

class GroupsProvider with ChangeNotifier {
  final GroupsRepository _repo = GroupsRepository();

  List<Group> _groups = [];
  List<Group> get groups => _groups;

  List<GroupInvite> _invites = [];
  List<GroupInvite> get invites => _invites;

  bool _loadingGroups = false;
  bool get loadingGroups => _loadingGroups;

  bool _loadingInvites = false;
  bool get loadingInvites => _loadingInvites;

  String? _error;
  String? get error => _error;

  // ---------------------------------------------------------------------------
  // Groups
  // ---------------------------------------------------------------------------

  /// GET /groups — fetch all groups the user belongs to.
  Future<void> fetchGroups() async {
    _loadingGroups = true;
    _error = null;
    notifyListeners();
    try {
      _groups = await _repo.getMyGroups();
    } catch (e) {
      _error = e.toString();
    }
    _loadingGroups = false;
    notifyListeners();
  }

  Future<void> createGroup(String name) async {
    try {
      _error = null;
      final group = await _repo.createGroup(name: name);
      _groups.insert(0, group);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> deleteGroup(int groupId) async {
    try {
      _error = null;
      await _repo.deleteGroup(groupId: groupId);
      _groups.removeWhere((g) => g.groupId == groupId);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  // ---------------------------------------------------------------------------
  // Members
  // ---------------------------------------------------------------------------

  Future<List<GroupMembership>> fetchMembers(int groupId) async {
    try {
      final members = await _repo.getGroupMembers(groupId: groupId);
      final idx = _groups.indexWhere((g) => g.groupId == groupId);
      if (idx != -1) {
        _groups[idx].members = members;
        notifyListeners();
      }
      return members;
    } catch (e) {
      debugPrint('fetchMembers error: $e');
      return [];
    }
  }

  Future<String?> removeMember({
    required int groupId,
    required int userId,
  }) async {
    try {
      await _repo.removeMember(groupId: groupId, userId: userId);
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  // ---------------------------------------------------------------------------
  // Invites
  // ---------------------------------------------------------------------------

  Future<void> fetchInvites() async {
    _loadingInvites = true;
    _error = null;
    notifyListeners();
    try {
      _invites = await _repo.getMyInvites();
    } catch (e) {
      _error = e.toString();
    }
    _loadingInvites = false;
    notifyListeners();
  }

  Future<String?> sendInvite({
    required int groupId,
    required String email,
  }) async {
    try {
      await _repo.inviteToGroup(groupId: groupId, inviteeEmail: email);
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<void> acceptInvite(int inviteId) async {
    try {
      await _repo.respondToInvite(inviteId: inviteId, action: 'accept');
      _invites.removeWhere((i) => i.id == inviteId);
      notifyListeners();
      // Refresh groups list since we just joined a new one.
      fetchGroups();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> rejectInvite(int inviteId) async {
    try {
      await _repo.respondToInvite(inviteId: inviteId, action: 'reject');
      _invites.removeWhere((i) => i.id == inviteId);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }
}
