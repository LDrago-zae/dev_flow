import 'package:flutter/material.dart';

/// Displays stacked avatars for project members
class MemberAvatarsStack extends StatelessWidget {
  final List<Map<String, dynamic>> members;
  final int maxAvatars;
  final double avatarSize;
  final double overlapFactor; // 0.0 to 1.0

  const MemberAvatarsStack({
    super.key,
    required this.members,
    this.maxAvatars = 4,
    this.avatarSize = 32,
    this.overlapFactor = 0.3,
  });

  @override
  Widget build(BuildContext context) {
    if (members.isEmpty) return const SizedBox.shrink();

    final displayMembers = members.take(maxAvatars).toList();
    final remainingCount = members.length - maxAvatars;
    final overlapOffset = avatarSize * (1 - overlapFactor);

    return SizedBox(
      height: avatarSize,
      width:
          (displayMembers.length * overlapOffset) +
          avatarSize +
          (remainingCount > 0 ? overlapOffset : 0),
      child: Stack(
        children: [
          // Display avatars
          ...displayMembers.asMap().entries.map((entry) {
            final index = entry.key;
            final member = entry.value;
            final left = index * overlapOffset;

            return Positioned(
              left: left,
              child: _buildAvatar(
                name: member['name'] ?? 'U',
                avatarUrl: member['avatar_url'],
              ),
            );
          }),

          // "+X more" badge if there are more members
          if (remainingCount > 0)
            Positioned(
              left: displayMembers.length * overlapOffset,
              child: _buildMoreBadge(remainingCount),
            ),
        ],
      ),
    );
  }

  Widget _buildAvatar({required String name, String? avatarUrl}) {
    return Container(
      width: avatarSize,
      height: avatarSize,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
        color: _getColorFromName(name),
        image: avatarUrl != null && avatarUrl.isNotEmpty
            ? DecorationImage(image: NetworkImage(avatarUrl), fit: BoxFit.cover)
            : null,
      ),
      child: avatarUrl == null || avatarUrl.isEmpty
          ? Center(
              child: Text(
                _getInitials(name),
                style: TextStyle(
                  color: Colors.white,
                  fontSize: avatarSize * 0.4,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildMoreBadge(int count) {
    return Container(
      width: avatarSize,
      height: avatarSize,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
        color: Colors.grey[700],
      ),
      child: Center(
        child: Text(
          '+$count',
          style: TextStyle(
            color: Colors.white,
            fontSize: avatarSize * 0.35,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  String _getInitials(String name) {
    if (name.isEmpty) return 'U';

    final parts = name.trim().split(' ');
    if (parts.length == 1) {
      return parts[0][0].toUpperCase();
    }

    return (parts[0][0] + parts[1][0]).toUpperCase();
  }

  Color _getColorFromName(String name) {
    final colors = [
      const Color(0xFF6366F1), // Indigo
      const Color(0xFF8B5CF6), // Purple
      const Color(0xFFEC4899), // Pink
      const Color(0xFF10B981), // Green
      const Color(0xFFF59E0B), // Amber
      const Color(0xFF3B82F6), // Blue
      const Color(0xFF14B8A6), // Teal
      const Color(0xFFF97316), // Orange
    ];

    final index =
        name.codeUnits.fold<int>(0, (sum, char) => sum + char) % colors.length;
    return colors[index];
  }
}
