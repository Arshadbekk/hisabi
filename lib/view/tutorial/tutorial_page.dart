import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../home/home_page.dart';

class TutorialScreen extends StatefulWidget {
  const TutorialScreen({Key? key}) : super(key: key);

  @override
  State<TutorialScreen> createState() => _TutorialScreenState();
}

class _TutorialScreenState extends State<TutorialScreen> {
  final PageController _controller = PageController();
  int _currentPage = 0;

  final List<Map<String, String>> _tutorialPages = [
    {
      'title': 'Track Expenses Easily',
      'description': 'Record your daily spending with just a few taps',
      'icon': '💸',
    },
    {
      'title': 'Set Budget Goals',
      'description':
          'Create budgets for different categories and stay on track',
      'icon': '🎯',
    },
    {
      'title': 'Visualize Your Spending',
      'description': 'See where your money goes with beautiful charts',
      'icon': '📊',
    },
    {
      'title': 'Get Insights',
      'description': 'Understand your spending patterns over time',
      'icon': '🔍',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          PageView.builder(
            controller: _controller,
            itemCount: _tutorialPages.length,
            onPageChanged: (int page) {
              setState(() => _currentPage = page);
            },
            itemBuilder: (_, index) {
              return TutorialPage(
                title: _tutorialPages[index]['title']!,
                description: _tutorialPages[index]['description']!,
                icon: _tutorialPages[index]['icon']!,
              );
            },
          ),
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Column(
              children: [
                // Page indicator
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    _tutorialPages.length,
                    (index) => Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color:
                            _currentPage == index
                                ? Colors.teal
                                : Colors.grey[300],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                // Action button
                SizedBox(
                  width: MediaQuery.of(context).size.width * 0.8,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (_currentPage == _tutorialPages.length - 1) {
                        final prefs = await SharedPreferences.getInstance();
                        await prefs.setBool('firstRun', false);
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (_) =>  HomePage()),
                        );
                      } else {
                        _controller.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeIn,
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      _currentPage == _tutorialPages.length - 1
                          ? 'Get Started'
                          : 'Continue',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class TutorialPage extends StatelessWidget {
  final String title;
  final String description;
  final String icon;

  const TutorialPage({
    Key? key,
    required this.title,
    required this.description,
    required this.icon,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Animated emoji
          AnimatedContainer(
            duration: const Duration(milliseconds: 500),
            transform: Matrix4.identity()..scale(1.5),
            child: Text(icon, style: const TextStyle(fontSize: 64)),
          ),
          const SizedBox(height: 40),
          // Title
          Text(
            title,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          // Description
          Text(
            description,
            style: const TextStyle(
              fontSize: 18,
              color: Colors.grey,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),
          // Feature preview
          if (icon == '💸') _buildTransactionPreview(),
          if (icon == '🎯') _buildBudgetPreview(),
          if (icon == '📊') _buildChartPreview(),
          if (icon == '🔍') _buildInsightsPreview(),
        ],
      ),
    );
  }

  Widget _buildTransactionPreview() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.teal.withOpacity(0.3)),
      ),
      child: const Column(
        children: [
          ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.green,
              child: Icon(Icons.arrow_downward, color: Colors.white),
            ),
            title: Text('Salary'),
            subtitle: Text('Today, 10:00 AM'),
            trailing: Text('\$2,500.00'),
          ),
          Divider(height: 1),
          ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.red,
              child: Icon(Icons.restaurant, color: Colors.white),
            ),
            title: Text('Dinner Out'),
            subtitle: Text('Yesterday, 7:30 PM'),
            trailing: Text('\$45.80'),
          ),
        ],
      ),
    );
  }

  Widget _buildBudgetPreview() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.teal.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Groceries Budget',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          LinearProgressIndicator(
            value: 0.65,
            backgroundColor: Colors.grey[300],
            color: Colors.blue,
            minHeight: 10,
            borderRadius: BorderRadius.circular(5),
          ),
          const SizedBox(height: 8),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [Text('\$325 used'), Text('\$500 total')],
          ),
        ],
      ),
    );
  }

  Widget _buildChartPreview() {
    return SizedBox(
      height: 150,
      child: PieChart(
        PieChartData(
          sections: [
            PieChartSectionData(value: 40, color: Colors.red, radius: 60),
            PieChartSectionData(value: 25, color: Colors.blue, radius: 60),
            PieChartSectionData(value: 20, color: Colors.green, radius: 60),
            PieChartSectionData(value: 15, color: Colors.orange, radius: 60),
          ],
          sectionsSpace: 2,
          centerSpaceRadius: 40,
        ),
      ),
    );
  }

  Widget _buildInsightsPreview() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.teal.withOpacity(0.3)),
      ),
      child: const Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Weekly Spending',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text('↓ 12% vs last week', style: TextStyle(color: Colors.green)),
            ],
          ),
          SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Column(
                children: [
                  Text('\$320', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text('This week'),
                ],
              ),
              Column(
                children: [
                  Text('\$365', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text('Last week'),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
