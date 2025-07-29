import 'package:country_picker/country_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';

import '../../constants/app_colors.dart';
import '../../controller/auth_controller.dart';

class RegistrationPage extends StatefulWidget {
  const RegistrationPage({super.key});

  @override
  State<RegistrationPage> createState() => _RegistrationPageState();
}

class _RegistrationPageState extends State<RegistrationPage> {
  final _formKey = GlobalKey<FormState>();
  final AuthController _authController = Get.put(AuthController());

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  Country? _selectedCountry;
  bool _notificationsEnabled = true;
  String _phoneHint = 'Phone Number';

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  // 2️⃣ Update your _submitForm to validate everything and then register
  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      // All fields passed validators, so register:
      _authController.registerUser(
        name: _nameController.text,
        phoneNumber: _phoneController.text,
        countryCode: _selectedCountry!.phoneCode,
        notificationsEnabled: _notificationsEnabled,
      );
    } else {
      // If any field failed, shake out the errors
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fix the errors in red before continuing'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _updatePhoneFormat(Country country) {
    setState(() {
      _selectedCountry = country;
      // Update phone hint based on country
      if (country.countryCode == 'US') {
        _phoneHint = '(XXX) XXX-XXXX';
      } else if (country.countryCode == 'UK') {
        _phoneHint = 'XXXX XXX XXX';
      } else {
        _phoneHint = 'Phone Number';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Sign the user out of Google (and your app)
        await _authController.signOut();
        // allow the pop to happen
        return true;
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FD),
        body: Stack(
          children: [
            SafeArea(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 2️⃣ Then wrap your header in a ClipPath:
                    // 2️⃣ Swap in this ClipPath block for your header:
                    ClipPath(
                      clipper: AsymmetricBottomClipper(),
                      child: Container(
                        height: 260,
                        width: double.infinity,
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Color(0xFF03045E), // Primary deep navy
                              Color(0xFF0077B6),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: SafeArea(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 16,
                            ),
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                // ─── TEXT AT TOP-LEFT ───────────────────────────
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: const [
                                    Text(
                                      'Create Account',
                                      style: TextStyle(
                                        fontSize: 28,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.white,
                                      ),
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      'Track expenses effortlessly',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.white70,
                                      ),
                                    ),
                                  ],
                                ),

                                Positioned(
                                  top: 15,
                                  right: 0,
                                  child: Container(
                                    width: 140,
                                    height: 140,
                                    decoration: BoxDecoration(),
                                    child: Image.asset(
                                      'assets/common/penquin.png',
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                    // ─── HEADER WITH PREMIUM DESIGN ─────────────────────────
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 10,
                        horizontal: 14,
                      ),
                      child: Column(
                        children: [
                          // ─── FORM CARD WITH PREMIUM STYLING ─────────────────────
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Form(
                                key: _formKey,
                                child: Column(
                                  children: [
                                    // Full Name Field
                                    TextFormField(
                                      controller: _nameController,
                                      style: const TextStyle(fontSize: 16),
                                      decoration: InputDecoration(
                                        hintText: 'Name',
                                        prefixIcon: Container(
                                          margin: const EdgeInsets.all(10),
                                          child: Icon(
                                            Icons.person_outline,
                                            color: AppColors.primary,
                                          ),
                                        ),
                                        filled: true,
                                        fillColor: const Color(0xFFF9FAFB),
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                              vertical: 18,
                                              horizontal: 16,
                                            ),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            14,
                                          ),
                                          borderSide: BorderSide.none,
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            14,
                                          ),
                                          borderSide: BorderSide.none,
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            14,
                                          ),
                                          borderSide: const BorderSide(
                                            color: AppColors.primary,
                                            width: 1.5,
                                          ),
                                        ),
                                      ),
                                      validator:
                                          (val) =>
                                              val!.trim().isEmpty
                                                  ? 'Please enter your name'
                                                  : null,
                                    ),
                                    const SizedBox(height: 20),

                                    // Country Picker
                                    GestureDetector(
                                      onTap: () {
                                        showCountryPicker(
                                          context: context,
                                          showPhoneCode: true,
                                          countryListTheme: CountryListThemeData(
                                            borderRadius: BorderRadius.circular(
                                              20,
                                            ),
                                            inputDecoration: InputDecoration(
                                              filled: true,
                                              fillColor: const Color(
                                                0xFFF9FAFB,
                                              ),
                                              contentPadding:
                                                  const EdgeInsets.all(16),
                                              hintText: 'Search country...',
                                              border: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(14),
                                                borderSide: BorderSide.none,
                                              ),
                                            ),
                                          ),
                                          onSelect:
                                              (country) =>
                                                  _updatePhoneFormat(country),
                                        );
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 16,
                                          horizontal: 16,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF9FAFB),
                                          borderRadius: BorderRadius.circular(
                                            14,
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            if (_selectedCountry != null)
                                              Container(
                                                margin: const EdgeInsets.only(
                                                  right: 12,
                                                ),
                                                child: Text(
                                                  _selectedCountry!.flagEmoji,
                                                  style: const TextStyle(
                                                    fontSize: 24,
                                                  ),
                                                ),
                                              ),
                                            Expanded(
                                              child: Text(
                                                _selectedCountry?.name ??
                                                    'Select Country',
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  color:
                                                      _selectedCountry == null
                                                          ? const Color(
                                                            0xFF9CA3AF,
                                                          )
                                                          : const Color(
                                                            0xFF1A1A1A,
                                                          ),
                                                ),
                                              ),
                                            ),
                                            const Icon(
                                              Icons.arrow_drop_down,
                                              color: Color(0xFF6B7280),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 20),

                                    // Phone Number Field
                                    TextFormField(
                                      controller: _phoneController,
                                      keyboardType: TextInputType.phone,
                                      inputFormatters: [
                                        FilteringTextInputFormatter.digitsOnly,
                                        LengthLimitingTextInputFormatter(15),
                                      ],
                                      style: const TextStyle(fontSize: 16),
                                      decoration: InputDecoration(
                                        hintText: _phoneHint,
                                        prefixIcon: Container(
                                          // width: 100,
                                          margin: const EdgeInsets.only(
                                            right: 4,
                                            top: 4,
                                            bottom: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFEDF2FF),
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const Icon(
                                                  Icons.phone_outlined,
                                                  size: 20,
                                                  color: AppColors.primary,
                                                ),
                                                const SizedBox(width: 6),
                                                Text(
                                                  _selectedCountry?.phoneCode ??
                                                      '+',
                                                  style: const TextStyle(
                                                    fontSize: 16,
                                                    color: Color(0xFF1A1A1A),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        filled: true,
                                        fillColor: const Color(0xFFF9FAFB),
                                        contentPadding: const EdgeInsets.only(
                                          left: 16,
                                          top: 18,
                                          bottom: 18,
                                        ),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            14,
                                          ),
                                          borderSide: BorderSide.none,
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            14,
                                          ),
                                          borderSide: BorderSide.none,
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            14,
                                          ),
                                          borderSide: const BorderSide(
                                            color: AppColors.primary,
                                            width: 1.5,
                                          ),
                                        ),
                                      ),
                                      validator: (val) {
                                        if (val!.trim().isEmpty) {
                                          return 'Please enter your phone number';
                                        }
                                        if (val.length < 8) {
                                          return 'Phone number is too short';
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 24),

                                    // Notifications Toggle
                                    Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF9FAFB),
                                        borderRadius: BorderRadius.circular(14),
                                        border: Border.all(
                                          color:
                                              _notificationsEnabled
                                                  ? AppColors.primary
                                                      .withOpacity(0.3)
                                                  : AppColors.grey,
                                          width: 1.5,
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.notifications_active_outlined,
                                            color:
                                                _notificationsEnabled
                                                    ? AppColors.primary
                                                    : AppColors.darkGrey,
                                          ),
                                          const SizedBox(width: 16),
                                          const Expanded(
                                            child: Text(
                                              'Enable Notifications',
                                              style: TextStyle(
                                                fontSize: 16,
                                                color: Color(0xFF1A1A1A),
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                          Transform.scale(
                                            scale: 1.2,
                                            child: Switch(
                                              value: _notificationsEnabled,
                                              activeColor: AppColors.primary,
                                              activeTrackColor: AppColors
                                                  .primary
                                                  .withOpacity(0.3),
                                              inactiveThumbColor:
                                                  AppColors.greyLight,
                                              inactiveTrackColor:
                                                  AppColors.grey,
                                              onChanged:
                                                  (v) => setState(
                                                    () =>
                                                        _notificationsEnabled =
                                                            v,
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

                          const SizedBox(height: 32),

                          // ─── GRADIENT SUBMIT BUTTON ────────────────────────────
                          Container(
                            height: 56,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              gradient: const LinearGradient(
                                colors: [
                                  Color(0xFF03045E), // Primary deep navy
                                  Color(0xFF0077B6), // Bright sapphire
                                ], // Green gradient
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(
                                    0xFFB7DAAE,
                                  ).withOpacity(0.4), // Matching shadow
                                  blurRadius: 10,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: ElevatedButton(
                              onPressed: _submitForm,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: const Text(
                                'CREATE ACCOUNT',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.8,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 24),

                          // Terms & Privacy
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              'By registering, you agree to our Terms of Service and Privacy Policy',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFF6B7280),
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
            // Loading overlay
            Obx(() {
              if (_authController.isLoading.value) {
                return Container(
                  color: Colors.black.withOpacity(0.4),
                  child: Center(
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 20,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SpinKitFadingCircle(
                            color: AppColors.primary,
                            size: 50,
                          ),
                          const SizedBox(height: 15),
                          const Text(
                            'Creating Account',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }
              return const SizedBox.shrink();
            }),
          ],
        ),
      ),
    );
  }
}

// 1️⃣ Reuse your AsymmetricBottomClipper from before
class AsymmetricBottomClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    return Path()
      ..moveTo(0, 0)
      ..lineTo(0, size.height)
      ..quadraticBezierTo(
        size.width * 0.5,
        size.height - 100,
        size.width,
        size.height - 50,
      )
      ..lineTo(size.width, 0)
      ..close();
  }

  @override
  bool shouldReclip(CustomClipper<Path> old) => false;
}
