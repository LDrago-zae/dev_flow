import 'package:flutter/material.dart';
import 'package:dev_flow/data/repositories/project_members_repository.dart';
import 'package:dev_flow/presentation/widgets/user_dropdown.dart';
import 'package:dev_flow/core/utils/app_text_styles.dart';
import 'package:dev_flow/core/constants/app_colors.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:dev_flow/presentation/widgets/animated_fade_slide.dart';

class ManageMembersDialog extends StatefulWidget {
  final String projectId;
  final List<Map<String, dynamic>> currentMembers;
  final VoidCallback onMembersChanged;

  const ManageMembersDialog({
    super.key,
    required this.projectId,
    required this.currentMembers,
    required this.onMembersChanged,
  });

  @override
  State<ManageMembersDialog> createState() => _ManageMembersDialogState();
}

class _ManageMembersDialogState extends State<ManageMembersDialog> {
  final ProjectMembersRepository _membersRepository =
      ProjectMembersRepository();
  bool _isAdding = false;
  String? _selectedUserId;
  String _selectedRole = 'member';

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // Header
          AnimatedFadeSlide(
            delay: 0.0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Project Members',
                  style: AppTextStyles.headlineSmall.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          AnimatedFadeSlide(
            delay: 0.1,
            child: Text(
              '${widget.currentMembers.length} member${widget.currentMembers.length != 1 ? 's' : ''}',
              style: AppTextStyles.bodySmall.copyWith(
                color: Colors.white.withOpacity(0.6),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Add member section
          AnimatedFadeSlide(
            delay: 0.2,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Add Member',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  UserDropdown(
                    selectedUserId: _selectedUserId,
                    onUserSelected: (userId) {
                      setState(() => _selectedUserId = userId);
                    },
                    hintText: 'Select user to add',
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Flexible(
                        flex: 2,
                        child: DropdownButtonFormField<String>(
                          value: _selectedRole,
                          dropdownColor: Colors.black,
                          style: const TextStyle(color: Colors.white),
                          isExpanded: true,
                          decoration: InputDecoration(
                            labelText: 'Role',
                            labelStyle: TextStyle(
                              color: Colors.white.withOpacity(0.6),
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(
                                color: Colors.white.withOpacity(0.2),
                              ),
                            ),
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 'member',
                              child: Text('Member'),
                            ),
                            DropdownMenuItem(
                              value: 'admin',
                              child: Text('Admin'),
                            ),
                            DropdownMenuItem(
                              value: 'viewer',
                              child: Text('Viewer'),
                            ),
                          ],
                          onChanged: (value) {
                            setState(() => _selectedRole = value!);
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Flexible(
                        flex: 1,
                        child: ElevatedButton(
                          onPressed: _isAdding || _selectedUserId == null
                              ? null
                              : _addMember,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 14,
                            ),
                          ),
                          child: _isAdding
                              ? SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                              : const Icon(Icons.add),
                          // icon: _isAdding
                          //     ? const SizedBox(
                          //         width: 16,
                          //         height: 16,
                          //         child: CircularProgressIndicator(
                          //           strokeWidth: 2,
                          //           color: Colors.white,
                          //         ),
                          //       )
                          //     : const Icon(Icons.add),
                          // label: Text(''),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Members list
          AnimatedFadeSlide(
            delay: 0.3,
            child: Text(
              'Current Members',
              style: AppTextStyles.bodyMedium.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 12),

          Flexible(
            child: widget.currentMembers.isEmpty
                ? AnimatedFadeSlide(
                    delay: 0.4,
                    child: Center(
                      child: Text(
                        'No members yet',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: Colors.white.withOpacity(0.5),
                        ),
                      ),
                    ),
                  )
                : ListView.builder(
                    itemCount: widget.currentMembers.length,
                    itemBuilder: (context, index) {
                      final member = widget.currentMembers[index];
                      return AnimatedFadeSlide(
                        delay: 0.4 + (index * 0.1),
                        child: _buildMemberTile(member),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildMemberTile(Map<String, dynamic> member) {
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    final isCurrentUser = member['user_id'] == currentUserId;
    final role = member['role'] as String;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          // Avatar
          CircleAvatar(
            radius: 20,
            backgroundColor: _getColorFromName(member['name']),
            backgroundImage: member['avatar_url'] != null
                ? NetworkImage(member['avatar_url'])
                : null,
            child: member['avatar_url'] == null
                ? Text(
                    _getInitials(member['name']),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 12),

          // Name and email
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        member['name'],
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isCurrentUser) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'You',
                          style: TextStyle(
                            color: Colors.blue,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                Text(
                  member['email'],
                  style: AppTextStyles.bodySmall.copyWith(
                    color: Colors.white.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),

          // Role badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _getRoleColor(role).withOpacity(0.2),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              role.toUpperCase(),
              style: TextStyle(
                color: _getRoleColor(role),
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          // Remove button (not for owner or current user)
          if (role != 'owner' && !isCurrentUser) ...[
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
              onPressed: () => _removeMember(member['user_id']),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _addMember() async {
    if (_selectedUserId == null) return;

    setState(() => _isAdding = true);

    try {
      await _membersRepository.addMember(
        projectId: widget.projectId,
        userId: _selectedUserId!,
        role: _selectedRole,
      );

      widget.onMembersChanged();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Member added successfully'),
            backgroundColor: Colors.green,
          ),
        );
        setState(() {
          _selectedUserId = null;
          _selectedRole = 'member';
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add member: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isAdding = false);
    }
  }

  Future<void> _removeMember(String userId) async {
    try {
      await _membersRepository.removeMember(
        projectId: widget.projectId,
        userId: userId,
      );

      widget.onMembersChanged();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Member removed successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to remove member: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Color _getRoleColor(String role) {
    switch (role.toLowerCase()) {
      case 'owner':
        return Colors.amber;
      case 'admin':
        return Colors.purple;
      case 'member':
        return Colors.blue;
      case 'viewer':
        return Colors.grey;
      default:
        return Colors.white;
    }
  }

  String _getInitials(String name) {
    if (name.isEmpty) return 'U';
    final parts = name.trim().split(' ');
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }

  Color _getColorFromName(String name) {
    final colors = [
      const Color(0xFF6366F1),
      const Color(0xFF8B5CF6),
      const Color(0xFFEC4899),
      const Color(0xFF10B981),
      const Color(0xFFF59E0B),
      const Color(0xFF3B82F6),
      const Color(0xFF14B8A6),
      const Color(0xFFF97316),
    ];
    final index =
        name.codeUnits.fold<int>(0, (sum, char) => sum + char) % colors.length;
    return colors[index];
  }

  static Future<void> show(
    BuildContext context, {
    required String projectId,
    required List<Map<String, dynamic>> currentMembers,
    required VoidCallback onMembersChanged,
  }) {
    return showDialog(
      context: context,
      builder: (context) => ManageMembersDialog(
        projectId: projectId,
        currentMembers: currentMembers,
        onMembersChanged: onMembersChanged,
      ),
    );
  }
}
