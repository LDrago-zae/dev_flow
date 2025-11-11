import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/app_text_styles.dart';
import '../../../routes/app_routes.dart';
import '../../../presentation/widgets/responsive_layout.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  final _fullNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _dobController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();

  @override
  void dispose() {
    _fullNameController.dispose();
    _usernameController.dispose();
    _dobController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: AppTextStyles.bodyMedium.copyWith(
        color: DarkThemeColors.textSecondary,
      ),
      filled: true,
      fillColor: Colors.black,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: DarkThemeColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: DarkThemeColors.primary100,
          width: 1.5,
        ),
      ),
    );
  }

  Future<void> _pickDateOfBirth() async {
    FocusScope.of(context).unfocus();
    final now = DateTime.now();
    final initialDate = DateTime(now.year - 18, now.month, now.day);
    final earliestDate = DateTime(now.year - 80);
    final latestDate = DateTime(now.year - 13, now.month, now.day);

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: earliestDate,
      lastDate: latestDate,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: DarkThemeColors.primary100,
              surface: DarkThemeColors.surface,
              onSurface: DarkThemeColors.textPrimary,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: DarkThemeColors.primary100,
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      final formatted =
          '${picked.day.toString().padLeft(2, '0')}/'
          '${picked.month.toString().padLeft(2, '0')}/'
          '${picked.year.toString()}';
      _dobController.text = formatted;
    }
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: AppTextStyles.bodyMedium.copyWith(
        color: DarkThemeColors.textSecondary,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        // leading: IconButton(
        //   onPressed: () => Navigator.of(context).maybePop(),
        //   icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
        // ),
        centerTitle: true,
        title: Text(
          'Fill Your Profile',
          style: AppTextStyles.headlineSmall.copyWith(
            fontWeight: FontWeight.w600,
            color: DarkThemeColors.light,
          ),
        ),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 24,
                ),
                child: ResponsiveLayout(
                  centerContent: true,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: DarkThemeColors.border,
                                  width: 2,
                                ),
                                shape: BoxShape.circle,
                              ),
                              child: CircleAvatar(
                                radius: 54,
                                backgroundColor: Colors.black,
                                child: Icon(
                                  Icons.person,
                                  size: 48,
                                  color: DarkThemeColors.textSecondary,
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: -2,
                              right: -2,
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: DarkThemeColors.primary100,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: DarkThemeColors.border,
                                    width: 2,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.edit,
                                  size: 16,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),

                      _buildLabel('Full Name'),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _fullNameController,
                        onTapOutside: (_) => FocusScope.of(context).unfocus(),
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: DarkThemeColors.light,
                        ),
                        decoration: _inputDecoration('Full Name'),
                      ),

                      const SizedBox(height: 20),

                      _buildLabel('Username'),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _usernameController,
                        onTapOutside: (_) => FocusScope.of(context).unfocus(),
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: DarkThemeColors.light,
                        ),
                        decoration: _inputDecoration('Username'),
                      ),

                      const SizedBox(height: 20),

                      _buildLabel('Date of Birth'),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _dobController,
                        readOnly: true,
                        onTap: _pickDateOfBirth,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: DarkThemeColors.light,
                        ),
                        decoration: _inputDecoration('Date of Birth').copyWith(
                          suffixIcon: const Icon(
                            Icons.calendar_today_outlined,
                            color: DarkThemeColors.icon,
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      _buildLabel('Email'),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        onTapOutside: (_) => FocusScope.of(context).unfocus(),
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: DarkThemeColors.light,
                        ),
                        decoration: _inputDecoration('Email').copyWith(
                          suffixIcon: const Icon(
                            Icons.mail_outline,
                            color: DarkThemeColors.icon,
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      _buildLabel('Phone Number'),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        onTapOutside: (_) => FocusScope.of(context).unfocus(),
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: DarkThemeColors.light,
                        ),
                        decoration: _inputDecoration('Phone Number').copyWith(
                          prefixIcon: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text(
                                  '🇺🇸',
                                  style: TextStyle(fontSize: 18),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '+1',
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    color: DarkThemeColors.light,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  width: 1,
                                  height: 24,
                                  color: DarkThemeColors.border,
                                ),
                                const SizedBox(width: 8),
                              ],
                            ),
                          ),
                          prefixIconConstraints: const BoxConstraints(
                            minWidth: 0,
                            minHeight: 0,
                          ),
                        ),
                      ),

                      const SizedBox(height: 32),

                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: DarkThemeColors.primary100,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () {
                            if (_formKey.currentState?.validate() ?? false) {
                              // TODO: Handle profile submission
                              context.go(AppRoutes.home);
                            }
                          },
                          child: Text(
                            'Continue',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
