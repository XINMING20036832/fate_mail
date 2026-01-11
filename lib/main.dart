import 'package:flutter/material.dart';
import 'pages/onboarding_page.dart';
import 'pages/home_page.dart';
import 'pages/compose_page.dart';
import 'pages/wallet_page.dart';
import 'pages/pending_page.dart';
import 'pages/incoming_page.dart';
import 'pages/mailbox_page.dart';
import 'pages/settings_page.dart';

void main() {
  runApp(const FateMailApp());
}

class FateMailApp extends StatelessWidget {
  const FateMailApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fate Mail',
      theme: ThemeData(useMaterial3: true),
      initialRoute: '/',
      routes: {
        '/': (_) => const OnboardingPage(),
        '/home': (_) => const HomePage(),
        '/compose': (_) => const ComposePage(),
        '/wallet': (_) => const WalletPage(),
        '/pending': (_) => const PendingPage(),
        '/incoming': (_) => const IncomingPage(),
        '/mailbox': (_) => const MailboxPage(),
        '/settings': (_) => const SettingsPage(),
      },
    );
  }
}
