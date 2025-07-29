import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String name;
  final String email;
  final String phoneNumber;
  final String countryCode;
  final bool notificationsEnabled;
  final bool onboardingComplete;
  final String currencyCode;
  final String currencySymbol;
  final double monthlyIncome;
  final String role;
  final DateTime createdAt;
  final Map<String, dynamic>? monthlySummaries;

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.phoneNumber,
    required this.countryCode,
    required this.notificationsEnabled,
    required this.onboardingComplete,
    required this.currencyCode,
    required this.currencySymbol,
    required this.monthlyIncome,
    required this.role,
    required this.createdAt,
    this.monthlySummaries,
  });

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] as String,
      name: map['name'] as String,
      email: map['email'] as String,
      phoneNumber: map['phoneNumber'] as String,
      countryCode: map['countryCode'] as String,
      notificationsEnabled: map['notificationsEnabled'] as bool,
      onboardingComplete: map['onboardingComplete'] as bool,
      currencyCode: map['currencyCode'] as String,
      currencySymbol: map['currencySymbol'] as String,
      monthlyIncome: (map['monthlyIncome'] as num).toDouble(),
      role: map['role'] as String,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      monthlySummaries: map['monthlySummaries'] != null
          ? Map<String, dynamic>.from(map['monthlySummaries'] as Map)
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'phoneNumber': phoneNumber,
      'countryCode': countryCode,
      'notificationsEnabled': notificationsEnabled,
      'onboardingComplete': onboardingComplete,
      'currencyCode': currencyCode,
      'currencySymbol': currencySymbol,
      'monthlyIncome': monthlyIncome,
      'role': role,
      'createdAt': createdAt,
      'monthlySummaries': monthlySummaries,
    };
  }
}
