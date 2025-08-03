// lib/view/transactions/add_transaction_page.dart
import 'package:currency_picker/currency_picker.dart';
import 'package:hisabi/constants/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hisabi/controller/auth_controller.dart';
import 'package:intl/intl.dart';
import 'package:flutter_multi_formatter/flutter_multi_formatter.dart';

import '../../controller/transaxtion_controller.dart';
import '../../models/category_model.dart';

class AddTransactionPage extends StatelessWidget {
  AddTransactionPage({Key? key}) : super(key: key);

  final Color primary = AppColors.primary;
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.put(AddTransactionController());
        final auth    = Get.find<AuthController>();

    final isGuest = auth.isGuestMode.value;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: Get.back,
        ),
        title: Text(
          'Add Transaction',
          style: TextStyle(
            color: Colors.grey[800],
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: Obx(() {
        // if (ctrl.isLoading.value) {
        //   return const Center(child: CircularProgressIndicator());
        // }
        return Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // — Amount —
              _buildAmountField(ctrl, context),
              const SizedBox(height: 24),

              // — Title/Name —
              _buildTitleField(ctrl),
              const SizedBox(height: 24),

              // — Category —
              _buildCategorySelector(ctrl),
              const SizedBox(height: 24),

              // — Payment Type —
              _buildPaymentTypeSelector(ctrl),
              const SizedBox(height: 24),

              // — Date Picker —
              _buildDatePicker(ctrl, context),
              const SizedBox(height: 32),

              // — Add Button —
              _buildSubmitButton(ctrl,isGuest),
            ],
          ),
        );
      }),
    );
  }

  // inside your AddTransactionPage

  Widget _buildAmountField(
    AddTransactionController ctrl,
    BuildContext context,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'AMOUNT',
          style: TextStyle(
            color: Colors.grey[500],
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Obx(() {
            final digits = ctrl.selectedDecimalDigits.value;
            return TextFormField(
              controller: ctrl.amountController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                MoneyInputFormatter(
                  leadingSymbol: '',
                  mantissaLength: digits,
                  thousandSeparator: ThousandSeparator.Comma,
                ),
              ],
              decoration: InputDecoration(
                // Tappable currency selector
                prefixIcon: InkWell(
                  onTap: () {
                    showCurrencyPicker(
                      context: context,
                      showFlag: true,
                      showCurrencyName: true,
                      showCurrencyCode: true,
                      onSelect: (Currency currency) {
                        ctrl.pickCurrency(currency);
                      },
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.only(left: 16, right: 8, top: 10),
                    child: Text(
                      ctrl.selectedCurrencySymbol.value,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                hintText: '0.${'0' * digits}',
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 18),
              ),
              validator:
                  (v) => (v == null || v.isEmpty) ? 'Enter amount' : null,
              // onSaved: (v) {
              //   final clean = toNumericString(
              //     v!,
              //     allowPeriod: true,
              //     mantissaLength: digits,
              //   );
              //   ctrl.amount.value = double.parse(clean);
              // },
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildTitleField(AddTransactionController ctrl) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'TITLE',
          style: TextStyle(
            color: Colors.grey[500],
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: TextFormField(
            controller: ctrl.titleController,

            decoration: const InputDecoration(
              hintText: 'Enter transaction title',
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 18,
              ),
            ),
            validator: (v) => (v == null || v.isEmpty) ? 'Enter title' : null,
            // onSaved: (v) => ctrl.description.value = v!,
            style: const TextStyle(fontSize: 16),
          ),
        ),
      ],
    );
  }

  Widget _buildCategorySelector(AddTransactionController ctrl) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'CATEGORY',
          style: TextStyle(
            color: Colors.grey[500],
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Obx(() {
            return DropdownButtonFormField<CategoryModel>(
              items:
                  ctrl.categories.map((cat) {
                    return DropdownMenuItem<CategoryModel>(
                      value: cat,
                      child: Container(
                        // padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: primary.withOpacity(0.2),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(cat.iconData, color: primary),
                            ),
                            const SizedBox(width: 16),
                            Text(
                              cat.name,
                              style: const TextStyle(fontSize: 16),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
              value: ctrl.selectedCat.value,
              onChanged: (cat) => ctrl.selectedCat.value = cat,
              decoration: const InputDecoration(
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 8),
              ),
              dropdownColor: Colors.white,
              icon: Icon(Icons.keyboard_arrow_down, color: Colors.grey[700]),
              borderRadius: BorderRadius.circular(16),
              validator: (cat) => cat == null ? 'Pick a category' : null,
            );
          }),
        ),
      ],
    );
  }

  Widget _buildPaymentTypeSelector(AddTransactionController ctrl) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'PAYMENT TYPE',
          style: TextStyle(
            color: Colors.grey[500],
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          height: 56,
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children:
                PaymentType.values.map((type) {
                  final isSelected = ctrl.paymentType.value == type;
                  final label =
                      {
                        PaymentType.cash: 'Cash',
                        PaymentType.card: 'Card',
                      }[type]!;
                  final icon =
                      {
                        PaymentType.cash: Icons.wallet,
                        PaymentType.card: Icons.credit_card,
                      }[type]!;

                  return Expanded(
                    child: InkWell(
                      onTap: () => ctrl.paymentType.value = type,
                      borderRadius: BorderRadius.circular(16),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.white : Colors.transparent,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow:
                              isSelected
                                  ? [
                                    BoxShadow(
                                      color: primary.withOpacity(0.2),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ]
                                  : [],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              icon,
                              color: isSelected ? primary : Colors.grey[600],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              label,
                              style: TextStyle(
                                color: isSelected ? primary : Colors.grey[600],
                                fontWeight:
                                    isSelected
                                        ? FontWeight.w600
                                        : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildDatePicker(AddTransactionController ctrl, BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'DATE & TIME',
          style: TextStyle(
            color: Colors.grey[500],
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Obx(() {
            final dt = ctrl.selectedDate.value;
            return InkWell(
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: dt,
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2100),
                  builder: (context, child) {
                    return Theme(
                      data: Theme.of(context).copyWith(
                        colorScheme: ColorScheme.light(primary: primary),
                      ),
                      child: child!,
                    );
                  },
                );
                if (date == null) return;
                final time = await showTimePicker(
                  context: context,
                  initialTime: TimeOfDay(hour: dt.hour, minute: dt.minute),
                  builder: (context, child) {
                    return Theme(
                      data: Theme.of(context).copyWith(
                        colorScheme: ColorScheme.light(primary: primary),
                      ),
                      child: child!,
                    );
                  },
                );
                ctrl.selectedDate.value = DateTime(
                  date.year,
                  date.month,
                  date.day,
                  time?.hour ?? dt.hour,
                  time?.minute ?? dt.minute,
                );
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      DateFormat('MMM dd, yyyy • hh:mm a').format(dt),
                      style: const TextStyle(fontSize: 16),
                    ),
                    Icon(Icons.calendar_month, color: Colors.grey[600]),
                  ],
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildSubmitButton(AddTransactionController ctrl,bool isGuest) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: primary,
        padding: const EdgeInsets.symmetric(vertical: 18),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 0,
        shadowColor: Colors.transparent,
      ),
  onPressed: () async {
        if (!_formKey.currentState!.validate()) return;
        _formKey.currentState!.save();
        try {
          if (isGuest) {
            // offline-only save
            await ctrl.addTransactionToHive();
            Get.back();
            Get.snackbar('Saved Locally', 'Your transaction was saved offline.');
          } else {
            // goes to Firestore + Hive
            await ctrl.addTransaction();
            Get.back();
            Get.snackbar('Success', 'Transaction added.');
          }
        } catch (e) {
          Get.snackbar('Error', e.toString());
        }
      },
      child:
          ctrl.isLoading.value
              ? SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white,
                ),
              )
              : const Text(
                'ADD TRANSACTION',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.8,
                ),
              ),
    );
  }
}
