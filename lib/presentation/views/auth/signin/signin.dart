import 'package:dev_flow/core/utils/string_extensions.dart';
import 'package:dev_flow/presentation/views/auth/signin/signin_verification.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/app_text_styles.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../signup/signup.dart';

class SignIn extends StatefulWidget {
  const SignIn({super.key});

  @override
  State<SignIn> createState() => _SignInState();
}

class _SignInState extends State<SignIn> {
  // Controllers and UI state
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _obscurePassword = true;
  bool _rememberMe = false;

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
                  'Sign In',
                  style: AppTextStyles.headlineLarge.copyWith(
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  "We're thrilled to welcome you back! Curious to catch up on all your latest adventures since your last login.",
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

                // Remember Me & Forgot Password
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Checkbox(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                          value: _rememberMe,
                          onChanged: (v) =>
                              setState(() => _rememberMe = v ?? false),
                          side: const BorderSide(color: DarkThemeColors.border),
                          activeColor: DarkThemeColors.primary100,
                          checkColor: Colors.white,
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                          visualDensity: VisualDensity.compact,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Remember Me',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: DarkThemeColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    GestureDetector(
                      onTap: () {
                        // TODO: Navigate to forgot password screen
                      },
                      child: Text(
                        'Forgot password?',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: DarkThemeColors.primary100,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Sign In button
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
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        // TODO: Implement sign in logic
                        Get.to(() => const SigninVerification());
                      }
                    },
                    child: Text(
                      'Sign In',
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
                        'Or sign in with',
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

                // Social sign-in buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    _GoogleButton(),
                  ],
                ),

                const SizedBox(height: 24),

                // Footer: Don't have an account? Sign Up
                Center(
                  child: Wrap(
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        "Don't have an account? ",
                        style: AppTextStyles.bodySmall.copyWith(
                          color: DarkThemeColors.textSecondary,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          Get.to(() => const Signup());
                        },
                        child: Text(
                          'Sign Up',
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
