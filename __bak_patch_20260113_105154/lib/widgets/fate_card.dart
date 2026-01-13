import 'package:flutter/material.dart';

class FateCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? pad;
  const FateCard({
    super.key,
    required this.child,
    this.pad,
    this.padding = const EdgeInsets.all(14),
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: pad ?? padding,
        child: child,
      ),
    );
  }
}
