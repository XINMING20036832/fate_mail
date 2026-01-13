import 'package:flutter/material.dart';
import 'pages/onboarding_page.dart';
import 'pages/home_page.dart';
import 'pages/compose_page.dart';
import 'pages/wallet_page.dart';
import 'pages/pending_page.dart';
import 'pages/incoming_page.dart';
import 'pages/mailbox_page.dart';
import 'pages/settings_page.dart';
import 'pages/thread_page.dart';

void main() {
  runApp(const FateMailApp());
}

class FateMailApp extends StatelessWidget {
  const FateMailApp({super.key});

  ThemeData _theme() {
    final scheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF6EE7FF),
      brightness: Brightness.dark,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: Colors.transparent,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.black.withOpacity(0.18),
        elevation: 0,
        centerTitle: true,
        titleTextStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
      ),
      cardTheme: CardTheme(
        color: Colors.white.withOpacity(0.06),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white.withOpacity(0.06),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.12)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.12)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: scheme.primary.withOpacity(0.75)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false, // ✅ 去掉右上角 DEBUG 斜条
      title: '另一个我',
      theme: _theme(),
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
        '/thread': (_) => const ThreadPage(),
      },
    );
  }
}
