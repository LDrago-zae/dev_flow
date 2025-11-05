import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:pinput/pinput.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/app_text_styles.dart';
import '../../../../routes/app_routes.dart';

class OtpVerification extends StatefulWidget {
  final String email;

  const OtpVerification({super.key, required this.email});

  @override
  State<OtpVerification> createState() => _OtpVerificationState();
}

class _OtpVerificationState extends State<OtpVerification> {
  final TextEditingController _pinController = TextEditingController();
  final FocusNode _pinFocusNode = FocusNode();

  @override
  void dispose() {
    _pinController.dispose();
    _pinFocusNode.dispose();
    super.dispose();
  }

  void _verifyOtp() {
    String otpCode = _pinController.text;
    if (otpCode.length != 4) {
      Get.snackbar(
        'Error',
        'Please enter complete OTP code',
        backgroundColor: DarkThemeColors.errorDark,
        colorText: Colors.white,
      );
      return;
    } else {
      Get.snackbar('OTP has been sent', 'OTP has been sent to ${widget.email}',
          backgroundColor: DarkThemeColors.success,
          icon: Padding(
            padding: const EdgeInsets.all(8.0),
            child: FaIcon(FontAwesomeIcons.circleCheck, color: DarkThemeColors.icon),
          ),
          colorText: Colors.white);
          _pinController.clear();
          _pinFocusNode.unfocus();
    }
    // Add your OTP verification logic here
    context.go(AppRoutes.verificationScreen);
  }

  void _resendOtp() {
    // Add your resend OTP logic here
    Get.snackbar(
      'Success',
      'OTP has been resent to ${widget.email}',
      backgroundColor: DarkThemeColors.primary100,
      colorText: Colors.white,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DarkThemeColors.dark,
      appBar: AppBar(
        backgroundColor: DarkThemeColors.dark,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "You're almost there!",
                  style: AppTextStyles.headlineSmall.copyWith(
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                RichText(
                  text: TextSpan(
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: DarkThemeColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                    children: [
                      const TextSpan(
                        text:
                            'You only have to enter an OTP code we sent via Email to your registered email\n',
                      ),
                      TextSpan(
                        text: '${widget.email}\n',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 48),
                Center(
                  child: Text(
                    'OTP verification code',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: DarkThemeColors.textSecondary,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Center(
                  child: Pinput(
                    controller: _pinController,
                    focusNode: _pinFocusNode,
                    length: 4,
                    defaultPinTheme: PinTheme(
                      width: 64,
                      height: 64,
                      textStyle: AppTextStyles.headlineMedium.copyWith(
                        color: Colors.white,
                      ),
                      decoration: BoxDecoration(
                        color: DarkThemeColors.dark,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: DarkThemeColors.border),
                      ),
                    ),
                    focusedPinTheme: PinTheme(
                      width: 64,
                      height: 64,
                      textStyle: AppTextStyles.headlineMedium.copyWith(
                        color: DarkThemeColors.primary100,
                      ),
                      decoration: BoxDecoration(
                        color: DarkThemeColors.dark,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: DarkThemeColors.primary600,
                          width: 1,
                        ),
                      ),
                    ),
                    submittedPinTheme: PinTheme(
                      width: 64,
                      height: 64,
                      textStyle: AppTextStyles.headlineMedium.copyWith(
                        color: DarkThemeColors.primary600,
                      ),
                      decoration: BoxDecoration(
                        color: DarkThemeColors.dark,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: DarkThemeColors.border),
                      ),
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    onCompleted: (pin) {
                      print('OTP completed: $pin');
                    },
                  ),
                ),
                const SizedBox(height: 24),
                Center(
                  child: RichText(
                    text: TextSpan(
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: DarkThemeColors.textSecondary,
                      ),
                      children: [
                        const TextSpan(text: "If you didn't receive a OTP? "),
                        WidgetSpan(
                          child: GestureDetector(
                            onTap: _resendOtp,
                            child: Text(
                              'Resend',
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: DarkThemeColors.primary100,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // const Spacer(),
                const SizedBox(height: 260),
                SizedBox(
                  width: 320,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: DarkThemeColors.primary100,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: _verifyOtp,
                    child: Text(
                      'Verify',
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
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
