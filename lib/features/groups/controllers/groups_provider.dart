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

  /// GET /groups — fetch all groups the user belongs to, then eagerly
  /// load member lists so the group tiles can show accurate counts.
  Future<void> fetchGroups() async {
    _loadingGroups = true;
    _error = null;
    notifyListeners();
    try {
      _groups = await _repo.getMyGroups();
      _loadingGroups = false;
      notifyListeners();

      // Eagerly fetch members for every group in parallel.
      await Future.wait(
        _groups.map((g) async {
          try {
            g.members = await _repo.getGroupMembers(groupId: g.groupId);
          } catch (_) {}
        }),
      );
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _loadingGroups = false;
      notifyListeners();
    }
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

  // ---------------------------------------------------------------------------
  // Event Proposals
  // ---------------------------------------------------------------------------

  List<EventProposal> _proposals = [];
  List<EventProposal> get proposals => _proposals;

  bool _loadingProposals = false;
  bool get loadingProposals => _loadingProposals;

  Future<List<EventProposal>> fetchProposals(int groupId) async {
    _loadingProposals = true;
    notifyListeners();
    try {
      _proposals = await _repo.getGroupProposals(groupId: groupId);
    } catch (e) {
      debugPrint('fetchProposals error: $e');
      _proposals = [];
    }
    _loadingProposals = false;
    notifyListeners();
    return _proposals;
  }

  /// Returns `({String? error, bool scheduled})`.
  /// [error] is null on success. [scheduled] is true when all members
  /// accepted and the event was pushed to Google Calendar.
  Future<({String? error, bool scheduled})> respondToProposal({
    required int proposalId,
    required String action,
    required int groupId,
  }) async {
    try {
      final data = await _repo.respondToProposal(
        proposalId: proposalId,
        action: action,
      );
      if (data['proposal'] != null) {
        final updated = EventProposal.fromJson(
          data['proposal'] as Map<String, dynamic>,
        );
        final idx = _proposals.indexWhere(
          (p) => p.proposalId == proposalId,
        );
        if (idx != -1) {
          _proposals[idx] = updated;
        }
      }
      notifyListeners();
      final scheduled = data['scheduled'] == true;
      return (error: null, scheduled: scheduled);
    } catch (e) {
      return (error: e.toString(), scheduled: false);
    }
  }
}
