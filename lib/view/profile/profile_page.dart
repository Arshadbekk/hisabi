import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:currency_picker/currency_picker.dart';
import 'package:expo_project/controller/auth_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

import '../../constants/app_colors.dart';
import '../../controller/home_controller.dart';
import '../../models/user_model.dart';

class ProfilePage extends StatelessWidget {
  ProfilePage({Key? key}) : super(key: key);
  final HomeController hc = Get.find();
  final AuthController ac = Get.find();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF8F9FA),
      body: Obx(() {
        final UserModel? user = hc.user.value;
        if (user == null) {
          return Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        }
        return Column(
          children: [
            // ─── PREMIUM HEADER ─────────────────────────────────
            Container(
              height: 220,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.primary.withOpacity(0.9),
                    AppColors.accent1.withOpacity(0.8),
                  ],
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 16,
                    offset: Offset(0, 6),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // Decorative elements
                  Positioned(
                    top: -20,
                    right: -20,
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.1),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 30,
                    left: -30,
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.1),
                      ),
                    ),
                  ),

                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Initials avatar
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.2),
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: Center(
                            child: Text(
                              user.name != null && user.name!.isNotEmpty
                                  ? user.name!.substring(0, 1).toUpperCase()
                                  : "U",
                              style: TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: 16),

                        // User name
                        Text(
                          user.name ?? 'No Name',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),

                        SizedBox(height: 4),

                        // User email
                        Text(
                          user.email ?? '—',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withOpacity(0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ─── SCROLLABLE CONTENT ────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                physics: BouncingScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      // Account Info Card
                      _buildInfoCard(context, user),

                      SizedBox(height: 24),

                      // Settings Card
                      _buildSettingsCard(context, user),

                      SizedBox(height: 24),

                      // Action Buttons
                      _buildActionButtons(context),

                      SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildInfoCard(BuildContext context, UserModel user) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: Colors.grey[200]!, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          children: [
            _InfoTile(
              icon: Icons.email_outlined,
              label: 'Email',
              value: user.email ?? '—',
              iconColor: Color(0xFF6C63FF),
            ),
            Divider(height: 0, indent: 56),
            _InfoTile(
              icon: Icons.phone_outlined,
              label: 'Phone',
              value: user.phoneNumber ?? '—',
              iconColor: Color(0xFF4CAF50),
            ),
            Divider(height: 0, indent: 56),
            _InfoTile(
              icon: Icons.calendar_today_outlined,
              label: 'Joined',
              value:
                  user.createdAt != null
                      ? DateFormat.yMMMd().format(user.createdAt!)
                      : '—',
              iconColor: Color(0xFFFF9800),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsCard(BuildContext context, UserModel user) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: Colors.grey[200]!, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          children: [
            _SwitchTile(
              icon: Icons.notifications_outlined,
              label: 'Notifications',
              value: user.notificationsEnabled ?? true,
              iconColor: Color(0xFF2196F3),
              onChanged: (v) {
                hc
                    .updateUser({'notificationsEnabled': v})
                    .catchError((e) => Get.snackbar('Error', e.toString()));
              },
            ),
            Divider(height: 0, indent: 56),
            _OptionTile(
              icon: Icons.attach_money_outlined,
              label: 'Monthly Income',
              // read from your MonthlySummary model
              value: hc.summary.value?.totalIncome.toStringAsFixed(0) ?? '0',
              iconColor: Color(0xFF9C27B0),
              onTap: () => _showEditIncomeDialog(context),
            ),

            Divider(height: 0, indent: 56),
            _OptionTile(
              icon: Icons.attach_money_outlined,
              label: 'Currency',
              value: user.currencyCode ?? 'USD',
              iconColor: const Color(0xFFE91E63),
              onTap: () {
                showCurrencyPicker(
                  context: context,
                  showFlag: true, // display country flag
                  showCurrencyName: true, // display currency name
                  showCurrencyCode: true, // display ISO code
                  onSelect: (Currency currency) {
                    hc.updateCurrency(currency.code, currency.symbol);
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showEditIncomeDialog(BuildContext context) async {
    final currentIncome = hc.summary.value?.totalIncome ?? 0.0;
    final textCtrl = TextEditingController(
      text: currentIncome.toStringAsFixed(0),
    );

    final newIncome = await showDialog<double>(
      context: context,
      barrierColor: Colors.black54,
      builder:
          (context) => Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.symmetric(horizontal: 24),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
                    child: Text(
                      'Edit Monthly Income',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.black,
                      ),
                    ),
                  ),

                  // Divider
                  const Divider(height: 1, color: AppColors.grey),

                  // Input Field
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 20,
                    ),
                    child: TextField(
                      controller: textCtrl,
                      autofocus: true,
                      keyboardType: TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: AppColors.black,
                      ),
                      decoration: InputDecoration(
                        border: const UnderlineInputBorder(
                          borderSide: BorderSide(color: AppColors.grey),
                        ),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(
                            color: AppColors.primary,
                            width: 2,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 12,
                        ),
                        hintText: 'Enter amount',
                        hintStyle: TextStyle(
                          color: AppColors.darkGrey.withOpacity(0.6),
                        ),
                      ),
                    ),
                  ),

                  // Action Buttons
                  Padding(
                    padding: const EdgeInsets.only(
                      top: 8,
                      bottom: 16,
                      right: 16,
                      left: 16,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.darkGrey,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                          ),
                          child: const Text('CANCEL'),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () {
                            final parsed = double.tryParse(textCtrl.text);
                            if (parsed != null) Navigator.pop(context, parsed);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: AppColors.black,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 10,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text('SAVE'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
    );

    if (newIncome != null) {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      final monthId = DateFormat('yyyy-MM').format(DateTime.now());
      final firestore = FirebaseFirestore.instance;

      await hc.updateUser({'monthlyIncome': newIncome});

      await firestore
          .collection('users')
          .doc(uid)
          .collection('monthlySummaries')
          .doc(monthId)
          .set({'totalIncome': newIncome}, SetOptions(merge: true));

      hc.refresh();
    }
  }

  Widget _buildActionButtons(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Color(0xFF6C63FF),
              elevation: 0,
              padding: EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Color(0xFF6C63FF)),
              ),
            ),
            onPressed: () => _showLogoutDialog(context),
            child: Text('Sign Out'),
          ),
        ),
        SizedBox(height: 12),
        TextButton(
          onPressed: () => _showDeleteAccountDialog(context),
          child: Text(
            'Delete Account',
            style: TextStyle(color: Color(0xFFE53935)),
          ),
        ),
        SizedBox(height: 50),
      ],
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Sign Out'),
            content: Text('Are you sure you want to sign out?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Cancel', style: TextStyle(color: Colors.grey)),
              ),
              TextButton(
                onPressed: () {
                  ac.signOut();
                },
                child: Text('Sign Out', style: TextStyle(color: Colors.red)),
              ),
            ],
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
    );
  }

  void _showDeleteAccountDialog(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Delete Account'),
            content: Text(
              'This will permanently delete your account and all data. This action cannot be undone.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Cancel', style: TextStyle(color: Colors.grey)),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  // TODO: Implement account deletion
                  Get.snackbar(
                    'Account Deletion',
                    'Account deletion feature to be implemented',
                  );
                },
                child: Text('Delete', style: TextStyle(color: Colors.red)),
              ),
            ],
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
    );
  }

  Future<String?> _showChoiceDialog({
    required BuildContext context,
    required String title,
    required List<String> options,
    required String current,
  }) {
    return showDialog<String>(
      context: context,
      builder:
          (_) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text(
                    title,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                ),
                Divider(height: 0),
                ...options.map(
                  (opt) => ListTile(
                    title: Text(opt),
                    trailing:
                        opt == current
                            ? Icon(Icons.check, color: AppColors.primary)
                            : null,
                    onTap: () => Navigator.pop(context, opt),
                  ),
                ),
                SizedBox(height: 8),
              ],
            ),
          ),
    );
  }
}

/// ─── CUSTOM TILE WIDGETS ──────────────────────────────────

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label, value;
  final Color iconColor;

  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
    this.iconColor = const Color(0xFF6C63FF),
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(
        label,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: Color(0xFF718096),
        ),
      ),
      subtitle: Text(
        value,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: Color(0xFF2D3748),
        ),
      ),
      minVerticalPadding: 16,
    );
  }
}

class _SwitchTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool value;
  final Color iconColor;
  final ValueChanged<bool> onChanged;

  const _SwitchTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.onChanged,
    this.iconColor = const Color(0xFF6C63FF),
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(
        label,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: Color(0xFF2D3748),
        ),
      ),
      trailing: Switch.adaptive(
        value: value,
        activeColor: AppColors.primary,
        onChanged: onChanged,
      ),
      minVerticalPadding: 16,
    );
  }
}

class _OptionTile extends StatelessWidget {
  final IconData icon;
  final String label, value;
  final Color iconColor;
  final VoidCallback onTap;

  const _OptionTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
    this.iconColor = const Color(0xFF6C63FF),
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(
        label,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: Color(0xFF2D3748),
        ),
      ),
      subtitle: Text(
        value,
        style: TextStyle(fontSize: 14, color: Color(0xFF718096)),
      ),
      trailing: Icon(Icons.chevron_right, color: Colors.grey[400]),
      onTap: onTap,
      minVerticalPadding: 16,
    );
  }
}
