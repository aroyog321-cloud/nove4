import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'privacy_policy_screen.dart';

/// Wrap your root app widget with this.
/// Shows PrivacyPolicyScreen only on first install.
/// After acceptance, shows the real app forever.
class TermsGate extends StatefulWidget {
  final Widget child;
  const TermsGate({super.key, required this.child});

  @override
  State<TermsGate> createState() => _TermsGateState();
}

class _TermsGateState extends State<TermsGate> {
  bool? _accepted;

  @override
  void initState() {
    super.initState();
    _checkAccepted();
  }

  Future<void> _checkAccepted() async {
    final prefs = await SharedPreferences.getInstance();
    final accepted = prefs.getBool('terms_accepted') ?? false;
    setState(() => _accepted = accepted);
  }

  @override
  Widget build(BuildContext context) {
    // Still loading
    if (_accepted == null) {
      return const MaterialApp(
        home: Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    // Already accepted — show normal app
    if (_accepted!) return widget.child;

    // First install — show terms
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: PrivacyPolicyScreen(
        onAccepted: () => setState(() => _accepted = true),
      ),
    );
  }
}