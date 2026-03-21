import 'package:cursor_hack/features/groups/models/group_model.dart';
import 'package:flutter/material.dart';

final List<Group> demoGroups = <Group>[
  Group(
    id: '1',
    name: 'Design Team',
    avatarColor: const Color(0xFF9B8CFF),
    lastMessage: 'Alice: Updated the mockups!',
    time: '2m',
    unreadCount: 3,
    members: <GroupMember>[
      GroupMember(id: 'u1', name: 'You', email: 'you@example.com', isAdmin: true),
      GroupMember(id: 'u2', name: 'Alice Johnson', email: 'alice@example.com'),
      GroupMember(id: 'u3', name: 'Bob Smith', email: 'bob@example.com'),
      GroupMember(id: 'u4', name: 'Carol Davis', email: 'carol@example.com'),
    ],
  ),
  Group(
    id: '2',
    name: 'Weekend Plans',
    avatarColor: const Color(0xFF4A90E2),
    lastMessage: 'Bob: Are we still on for Saturday?',
    time: '15m',
    unreadCount: 1,
    members: <GroupMember>[
      GroupMember(id: 'u1', name: 'You', email: 'you@example.com', isAdmin: true),
      GroupMember(id: 'u3', name: 'Bob Smith', email: 'bob@example.com'),
      GroupMember(id: 'u5', name: 'Dave Wilson', email: 'dave@example.com'),
    ],
  ),
  Group(
    id: '3',
    name: 'Project Alpha',
    avatarColor: const Color(0xFF5FD4A8),
    lastMessage: 'You: Pushed the latest build',
    time: '1h',
    members: <GroupMember>[
      GroupMember(id: 'u1', name: 'You', email: 'you@example.com', isAdmin: true),
      GroupMember(id: 'u2', name: 'Alice Johnson', email: 'alice@example.com'),
      GroupMember(id: 'u6', name: 'Eve Martinez', email: 'eve@example.com'),
      GroupMember(id: 'u7', name: 'Frank Lee', email: 'frank@example.com'),
      GroupMember(id: 'u8', name: 'Grace Kim', email: 'grace@example.com'),
    ],
  ),
  Group(
    id: '4',
    name: 'Family',
    avatarColor: const Color(0xFFFF7BAC),
    lastMessage: 'Mom: Dinner at 7pm',
    time: '3h',
    unreadCount: 5,
    members: <GroupMember>[
      GroupMember(id: 'u1', name: 'You', email: 'you@example.com'),
      GroupMember(id: 'u9', name: 'Mom', email: 'mom@example.com', isAdmin: true),
      GroupMember(id: 'u10', name: 'Dad', email: 'dad@example.com'),
    ],
  ),
  Group(
    id: '5',
    name: 'Book Club',
    avatarColor: const Color(0xFFFFA726),
    lastMessage: 'Eve: Chapter 12 discussion tomorrow',
    time: '1d',
    members: <GroupMember>[
      GroupMember(id: 'u6', name: 'Eve Martinez', email: 'eve@example.com', isAdmin: true),
      GroupMember(id: 'u1', name: 'You', email: 'you@example.com'),
      GroupMember(id: 'u4', name: 'Carol Davis', email: 'carol@example.com'),
    ],
  ),
];
