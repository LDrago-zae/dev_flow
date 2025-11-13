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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String?>(
          value: widget.selectedUserId,
          hint: Row(
            children: [
              CircleAvatar(
                radius: 12,
                backgroundColor: DarkThemeColors.surface,
                child: Icon(
                  Icons.person_add,
                  color: DarkThemeColors.textSecondary,
                  size: 14,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                widget.hintText,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: DarkThemeColors.textSecondary,
                ),
              ),
            ],
          ),
          icon: Icon(
            Icons.arrow_drop_down,
            color: DarkThemeColors.textSecondary,
          ),
          isExpanded: true,
          dropdownColor: DarkThemeColors.surface,
          items: [
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
                    UserAvatar(user: user, radius: 12),
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
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            user.email,
                            style: AppTextStyles.bodySmall.copyWith(
                              color: DarkThemeColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
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
                      UserAvatar(user: selectedUser, radius: 12),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          selectedUser?.name ?? user.name,
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: DarkThemeColors.textPrimary,
                          ),
                          overflow: TextOverflow.ellipsis,
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
