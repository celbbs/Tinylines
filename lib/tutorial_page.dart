import 'package:flutter/material.dart';
import '/utils/app_theme.dart';
import 'package:tinylines/utils/tutorial_helper.dart';
import '/screens/home_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';

// full screen tutorial shown to new users on first launch
class TutorialPage extends StatefulWidget {
  final VoidCallback? onFinished;

  const TutorialPage({super.key, this.onFinished});

  @override
  State<TutorialPage> createState() => _TutorialPageState();
}

class _TutorialPageState extends State<TutorialPage> {
  // controls swiping between pages
  final PageController _controller = PageController();

  // tracks which page the user is on
  int _currentPage = 0;

  // content for each tutorial slide
  final List<Map<String, String>> _pages = [
    {
      'title': 'Welcome to TinyLines',
      'subtitle': 'Capture one meaningful moment every day.',
      'image': 'assets/tutorial1.png',
    },
    {
      'title': 'Add an Entry',
      'subtitle':
          'Tap any day on the calendar to write about it, past or present.',
      'image': 'assets/tutorial2.png',
    },
    {
      'title': 'Add a Photo',
      'subtitle': 'Attach a photo to bring your memory to life.',
      'image': 'assets/tutorial3.png',
    },
  ];

  // avoid memory leaks
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

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
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  // builds the bottom nav bar
  // shows "get started" on the last page, skip/next otherwise
  Widget _buildBottomBar() {
    final isLastPage = _currentPage == _pages.length - 1;

    return Container(
      padding: EdgeInsets.all(AppTheme.spacingM),
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor,
        border: Border(
          top: BorderSide(color: AppTheme.dividerColor, width: 0.5),
        ),
      ),
      child: isLastPage
          ? SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  final uid = FirebaseAuth.instance.currentUser?.uid;
                  if (uid != null) {
                    await TutorialHelper.setTutorialSeen(uid);
                  }
                  if (!mounted) return;
                  if (widget.onFinished != null) {
                    widget.onFinished!();
                    return;
                  }
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const HomeScreen()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: AppTheme.spacingM),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusM),
                  ),
                ),
                child: const Text(
                  'Get Started',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // skip jumps to the last page
                TextButton(
                  onPressed: () => _controller.jumpToPage(_pages.length - 1),
                  child: Text(
                    'Skip',
                    style: TextStyle(color: AppTheme.primaryColor),
                  ),
                ),
                // dot indicators showing current page position
                Row(
                  children: List.generate(
                    _pages.length,
                    (index) => AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      // active dot is wider
                      width: _currentPage == index ? 16 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        color: _currentPage == index
                            ? AppTheme.primaryColor
                            : AppTheme.dividerColor,
                      ),
                    ),
                  ),
                ),
                // next animates to the following page
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
    );
  }
}
