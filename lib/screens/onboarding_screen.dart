import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class _OnboardingPage {
  const _OnboardingPage(this.title, this.body, this.icon);
  final String title;
  final String body;
  final IconData icon;
}

const _pages = [
  _OnboardingPage(
    'Find your next\nhidden gem',
    'The family-run kitchen. The tucked-away bookshop. Good things are closer than you think.',
    Icons.travel_explore_outlined,
  ),
  _OnboardingPage(
    'Every place\nhas a story',
    'Meet the people behind your favorite spots. Share moments, not star ratings.',
    Icons.auto_stories_outlined,
  ),
  _OnboardingPage(
    'Small acts.\nLocal impact.',
    'Take a mystery mission, support an independent business, and watch your neighborhood thrive.',
    Icons.volunteer_activism_outlined,
  ),
];

/// Three intro pages, shown once after "Let's explore".
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({
    super.key,
    required this.onFinish,
    required this.onSkip,
  });

  /// Last page's "Find my local legends" button (goes to sign up).
  final VoidCallback onFinish;

  /// "Skip" and "I already have an account" (go to log in).
  final VoidCallback onSkip;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _index = 0;

  bool get _isLast => _index == _pages.length - 1;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _next() {
    if (_isLast) {
      widget.onFinish();
    } else {
      _controller.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        title: const Text(
          'LocalLegends',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17, color: AppColors.ink),
        ),
        actions: [
          TextButton(onPressed: widget.onSkip, child: const Text('Skip')),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          child: Column(
            children: [
              Expanded(
                child: PageView.builder(
                  controller: _controller,
                  itemCount: _pages.length,
                  onPageChanged: (i) => setState(() => _index = i),
                  itemBuilder: (_, i) => _PageBody(page: _pages[i], number: i + 1),
                ),
              ),
              Row(
                children: [
                  for (var i = 0; i < _pages.length; i++)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      margin: const EdgeInsets.only(right: 6),
                      width: i == _index ? 22 : 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: i == _index ? AppColors.terracotta : AppColors.border,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _next,
                child: Text(_isLast ? 'Find my local legends' : 'Next'),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: widget.onSkip,
                child: const Text('I already have an account'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PageBody extends StatelessWidget {
  const _PageBody({required this.page, required this.number});

  final _OnboardingPage page;
  final int number;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stand-in for the illustration. Swap for Image.asset later.
          Container(
            height: 280,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.border),
            ),
            child: Icon(page.icon, size: 72, color: AppColors.terracotta),
          ),
          const SizedBox(height: 20),
          Text(
            '0$number  /  DISCOVER YOUR NEIGHBORHOOD',
            style: const TextStyle(fontSize: 11, letterSpacing: 0.8, color: AppColors.muted),
          ),
          const SizedBox(height: 10),
          Text(
            page.title,
            style: const TextStyle(
              fontSize: 28,
              height: 1.25,
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            page.body,
            style: const TextStyle(fontSize: 15, height: 1.5, color: AppColors.muted),
          ),
        ],
      ),
    );
  }
}
