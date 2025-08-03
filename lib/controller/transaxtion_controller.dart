import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:currency_picker/currency_picker.dart';
import 'package:hisabi/controller/home_controller.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_multi_formatter/formatters/formatter_utils.dart';
import 'package:get/get.dart';
import 'package:hisabi/models/txn.dart';
import 'package:hisabi/services/hive_services.dart';
import 'package:intl/intl.dart';

import '../models/category_model.dart';
import '../models/transaction_model.dart';
import '../models/user_model.dart';

enum PaymentType { cash, card }

class AddTransactionController extends GetxController {
  // Firebase & Auth
  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;
  final ctrl = Get.put(HomeController());

  // Reactive state
  final user = Rxn<UserModel>();
  final categories = <CategoryModel>[].obs;
  final selectedCat = Rxn<CategoryModel>();
  final amount = 0.0.obs;
  final description = ''.obs;
  final amountController = TextEditingController();
  final titleController = TextEditingController();
  final paymentType = PaymentType.cash.obs;
  final selectedDate = DateTime.now().obs;
  final isLoading = false.obs; // NEW
  /// Start with user’s preferred currency or fallback to USD
  /// Instead of Rx<Currency>, just keep code & symbol
  final selectedCurrencyCode = RxString('USD');
  final selectedCurrencySymbol = RxString('\$');

  /// how many decimal places to allow
  final selectedDecimalDigits = 2.obs;
  late final String _uid;
  late final String _monthId;

  @override
  void onInit() {
    super.onInit();
    _seedCategories();

    _auth.authStateChanges().listen((fbUser) {
      if (fbUser == null) return; // signed out
      _uid = fbUser.uid;
      _monthId = DateFormat('yyyy-MM').format(DateTime.now());
    });
    // 1) Watch HomeController.user for currency prefs
    ever<UserModel?>(ctrl.user, (u) {
      if (u == null) return;
      final code = u.currencyCode ?? 'USD';
      final sym = u.currencySymbol ?? '\$';
      selectedCurrencyCode.value = code;
      selectedCurrencySymbol.value = sym;
      selectedDecimalDigits.value =
          NumberFormat.currency(name: code).decimalDigits!;
    });

    // 2) Safe‐guard around no‐user‐logged‐in
    final firebaseUser = _auth.currentUser;
    if (firebaseUser == null) {
      // Instead of crashing, send them to login (or just return):
      // Get.offAll(() => LoginPage());
      return;
    }

    // 3) Now it’s safe to grab uid/date
    _uid = firebaseUser.uid;
    _monthId = DateFormat('yyyy-MM').format(DateTime.now());
  }

  Future<void> _loadUser() async {
    final snap = await _db.collection('users').doc(_uid).get();
    if (snap.exists && snap.data() != null) {
      user.value = UserModel.fromMap(snap.data()!);
    }
  }

  void pickCurrency(Currency currency) {
    selectedCurrencyCode.value = currency.code;
    selectedCurrencySymbol.value = currency.symbol;
    selectedDecimalDigits.value = currency.decimalDigits;
  }

  void _seedCategories() {
    categories.assignAll([
      CategoryModel(id: 'food', name: 'Food', iconName: 'fastfood'),
      CategoryModel(
        id: 'transport',
        name: 'Transport',
        iconName: 'directions_car',
      ),
      CategoryModel(
        id: 'entertainment',
        name: 'Entertainment',
        iconName: 'movie',
      ),
      CategoryModel(id: 'utilities', name: 'Utilities', iconName: 'power'),
      CategoryModel(id: 'shopping', name: 'Shopping', iconName: 'shopping_bag'),
      CategoryModel(id: 'other', name: 'Other', iconName: 'category'),
    ]);
  }

  /// Adds a transaction and resets the form on success.
  Future<void> addTransaction() async {
    // Log entry and current UIDs
    final actualUid = FirebaseAuth.instance.currentUser?.uid;
    debugPrint('🛠️ addTransaction() called');
    debugPrint('  • cached _uid: $_uid');
    debugPrint('  • actual FirebaseAuth uid: $actualUid');
    debugPrint('  • monthId: $_monthId');

    final clean = toNumericString(
      amountController.text,
      allowPeriod: true,
      mantissaLength: selectedDecimalDigits.value,
    );
    amount.value = double.parse(clean);
    description.value = titleController.text;
    if (amount.value <= 0) {
      throw Exception('Amount must be greater than zero.');
    }
    final cat = selectedCat.value;
    if (cat == null) {
      throw Exception('Please select a category.');
    }

    isLoading.value = true;
    try {
      final userRef = _db.collection('users').doc(actualUid);
      final summaryRef = userRef.collection('monthlySummaries').doc(_monthId);
      final txsRef = summaryRef.collection('transactions');
      final txId = _db.collection('dummy').doc().id;
      final now = DateTime.now();

      debugPrint(
        '  • Writing to path: users/$actualUid/monthlySummaries/$_monthId/transactions/$txId',
      );

      final currencyCode = selectedCurrencyCode.value;
      final currencySymbol = selectedCurrencySymbol.value;
      final formatter = NumberFormat.currency(
        name: currencyCode,
        symbol: currencySymbol,
      );

      final txData = {
        'id': txId,
        'amount': amount.value,
        'formattedAmount': formatter.format(amount.value),
        'currencyCode': currencyCode,
        'currencySymbol': currencySymbol,
        'categoryId': cat.id,
        'categoryName': cat.name,
        'description': description.value,
        'paymentType': paymentType.value.name,
        'date': selectedDate.value,
      };

      await _db.runTransaction((tx) async {
        final snap = await tx.get(summaryRef);
        if (!snap.exists) {
          debugPrint(
            '  • monthlySummary doc does not exist yet; initializing totals',
          );
          tx.set(summaryRef, {'totalExpense': 0.0, 'totalIncome': 0.0});
        }
        tx.set(txsRef.doc(txId), txData);
        tx.update(summaryRef, {
          'totalExpense': FieldValue.increment(amount.value.abs()),
        });
      });

      debugPrint('✅ Transaction $txId written successfully.');

      // RESET FORM FIELDS
      amountController.clear();
      titleController.clear();
      amount.value = 0.0;
      description.value = '';
      selectedCat.value = null;
      paymentType.value = PaymentType.cash;
      selectedDate.value = DateTime.now();
    } catch (e, st) {
      debugPrint('❌ Error in addTransaction: $e');
      debugPrint(st.toString());
      rethrow;
    } finally {
      isLoading.value = false;
    }
  }

  /// OFFLINE: builds a Txn and writes it into Hive
  Future<void> addTransactionToHive() async {
    // 1) parse & validate
    final clean = toNumericString(
      amountController.text,
      allowPeriod: true,
      mantissaLength: selectedDecimalDigits.value,
    );
    final amt = double.tryParse(clean) ?? 0.0;
    if (amt <= 0) throw Exception('Amount must be > 0');
    final cat = selectedCat.value;
    if (cat == null)    throw Exception('Please select a category');

    // 2) format & build model
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final formatter = NumberFormat.currency(
      name: selectedCurrencyCode.value,
      symbol: selectedCurrencySymbol.value,
    );
    final formatted = formatter.format(amt);

    final txn = Txn(
      id:              id,
      amount:          amt,
      formattedAmount: formatted,
      currencyCode:    selectedCurrencyCode.value,
      currencySymbol:  selectedCurrencySymbol.value,
      categoryId:      cat.id,
      categoryName:    cat.name,
      description:     titleController.text,
      paymentType:     paymentType.value.name,
      date:            selectedDate.value,
    );

    // 3) save to Hive
    await HiveService.addTxn(txn);

    // 4) reset form
    amountController.clear();
    titleController.clear();
    selectedCat.value  = null;
    paymentType.value  = PaymentType.cash;
    selectedDate.value = DateTime.now();
  }

   /// Deletes a txn from Hive and, if signed-in, also from Firestore + updates totals.
  Future<void> deleteTransaction(Txn txn) async {
    // 1) remove locally
    await HiveService.deleteTxn(txn.id);

   
  }
}
