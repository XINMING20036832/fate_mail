import 'package:flutter/material.dart';
import 'pages/onboarding_page.dart';
import 'pages/home_page.dart';
import 'pages/wallet_page.dart';
import 'pages/compose_page.dart';
import 'pages/pending_page.dart';
import 'pages/incoming_page.dart';
import 'pages/mailbox_page.dart';
import 'pages/settings_page.dart';
import 'pages/rules_page.dart';
import 'core/fate_theme.dart';

void main() {
  runApp(const FateMailApp());
}

class FateMailApp extends StatelessWidget {
  const FateMailApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: '另一个我',
      theme: FateTheme.light(),
      darkTheme: FateTheme.dark(),
      themeMode: ThemeMode.system,
      routes: {
        '/': (_) => const OnboardingPage(),
        '/home': (_) => const HomePage(),
        '/wallet': (_) => const WalletPage(),
        '/compose': (_) => const ComposePage(),
        '/pending': (_) => const PendingPage(),
        '/incoming': (_) => const IncomingPage(),
        '/mailbox': (_) => const MailboxPage(),
        '/settings': (_) => const SettingsPage(),
        '/rules': (_) => const RulesPage(),
      },
      initialRoute: '/',
    );
  }
}
