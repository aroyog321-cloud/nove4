import 'dart:ui'; // for ImageFilter (glassmorphism)
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/tokens.dart';

// ─────────────────────────────────────────────────────────────────────────────
// OnboardingScreen
// Updated with:
//   • Frosted glass icon circles  (glass3d.dev)
//   • Gradient "Get Started" CTA  (cta.gallery)
//   • Spring page transition       (60fps.design)
// ─────────────────────────────────────────────────────────────────────────────

class OnboardingScreen extends StatefulWidget {
  final VoidCallback onDone;
  const OnboardingScreen({super.key, required this.onDone});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, String>> _pages = [
    {
      'title': 'A Calm Workspace',
      'body': 'NOVE is designed to remove distractions. A minimal, analogue-inspired environment for your best thoughts.',
      'icon': 'drafts',
    },
    {
      'title': 'Context-Aware',
      'body': 'Link your sticky notes to other apps. Your notes automatically float into view exactly when you need them.',
      'icon': 'all_out',
    },
    {
      'title': 'Offline First. Always.',
      'body': 'Your data never leaves your device. No cloud sync, no accounts, complete privacy.',
      'icon': 'lock_outline',
    },
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  IconData _getIcon(String name) {
    switch (name) {
      case 'drafts':       return Icons.drafts_outlined;
      case 'all_out':      return Icons.all_out_rounded;
      case 'lock_outline': return Icons.lock_outline_rounded;
      default:             return Icons.star_border;
    }
  }

  void _handleNext() {
    HapticFeedback.mediumImpact();
    if (_currentPage == _pages.length - 1) {
      widget.onDone();
    } else {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: NoveAnimation.smooth,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NoveColors.bg(context),
      body: SafeArea(
        child: Column(
          children: [
            // ── Page content ───────────────────────────────────────────────
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (idx) {
                  HapticFeedback.lightImpact();
                  setState(() => _currentPage = idx);
                },
                itemCount: _pages.length,
                itemBuilder: (context, index) {
                  final page = _pages[index];
                  return Padding(
                    padding: const EdgeInsets.all(40.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // ── Glass icon circle (glass3d.dev) ───────────────
                        ClipOval(
                          child: BackdropFilter(
                            filter: ImageFilter.blur(
                              sigmaX: NoveBlur.heavy,
                              sigmaY: NoveBlur.heavy,
                            ),
                            child: Container(
                              padding: const EdgeInsets.all(36),
                              decoration: BoxDecoration(
                                color: Theme.of(context).brightness == Brightness.dark
                                    ? Colors.white.withValues(alpha: 0.07)
                                    : Colors.white.withValues(alpha: 0.6),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.25),
                                  width: 1,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: NoveColors.terracotta.withValues(alpha: 0.2),
                                    blurRadius: 30,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: Icon(
                                _getIcon(page['icon']!),
                                size: 64,
                                color: NoveColors.terracotta,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 64),

                        Text(
                          page['title']!,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.lora(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: NoveColors.primaryText(context),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          page['body']!,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.dmSans(
                            fontSize: 16,
                            height: 1.6,
                            color: NoveColors.secondaryText(context),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // ── Bottom controls ────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(32, 0, 32, 48),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Page dot indicators
                  Row(
                    children: List.generate(
                      _pages.length,
                      (index) => AnimatedContainer(
                        duration: NoveAnimation.fast,
                        margin: const EdgeInsets.only(right: 8),
                        height: 8,
                        width: _currentPage == index ? 24 : 8,
                        decoration: BoxDecoration(
                          color: _currentPage == index
                              ? NoveColors.terracotta
                              : NoveColors.warmGray300,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),

                  // ── Gradient CTA button (cta.gallery) ─────────────────
                  GestureDetector(
                    onTap: _handleNext,
                    child: AnimatedContainer(
                      duration: NoveAnimation.micro,
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            NoveColors.terracottaLight,
                            NoveColors.terracottaDark,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: NoveShadows.ctaGlow(),
                      ),
                      child: Text(
                        _currentPage == _pages.length - 1 ? 'Get Started' : 'Next',
                        style: GoogleFonts.dmSans(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
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
      ),
    );
  }
}