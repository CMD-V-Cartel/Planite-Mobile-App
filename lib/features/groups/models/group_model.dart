import 'dart:math';

import 'package:flutter/material.dart';

class GroupMember {
  GroupMember({
    required this.id,
    required this.name,
    required this.email,
    this.avatarUrl,
    this.isAdmin = false,
  });

  final String id;
  final String name;
  final String email;
  final String? avatarUrl;
  bool isAdmin;

  String get initials {
    final List<String> parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return name.substring(0, name.length.clamp(0, 2)).toUpperCase();
  }
}

class Group {
  Group({
    required this.id,
    required this.name,
    required this.avatarColor,
    required this.members,
    this.lastMessage = '',
    this.time = '',
    this.unreadCount = 0,
    String? inviteCode,
  }) : inviteCode = inviteCode ?? _generateCode();

  final String id;
  final String name;
  final Color avatarColor;
  final List<GroupMember> members;
  final String lastMessage;
  final String time;
  final int unreadCount;
  final String inviteCode;

  String get initials {
    final List<String> parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return name.substring(0, name.length.clamp(0, 2)).toUpperCase();
  }

  String get inviteLink => 'https://planite.app/join/$inviteCode';

  static String _generateCode() {
    const String chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final Random rng = Random();
    return List<String>.generate(
      8,
      (_) => chars[rng.nextInt(chars.length)],
    ).join();
  }
}
