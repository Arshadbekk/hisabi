import 'package:expo_project/constants/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:currency_picker/currency_picker.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:get/get.dart';
import '../../controller/on_boarding_controller.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({Key? key}) : super(key: key);

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _pageController = PageController();
  final oc = Get.put(OnboardingController());

  int _currentPage = 0;
  Currency? _selectedCurrency;
  final TextEditingController _incomeController = TextEditingController();

  static const Color primary = AppColors.primary;
  static const Color white = Colors.black;
  static const Color backgroundColor = Colors.white;
  static const Color cardColor = AppColors.primary;

  @override
  void dispose() {
    _pageController.dispose();
    _incomeController.dispose();
    super.dispose();
  }

  void _onNext() {
    if (_currentPage < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOutQuint,
      );
    } else {
      // Done onboarding: navigate or whatever
      print('Onboarding complete!');
    }
  }

  /// Wraps each page in a scrollable, keyboard‑aware container
  Widget _pageWrapper(Widget child) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: IntrinsicHeight(child: child),
          ),
        );
      },
    );
  }

  Widget _buildFeatureRow(
    IconData icon,
    String title,
    String subtitle, {
    required Color cardColor, // new
  }) {
    // pick white or black text depending on how dark the cardColor is
    final bool isDarkBackground = cardColor.computeLuminance() < 0.5;
    final Color textColor = isDarkBackground ? Colors.white : Colors.black;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          // icon circle uses the same color at 20% opacity
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: cardColor.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: textColor),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(color: textColor, fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomePage() {
    return Container(
      color: AppColors.white, // deep navy background
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(flex: 2),

          // circular illustration
          Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              image: DecorationImage(
                image: AssetImage('assets/common/on_board.png'),
                fit: BoxFit.cover,
              ),
            ),
          ),

          const SizedBox(height: 10),
          const Text(
            'Welcome to Hisabi',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w800,
              color: AppColors.black, // white text
            ),
          ),

          const SizedBox(height: 16),
          const Text(
            'Take control of your finances with our powerful budgeting tools',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: AppColors.black, // light cyan for body
              height: 1.5,
            ),
          ),

          const Spacer(),

          // Feature rows (you can pass a color if you update _buildFeatureRow signature)
          _buildFeatureRow(
            Icons.pie_chart_rounded,
            'Smart Budgeting',
            'Allocate funds efficiently across spending categories',
            cardColor: AppColors.primary, // true blue icon
          ),
          const SizedBox(height: 24),
          _buildFeatureRow(
            Icons.insights_rounded,
            'Spend Analytics',
            'Visualize expenses with beautiful charts',
            cardColor: AppColors.primary,
          ),
          const SizedBox(height: 24),
          _buildFeatureRow(
            Icons.account_balance_wallet_rounded,
            'Savings Goals',
            'Set and track your financial objectives',
            cardColor: AppColors.primary,
          ),

          const Spacer(flex: 3),

          // Get Started button
          ElevatedButton(
            onPressed: _onNext,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary, // bright sapphire background
              foregroundColor: AppColors.white, // white label
              padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 18),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 8,
              shadowColor: AppColors.accent2.withOpacity(0.5),
            ),
            child: const Text(
              'Get Started',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),

          const Spacer(),
        ],
      ),
    );
  }

  Widget _buildCurrencyPage() {
    return _pageWrapper(
      Container(
        color: backgroundColor,
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            const Spacer(),
            Container(
              width: 200,
              height: 200,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                image: DecorationImage(
                  image: AssetImage('assets/common/currency.png'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 40),
            const Text(
              'Select Currency',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: white,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Choose your primary currency for transactions',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.black, height: 1.5),
            ),
            const SizedBox(height: 40),
            GestureDetector(
              onTap:
                  () => showCurrencyPicker(
                    context: context,
                    showFlag: true,
                    showCurrencyName: true,
                    showSearchField: true,
                    onSelect: (Currency currency) {
                      oc.setCurrency(currency);
                      setState(() => _selectedCurrency = currency);
                    },
                  ),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 20,
                  horizontal: 24,
                ),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                  border: Border.all(
                    color:
                        _selectedCurrency != null
                            ? Colors.white
                            : Colors.transparent,
                    width: 1.5,
                  ),
                ),
                child: Row(
                  children: [
                    if (_selectedCurrency != null)
                      Text(
                        _selectedCurrency!.flag!,
                        style: const TextStyle(
                          fontSize: 24,
                          color: Colors.white,
                        ),
                      )
                    else
                      Icon(
                        Icons.currency_exchange_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        _selectedCurrency?.name ?? 'Select Currency',
                        style: const TextStyle(
                          fontSize: 18,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.arrow_drop_down_rounded,
                      color: Colors.white.withOpacity(0.7),
                      size: 28,
                    ),
                  ],
                ),
              ),
            ),
            const Spacer(flex: 2),
            ElevatedButton(
              onPressed: _selectedCurrency != null ? _onNext : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: primary,
                foregroundColor: backgroundColor,
                padding: const EdgeInsets.symmetric(
                  horizontal: 48,
                  vertical: 18,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 8,
                shadowColor: primary.withOpacity(0.5),
              ),
              child: const Text(
                'Continue',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }

  Widget _buildIncomePage() {
    return _pageWrapper(
      Container(
        color: backgroundColor,
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            const Spacer(),
            Container(
              width: 200,
              height: 200,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                image: DecorationImage(
                  image: AssetImage('assets/common/monthly.png'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 40),
            const Text(
              'Set Your Monthly Income',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: white,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Enter your monthly take-home pay to create a personalized budget',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.black, height: 1.5),
            ),
            const SizedBox(height: 40),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: primary.withOpacity(0.3), width: 1),
              ),
              child: Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: Text(
                      _selectedCurrency?.flag ?? '💵',
                      style: const TextStyle(fontSize: 24, color: Colors.white),
                    ),
                  ),
                  Expanded(
                    child: TextFormField(
                      controller: _incomeController,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(
                        fontSize: 24,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                      decoration: InputDecoration(
                        hintText: '0.00',
                        hintStyle: TextStyle(
                          color: Colors.white.withOpacity(0.4),
                        ),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  Text(
                    _selectedCurrency?.code ?? 'USD',
                    style: const TextStyle(
                      color: primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Enter amount in ${_selectedCurrency?.code ?? 'USD'}',
              style: const TextStyle(color: Colors.black, fontSize: 14),
            ),
            const Spacer(flex: 2),
            ElevatedButton(
              onPressed: () async {
                if (_incomeController.text.isEmpty) return;
                oc.setIncome(_incomeController.text);
                await oc.completeOnboarding();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: primary,
                foregroundColor: backgroundColor,
                padding: const EdgeInsets.symmetric(
                  horizontal: 48,
                  vertical: 18,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 8,
                shadowColor: primary.withOpacity(0.5),
              ),
              child: const Text(
                'Finish Setup',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      _buildWelcomePage(),
      _buildCurrencyPage(),
      _buildIncomePage(),
    ];

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            PageView(
              controller: _pageController,
              onPageChanged: (idx) => setState(() => _currentPage = idx),
              children: pages,
            ),

            // Dot Indicators
            Positioned(
              top: MediaQuery.of(context).padding.top + 20,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  pages.length,
                  (i) => AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: _currentPage == i ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color:
                          _currentPage == i ? primary : white.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
            ),

            Obx(() {
              if (oc.isLoading.value) {
                return Container(
                  color: Colors.black.withOpacity(0.4),
                  child: Center(
                    child: Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 30,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Premium animated loader
                          SpinKitFadingCircle(
                            color: AppColors.primary,
                            size: 50,
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            'Finalizing Setup',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1A1A1A),
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Just a moment...',
                            style: TextStyle(
                              fontSize: 13,
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
