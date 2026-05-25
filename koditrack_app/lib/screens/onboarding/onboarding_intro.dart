import 'package:flutter/material.dart';
import '../../theme/koditrack_theme.dart';

class OnboardingIntro extends StatefulWidget {
  const OnboardingIntro({super.key});

  @override
  State<OnboardingIntro> createState() => _OnboardingIntroState();
}

class _OnboardingIntroState extends State<OnboardingIntro> {
  final _pageController = PageController();
  int _step = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _next() {
    if (_step < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
      setState(() => _step++);
    } else {
      Navigator.pop(context, true); // Done — back to login for signup
    }
  }

  void _skip() {
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final kt = Theme.of(context).extension<KoditrackColors>() ?? KoditrackColors.light;

    return Scaffold(
      backgroundColor: kt.pageBackground,
      body: SafeArea(
        child: Column(
          children: [
            // Progress dots + Skip
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
              child: Row(
                children: [
                  ...List.generate(3, (i) {
                    return Expanded(
                      child: Container(
                        margin: EdgeInsets.only(right: i < 2 ? 6 : 0),
                        height: 4,
                        decoration: BoxDecoration(
                          color: i <= _step ? kt.brandGreen : Colors.grey.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    );
                  }),
                  const SizedBox(width: 16),
                  GestureDetector(
                    onTap: _skip,
                    child: Text('Skip', style: TextStyle(color: kt.brandGreen, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),
            // Pages
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _IntroPage(
                    icon: Icons.apartment,
                    title: 'Manage Properties',
                    body: 'Keep track of all your rental units — apartments, commercial spaces, stalls, and more.',
                    kt: kt,
                  ),
                  _IntroPage(
                    icon: Icons.payments,
                    title: 'Track Payments',
                    body: 'Record M-Pesa, cash, and bank payments. See who has paid and who owes at a glance.',
                    kt: kt,
                  ),
                  _IntroPage(
                    icon: Icons.send,
                    title: 'Send Reminders',
                    body: 'One-tap WhatsApp reminders to nudge tenants. Automated receipts when they pay.',
                    kt: kt,
                  ),
                ],
              ),
            ),
            // Bottom button
            Padding(
              padding: const EdgeInsets.all(24),
              child: FilledButton(
                onPressed: _next,
                style: FilledButton.styleFrom(
                  backgroundColor: kt.brandGreen,
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: Text(
                  _step < 2 ? 'Next' : 'Create Account',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IntroPage extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;
  final KoditrackColors kt;

  const _IntroPage({required this.icon, required this.title, required this.body, required this.kt});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: kt.brandGreenLight,
              borderRadius: BorderRadius.circular(28),
            ),
            child: Icon(icon, size: 48, color: kt.brandGreen),
          ),
          const SizedBox(height: 40),
          Text(title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Text(
            body,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, height: 1.5, color: Colors.grey.shade700),
          ),
        ],
      ),
    );
  }
}