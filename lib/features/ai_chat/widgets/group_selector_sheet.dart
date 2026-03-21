import 'package:cursor_hack/features/groups/models/group_model.dart';
import 'package:flutter/material.dart';

class GroupSelectorSheet extends StatelessWidget {
  const GroupSelectorSheet({
    super.key,
    required this.groups,
    required this.selectedGroup,
    required this.onSelected,
  });

  final List<Group> groups;
  final Group? selectedGroup;
  final ValueChanged<Group?> onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const SizedBox(height: 8),
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFD1D5DB),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Select a Group',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: Color(0xFF111111),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Direct your message to a specific group',
            style: TextStyle(fontSize: 13, color: Color(0xFF8E95A4)),
          ),
          const SizedBox(height: 12),
          if (selectedGroup != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextButton.icon(
                onPressed: () {
                  onSelected(null);
                  Navigator.of(context).pop();
                },
                icon: const Icon(Icons.close_rounded, size: 18),
                label: const Text('Clear selection'),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFFEF5350),
                ),
              ),
            ),
          const Divider(height: 1, color: Color(0xFFE8EAF0)),
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.45,
            ),
            child: ListView.separated(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: groups.length,
              separatorBuilder: (_, __) =>
                  const Divider(height: 1, indent: 72, color: Color(0xFFF0F1F4)),
              itemBuilder: (BuildContext context, int index) {
                final Group group = groups[index];
                final bool isSelected = selectedGroup?.id == group.id;
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: group.avatarColor,
                    radius: 22,
                    child: Text(
                      group.initials,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  title: Text(
                    group.name,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: const Color(0xFF111111),
                    ),
                  ),
                  subtitle: Text(
                    '${group.members.length} members',
                    style:
                        const TextStyle(fontSize: 12, color: Color(0xFF8E95A4)),
                  ),
                  trailing: isSelected
                      ? const Icon(
                          Icons.check_circle_rounded,
                          color: Color(0xFF3D5AFE),
                          size: 22,
                        )
                      : null,
                  onTap: () {
                    onSelected(group);
                    Navigator.of(context).pop();
                  },
                );
              },
            ),
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
        ],
      ),
    );
  }
}
