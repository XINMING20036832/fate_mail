\
import 'package:flutter/material.dart';
import 'fate_background.dart';

class FateScaffold extends StatelessWidget {
  final String title;
  final Widget body;
  final List<Widget>? actions;
  final Widget? floatingActionButton;
  final bool centerTitle;

  const FateScaffold({
    super.key,
    required this.title,
    required this.body,
    this.actions,
    this.floatingActionButton,
    this.centerTitle = true,
  });

  @override
  Widget build(BuildContext context) {
    return FateBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: centerTitle,
          title: Text(title),
          actions: actions,
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: body,
          ),
        ),
        floatingActionButton: floatingActionButton,
      ),
    );
  }
}
