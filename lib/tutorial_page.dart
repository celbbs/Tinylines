import 'package:flutter/material.dart';
import '/utils/app_theme.dart';
import 'package:tinylines/utils/tutorial_helper.dart';
import '/screens/home_screen.dart';

class TutorialPage extends StatefulWidget {
  const TutorialPage({super.key});

  @override
  State<TutorialPage> createState() => _TutorialPageState();
}

class _TutorialPageState extends State<TutorialPage> {
  final PageController _controller = PageController();
  int _currentPage = 0;

  final List<Map<String, String>> _pages = [
    {
      'title': 'Welcome',
      'subtitle': 'TinyLines helps you journal every day.',
      'image': 'assets/tutorial1.png',
    },
    {
      'title': 'Add Entries',
      'subtitle': 'Create entries for any day you want.',
      'image': 'assets/tutorial2.png',
    },
    {
      'title': 'Attach Photos',
      'subtitle': 'Pick images from your camera roll.',
      'image': 'assets/tutorial3.png',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: PageView.builder(
        controller: _controller,
        itemCount: _pages.length,
        onPageChanged: (index) => setState(() => _currentPage = index),
        itemBuilder: (context, index) {
          final page = _pages[index];
          return Padding(
            padding: EdgeInsets.all(AppTheme.spacingXl),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (page['image'] != null)
                  Image.asset(page['image']!, height: 250),
                SizedBox(height: AppTheme.spacingXl),
                Text(
                  page['title']!,
                  style: Theme.of(context).textTheme.displayMedium,
                ),
                SizedBox(height: AppTheme.spacingM),
                Text(
                  page['subtitle']!,
                  style: Theme.of(context).textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        },
      ),
      bottomSheet: _currentPage == _pages.length - 1
          ? Padding(
              padding: EdgeInsets.all(AppTheme.spacingM),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    await TutorialHelper.setTutorialSeen();
                    if (!mounted) return;
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const HomeScreen(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(
                      horizontal: AppTheme.spacingXxl,
                      vertical: AppTheme.spacingM,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusM),
                    ),
                  ),
                  child: const Text('Get Started'),
                ),
              ),
            )
          : Padding(
              padding: EdgeInsets.all(AppTheme.spacingM),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () => _controller.jumpToPage(_pages.length - 1),
                    child: Text(
                      'Skip',
                      style: TextStyle(color: AppTheme.primaryColor),
                    ),
                  ),
                  Row(
                    children: List.generate(
                      _pages.length,
                      (index) => Container(
                        margin: EdgeInsets.symmetric(horizontal: 4),
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _currentPage == index
                              ? AppTheme.primaryColor
                              : AppTheme.dividerColor,
                        ),
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => _controller.nextPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    ),
                    child: Text(
                      'Next',
                      style: TextStyle(color: AppTheme.primaryColor),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}