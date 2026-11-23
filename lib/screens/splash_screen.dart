import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// First screen of the app (revision 2).
///
/// While the session is still loading it shows only the logo and tagline.
/// For logged-out users it then shows "Let's explore" and
/// "I already have an account". AuthGate decides which.
class SplashScreen extends StatelessWidget {
  const SplashScreen({
    super.key,
    this.onExplore,
    this.onHaveAccount,
  });

  /// Null while loading, so the buttons stay hidden.
  final VoidCallback? onExplore;
  final VoidCallback? onHaveAccount;

  bool get _showActions => onExplore != null;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                children: [
                  const Spacer(),
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.85, end: 1),
                    duration: const Duration(milliseconds: 600),
                    curve: Curves.easeOutBack,
                    builder: (_, scale, child) =>
                        Transform.scale(scale: scale, child: child),
                    child: Container(
                      width: 76,
                      height: 76,
                      decoration: BoxDecoration(
                        color: AppColors.terracotta,
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: const Icon(Icons.location_on_outlined,
                          color: Colors.white, size: 34),
                    ),
                  ),
                  const SizedBox(height: 28),
                  const Text(
                    'LocalLegends',
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Little places.\nExtraordinary stories.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 18, height: 1.45, color: AppColors.ink),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Discover the heart of your neighborhood.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.muted),
                  ),
                  const SizedBox(height: 32),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: _showActions
                        ? Column(
                            key: const ValueKey('actions'),
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              FilledButton(
                                onPressed: onExplore,
                                child: const Text('Let’s explore'),
                              ),
                              const SizedBox(height: 8),
                              TextButton(
                                onPressed: onHaveAccount,
                                child: const Text('I already have an account'),
                              ),
                            ],
                          )
                        : const SizedBox(
                            key: ValueKey('loading'),
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: AppColors.terracotta,
                            ),
                          ),
                  ),
                  const Spacer(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
