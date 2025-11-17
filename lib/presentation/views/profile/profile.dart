import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:country_picker/country_picker.dart';

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

  Country _selectedCountry = Country(
    phoneCode: '1',
    countryCode: 'US',
    e164Sc: 0,
    geographic: true,
    level: 1,
    name: 'United States',
    example: 'United States',
    displayName: 'United States',
    displayNameNoCountryCode: 'US',
    e164Key: '',
  );

  bool _isGoogleUser = false;
  bool _isLoading = true;
  bool _isEditMode = false;
  bool _isSigningOut = false;
  String? _avatarUrl;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      // Check if user signed in with Google
      _isGoogleUser = user.appMetadata['provider'] == 'google';

      // Auto-fill email (always available)
      _emailController.text = user.email ?? '';

      // Check if profile exists
      final profile = await Supabase.instance.client
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      if (profile != null) {
        // Load existing profile data for editing
        _isEditMode = true;
        _fullNameController.text = profile['name'] ?? '';
        _avatarUrl = profile['avatar_url'];

        print('✅ Loaded profile from database:');
        print('  - Name: ${profile['name']}');
        print('  - Email: ${profile['email']}');
        print('  - Avatar URL: ${profile['avatar_url']}');

        // Note: username, phone_number, date_of_birth don't exist in schema yet
      } else if (_isGoogleUser && user.userMetadata != null) {
        // Use Google metadata if profile doesn't exist yet
        _fullNameController.text = user.userMetadata?['full_name'] ?? '';
        _avatarUrl = user.userMetadata?['avatar_url'];
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading user data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

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
          _isEditMode ? 'Edit Profile' : 'Fill Your Profile',
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
                              child: _isLoading
                                  ? const CircleAvatar(
                                      radius: 54,
                                      backgroundColor: Colors.black,
                                      child: CircularProgressIndicator(),
                                    )
                                  : CircleAvatar(
                                      radius: 54,
                                      backgroundColor: Colors.black,
                                      backgroundImage: _avatarUrl != null
                                          ? NetworkImage(_avatarUrl!)
                                          : null,
                                      child: _avatarUrl == null
                                          ? Icon(
                                              Icons.person,
                                              size: 48,
                                              color:
                                                  DarkThemeColors.textSecondary,
                                            )
                                          : null,
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
                        readOnly: true,
                        enabled: false,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: DarkThemeColors.textSecondary,
                        ),
                        decoration: _inputDecoration('Email').copyWith(
                          suffixIcon: const Icon(
                            Icons.mail_outline,
                            color: DarkThemeColors.icon,
                          ),
                          fillColor: DarkThemeColors.surface,
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
                          prefixIcon: GestureDetector(
                            onTap: () {
                              showCountryPicker(
                                context: context,
                                showPhoneCode: true,
                                countryListTheme: CountryListThemeData(
                                  backgroundColor: DarkThemeColors.surface,
                                  textStyle: AppTextStyles.bodyMedium.copyWith(
                                    color: DarkThemeColors.textPrimary,
                                  ),
                                  bottomSheetHeight: 500,
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(20),
                                    topRight: Radius.circular(20),
                                  ),
                                  inputDecoration: InputDecoration(
                                    hintText: 'Search country',
                                    hintStyle: AppTextStyles.bodyMedium
                                        .copyWith(
                                          color: DarkThemeColors.textSecondary,
                                        ),
                                    prefixIcon: const Icon(Icons.search),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(
                                        color: DarkThemeColors.border,
                                      ),
                                    ),
                                  ),
                                ),
                                onSelect: (Country country) {
                                  setState(() {
                                    _selectedCountry = country;
                                  });
                                },
                              );
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    _selectedCountry.flagEmoji,
                                    style: const TextStyle(fontSize: 18),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    '+${_selectedCountry.phoneCode}',
                                    style: AppTextStyles.bodyMedium.copyWith(
                                      color: DarkThemeColors.light,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  const Icon(
                                    Icons.arrow_drop_down,
                                    color: DarkThemeColors.textSecondary,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 4),
                                  Container(
                                    width: 1,
                                    height: 24,
                                    color: DarkThemeColors.border,
                                  ),
                                  const SizedBox(width: 8),
                                ],
                              ),
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
                          onPressed: _isLoading
                              ? null
                              : () async {
                                  print(
                                    '🔘 Continue/Save button pressed - isEditMode: $_isEditMode',
                                  );
                                  if (_formKey.currentState?.validate() ??
                                      false) {
                                    try {
                                      print('✅ Form validation passed');
                                      setState(() => _isLoading = true);

                                      final user = Supabase
                                          .instance
                                          .client
                                          .auth
                                          .currentUser;
                                      if (user == null)
                                        throw Exception('No user found');

                                      print('👤 User ID: ${user.id}');

                                      // Prepare phone number with country code
                                      final phoneNumber =
                                          _phoneController.text.isNotEmpty
                                          ? '+${_selectedCountry.phoneCode} ${_phoneController.text.trim()}'
                                          : null;

                                      print('📝 Profile data to save:');
                                      print(
                                        '  - Name: ${_fullNameController.text.trim()}',
                                      );
                                      print(
                                        '  - Username: ${_usernameController.text.trim()}',
                                      );
                                      print(
                                        '  - Email: ${_emailController.text.trim()}',
                                      );
                                      print('  - Phone: $phoneNumber');
                                      print(
                                        '  - DOB: ${_dobController.text.trim()}',
                                      );
                                      print('  - Avatar URL: $_avatarUrl');

                                      // Update or insert profile with all fields
                                      await Supabase.instance.client
                                          .from('profiles')
                                          .upsert({
                                            'id': user.id,
                                            'name': _fullNameController.text
                                                .trim(),
                                            'username': _usernameController.text
                                                .trim(),
                                            'email': _emailController.text
                                                .trim(),
                                            'phone_number': phoneNumber,
                                            'date_of_birth':
                                                _dobController.text
                                                    .trim()
                                                    .isNotEmpty
                                                ? _dobController.text.trim()
                                                : null,
                                            'avatar_url': _avatarUrl,
                                            'updated_at': DateTime.now()
                                                .toIso8601String(),
                                          });
                                      print(
                                        '💾 Profile saved to Supabase successfully',
                                      );

                                      if (!mounted) return;

                                      // Show success message
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            _isEditMode
                                                ? 'Profile updated successfully'
                                                : 'Profile created successfully',
                                          ),
                                          backgroundColor: Colors.green,
                                        ),
                                      );

                                      print('🎉 Success message shown');

                                      // Navigate to home only if creating profile, stay here if editing
                                      if (!_isEditMode) {
                                        print(
                                          '🏠 Navigating to home (new user)',
                                        );
                                        context.go(AppRoutes.home);
                                      } else {
                                        print(
                                          '🔄 Reloading profile data after save',
                                        );
                                        // Reload profile data to reflect changes
                                        await _loadUserData();
                                        print(
                                          '📍 Staying on profile screen (edit mode)',
                                        );
                                      }
                                    } catch (e) {
                                      print('❌ Error saving profile: $e');
                                      if (!mounted) return;
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'Failed to save profile: $e',
                                          ),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                      setState(() => _isLoading = false);
                                    }
                                  }
                                },
                          child: _isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                              : Text(
                                  _isEditMode ? 'Save Changes' : 'Continue',
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),

                      // Logout button (only show in edit mode)
                      if (_isEditMode) ...[
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red,
                              side: const BorderSide(color: Colors.red),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: _isSigningOut
                                ? null
                                : () async {
                                    // Show confirmation dialog
                                    final shouldLogout = await showDialog<bool>(
                                      context: context,
                                      barrierDismissible: false,
                                      builder: (dialogContext) {
                                        return Dialog(
                                          backgroundColor: const Color(
                                            0xFF050505,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              20,
                                            ),
                                          ),
                                          child: Padding(
                                            padding: const EdgeInsets.all(24),
                                            child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Container(
                                                  height: 64,
                                                  width: 64,
                                                  decoration: BoxDecoration(
                                                    color: Colors.red
                                                        .withOpacity(0.08),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          16,
                                                        ),
                                                  ),
                                                  child: const Icon(
                                                    Icons.logout_rounded,
                                                    color: Colors.red,
                                                    size: 28,
                                                  ),
                                                ),
                                                const SizedBox(height: 20),
                                                Text(
                                                  'Sign out of Dev Flow?',
                                                  textAlign: TextAlign.center,
                                                  style: AppTextStyles
                                                      .headlineSmall
                                                      .copyWith(
                                                        color: Colors.white,
                                                        fontSize: 20,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                      ),
                                                ),
                                                const SizedBox(height: 12),
                                                Text(
                                                  'You’ll need to sign in again to access your boards, projects, and reports.',
                                                  textAlign: TextAlign.center,
                                                  style: AppTextStyles
                                                      .bodyMedium
                                                      .copyWith(
                                                        color: DarkThemeColors
                                                            .textSecondary,
                                                        height: 1.4,
                                                      ),
                                                ),
                                                const SizedBox(height: 24),
                                                Row(
                                                  children: [
                                                    Expanded(
                                                      child: OutlinedButton(
                                                        style: OutlinedButton.styleFrom(
                                                          side: BorderSide(
                                                            color:
                                                                DarkThemeColors
                                                                    .border,
                                                          ),
                                                          foregroundColor:
                                                              DarkThemeColors
                                                                  .textPrimary,
                                                          padding:
                                                              const EdgeInsets.symmetric(
                                                                vertical: 14,
                                                              ),
                                                          shape: RoundedRectangleBorder(
                                                            borderRadius:
                                                                BorderRadius.circular(
                                                                  12,
                                                                ),
                                                          ),
                                                        ),
                                                        onPressed: () =>
                                                            Navigator.pop(
                                                              dialogContext,
                                                              false,
                                                            ),
                                                        child: const Text(
                                                          'Cancel',
                                                        ),
                                                      ),
                                                    ),
                                                    const SizedBox(width: 12),
                                                    Expanded(
                                                      child: ElevatedButton(
                                                        style: ElevatedButton.styleFrom(
                                                          backgroundColor:
                                                              Colors.red,
                                                          foregroundColor:
                                                              Colors.white,
                                                          padding:
                                                              const EdgeInsets.symmetric(
                                                                vertical: 14,
                                                              ),
                                                          shape: RoundedRectangleBorder(
                                                            borderRadius:
                                                                BorderRadius.circular(
                                                                  12,
                                                                ),
                                                          ),
                                                        ),
                                                        onPressed: () =>
                                                            Navigator.pop(
                                                              dialogContext,
                                                              true,
                                                            ),
                                                        child: const Text(
                                                          'Logout',
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                      },
                                    );

                                    if (shouldLogout == true) {
                                      setState(() => _isSigningOut = true);

                                      try {
                                        await Supabase.instance.client.auth
                                            .signOut();

                                        if (!mounted) return;
                                        context.go(AppRoutes.login);
                                      } catch (e) {
                                        if (!mounted) return;
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              'Failed to logout: $e',
                                            ),
                                            backgroundColor: Colors.red,
                                          ),
                                        );
                                        setState(() => _isSigningOut = false);
                                      }
                                    }
                                  },
                            child: _isSigningOut
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.red,
                                      ),
                                    ),
                                  )
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.logout, size: 20),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Logout',
                                        style: AppTextStyles.bodyMedium
                                            .copyWith(
                                              color: Colors.red,
                                              fontWeight: FontWeight.w600,
                                            ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                      ],
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
