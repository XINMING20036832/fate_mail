\
import 'package:flutter/material.dart';

import 'pages/onboarding_page.dart';
import 'pages/home_page.dart';
import 'pages/compose_page.dart';
import 'pages/wallet_page.dart';
import 'pages/pending_page.dart';
import 'pages/incoming_page.dart';
import 'pages/mailbox_page.dart';
import 'pages/settings_page.dart';
import 'pages/rules_page.dart';
import 'pages/profile_page.dart';

void main() {
  runApp(const AnotherMeApp());
}

class AnotherMeApp extends StatelessWidget {
  const AnotherMeApp({super.key});

  @override
  Widget build(BuildContext context) {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorSchemeSeed: const Color(0xFF8B5CF6),
    );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: '另一个我',
      theme: base.copyWith(
        appBarTheme: const AppBarTheme(
          foregroundColor: Colors.white,
        ),
        scaffoldBackgroundColor: Colors.transparent,
        snackBarTheme: const SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white.withOpacity(0.06),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: Colors.white.withOpacity(0.12)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: Colors.white.withOpacity(0.10)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: Colors.white.withOpacity(0.22)),
          ),
        ),
        cardTheme: CardTheme(
          color: Colors.white.withOpacity(0.06),
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        ),
      ),
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
        '/rules': (_) => const RulesPage(),
        '/profile': (_) => const ProfilePage(),
      },
    );
  }
}
