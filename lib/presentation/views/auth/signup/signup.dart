import 'package:dev_flow/core/utils/string_extensions.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/app_text_styles.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../routes/app_routes.dart';

class Signup extends StatefulWidget {
  const Signup({super.key});

  @override
  State<Signup> createState() => _SignupState();
}

class _SignupState extends State<Signup> {
  // Controllers and UI state
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _agreeTerms = false;

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: AppTextStyles.bodyMedium.copyWith(
        color: DarkThemeColors.textSecondary,
      ),
      filled: true,
      fillColor: DarkThemeColors.dark,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: DarkThemeColors.error, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: DarkThemeColors.error, width: 1.5),
      ),
      errorStyle: AppTextStyles.bodySmall.copyWith(
        color: DarkThemeColors.error,
      ),
      errorMaxLines: 3,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DarkThemeColors.dark,
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Text(
                  'Create Account',
                  style: AppTextStyles.headlineLarge.copyWith(
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  "Get ready to make your days more organized and planned. Let's start now!",
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: DarkThemeColors.textSecondary,
                  ),
                ),

                const SizedBox(height: 28),

                // Email label
                Text(
                  'Your Email',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: DarkThemeColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  onTapOutside: (event) => FocusScope.of(context).unfocus(),
                  controller: emailController,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: DarkThemeColors.light,
                  ),
                  keyboardType: TextInputType.emailAddress,
                  decoration: _inputDecoration('Email').copyWith(
                    suffixIcon: Icon(
                      size: 20,
                      Icons.email_outlined,
                      color: DarkThemeColors.icon,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your email';
                    }
                    if (!value.isValidEmail()) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // Password label
                Text(
                  'Password',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: DarkThemeColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  onTapOutside: (event) => FocusScope.of(context).unfocus(),
                  controller: passwordController,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: DarkThemeColors.textPrimary,
                  ),
                  obscureText: _obscurePassword,
                  decoration: _inputDecoration('Password').copyWith(
                    suffixIcon: IconButton(
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                      icon: Icon(
                        size: 20,
                        _obscurePassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: DarkThemeColors.icon,
                      ),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your password';
                    }
                    if (value.length < 6) {
                      return 'Password must be at least 6 characters long';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // Confirm Password label
                Text(
                  'Confirm Password',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: DarkThemeColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  onTapOutside: (event) => FocusScope.of(context).unfocus(),
                  controller: confirmPasswordController,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: DarkThemeColors.textPrimary,
                  ),
                  obscureText: _obscureConfirmPassword,
                  decoration: _inputDecoration('Confirm Password').copyWith(
                    suffixIcon: IconButton(
                      onPressed: () => setState(
                        () =>
                            _obscureConfirmPassword = !_obscureConfirmPassword,
                      ),
                      icon: Icon(
                        size: 20,
                        _obscureConfirmPassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: DarkThemeColors.icon,
                      ),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please confirm your password';
                    }
                    if (value != passwordController.text) {
                      return 'Passwords do not match';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // Terms & Conditions
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Checkbox(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                      value: _agreeTerms,
                      onChanged: (v) =>
                          setState(() => _agreeTerms = v ?? false),
                      side: const BorderSide(color: DarkThemeColors.border),
                      activeColor: DarkThemeColors.primary100,
                      checkColor: Colors.white,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: RichText(
                        text: TextSpan(
                          style: AppTextStyles.bodySmall.copyWith(
                            color: DarkThemeColors.textSecondary,
                          ),
                          children: [
                            const TextSpan(text: 'I agree to '),
                            TextSpan(
                              text: 'Terms & Conditions',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: DarkThemeColors.primary100,
                              ),
                            ),
                            const TextSpan(text: ' and '),
                            TextSpan(
                              text: 'Privacy Policy',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: DarkThemeColors.primary100,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Sign Up button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: DarkThemeColors.primary100,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () async {
                      if (_formKey.currentState!.validate()) {
                        if (!_agreeTerms) {
                          Get.snackbar(
                            'Error',
                            'Please agree to Terms & Conditions',
                            backgroundColor: DarkThemeColors.errorDark,
                            colorText: Colors.white,
                            icon: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: FaIcon(
                                FontAwesomeIcons.circleExclamation,
                                color: DarkThemeColors.icon,
                              ),
                            ),
                          );
                          return;
                        }

                        try {
                          final response = await Supabase.instance.client.auth
                              .signUp(
                                email: emailController.text.trim(),
                                password: passwordController.text.trim(),
                              );

                          if (response.user != null) {
                            // Create profile in database
                            await Supabase.instance.client
                                .from('profiles')
                                .insert({
                                  'id': response.user!.id,
                                  'name':
                                      'User', // Default name, can be updated later
                                  'email': emailController.text.trim(),
                                });

                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Account created successfully! Please check your email for verification.',
                                  ),
                                ),
                              );
                              context.go(AppRoutes.signin);
                            }
                          }
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Signup failed: ${e.toString()}'),
                              backgroundColor: DarkThemeColors.error,
                            ),
                          );
                          print(e.toString());
                        }
                      }
                    },

                    child: Text(
                      'Sign Up',
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Divider with text
                Row(
                  children: [
                    const Expanded(
                      child: Divider(
                        color: DarkThemeColors.border,
                        thickness: 1,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12.0),
                      child: Text(
                        'Or sign up with',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: DarkThemeColors.textSecondary,
                        ),
                      ),
                    ),
                    const Expanded(
                      child: Divider(
                        color: DarkThemeColors.border,
                        thickness: 1,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Social placeholders (leave spaces for icons)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Center(
                      child: const _GoogleButton(),
                      // _SocialPlaceholder(),
                      // _SocialPlaceholder(),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Footer: Already have an account? Sign In
                Center(
                  child: Wrap(
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        'Already have an account? ',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: DarkThemeColors.textSecondary,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          context.push(AppRoutes.signin);
                        },
                        child: Text(
                          'Sign In',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: DarkThemeColors.primary100,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GoogleButton extends StatelessWidget {
  const _GoogleButton();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: DarkThemeColors.dark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: DarkThemeColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FaIcon(
            FontAwesomeIcons.google,
            color: DarkThemeColors.light,
            size: 20,
          ),
          const SizedBox(width: 12),
          Text(
            'Continue with Google',
            style: AppTextStyles.bodyMedium.copyWith(
              color: DarkThemeColors.textPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
