import 'package:flutter/material.dart';
import 'package:dev_flow/core/constants/app_colors.dart';
import 'package:dev_flow/core/utils/app_text_styles.dart';
import 'package:dev_flow/data/models/user_model.dart';
import 'package:dev_flow/data/repositories/user_repository.dart';
import 'package:dev_flow/presentation/widgets/user_avatar.dart';

class UserDropdown extends StatefulWidget {
  final String? selectedUserId;
  final Function(String?) onUserSelected;
  final String hintText;
  final bool showClearOption;

  const UserDropdown({
    super.key,
    required this.selectedUserId,
    required this.onUserSelected,
    this.hintText = 'Select user',
    this.showClearOption = true,
  });

  @override
  State<UserDropdown> createState() => _UserDropdownState();
}

class _UserDropdownState extends State<UserDropdown> {
  final UserRepository _userRepository = UserRepository();
  List<User> _users = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    try {
      final users = await _userRepository.getUsers();
      if (mounted) {
        setState(() {
          _users = users;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedUser = _users
        .where((u) => u.id == widget.selectedUserId)
        .firstOrNull;

    if (_isLoading) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  DarkThemeColors.primary100,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Loading users...',
              style: AppTextStyles.bodyMedium.copyWith(
                color: DarkThemeColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: DarkThemeColors.border, width: 1),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String?>(
          value: widget.selectedUserId,
          hint: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: DarkThemeColors.primary100.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.person_add_outlined,
                  color: DarkThemeColors.primary100,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                widget.hintText,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: DarkThemeColors.textSecondary,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          icon: Icon(
            Icons.keyboard_arrow_down_rounded,
            color: DarkThemeColors.textSecondary,
            size: 24,
          ),
          isExpanded: true,
          dropdownColor: const Color(0xFF0A0A0A),
          itemHeight: null,
          menuMaxHeight: 360,
          elevation: 8,
          borderRadius: BorderRadius.circular(12),
          items: [
            if (widget.showClearOption)
              DropdownMenuItem<String?>(
                value: null,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 8,
                    horizontal: 12,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: DarkThemeColors.surface,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: DarkThemeColors.border,
                            width: 1,
                          ),
                        ),
                        child: Icon(
                          Icons.person_off_outlined,
                          color: DarkThemeColors.textSecondary,
                          size: 16,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Unassigned',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: DarkThemeColors.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ..._users.map((user) {
              return DropdownMenuItem<String?>(
                value: user.id,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 8,
                    horizontal: 12,
                  ),
                  child: Row(
                    children: [
                      UserAvatar(user: user, radius: 16),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              user.name,
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: DarkThemeColors.textPrimary,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              user.email,
                              style: AppTextStyles.bodySmall.copyWith(
                                color: DarkThemeColors.textSecondary,
                                fontSize: 11,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
          onChanged: widget.onUserSelected,
          selectedItemBuilder: (context) {
            return [
              if (widget.showClearOption)
                DropdownMenuItem<String?>(
                  value: null,
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 12,
                        backgroundColor: DarkThemeColors.surface,
                        child: Icon(
                          Icons.clear,
                          color: DarkThemeColors.textSecondary,
                          size: 14,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Unassigned',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: DarkThemeColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ..._users.map((user) {
                return DropdownMenuItem<String?>(
                  value: user.id,
                  child: Row(
                    children: [
                      UserAvatar(user: selectedUser, radius: 16),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              selectedUser?.name ?? user.name,
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: DarkThemeColors.textPrimary,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (selectedUser?.email != null)
                              Text(
                                selectedUser!.email,
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: DarkThemeColors.textSecondary,
                                  fontSize: 11,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ];
          },
        ),
      ),
    );
  }
}
