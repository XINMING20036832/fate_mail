import 'package:flutter/material.dart';
import '../services/local_store.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  Future<void> _reset(BuildContext context) async {
    // For starter only: user can clear app data via system settings.
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('如需重置，请在系统设置里清除应用数据（starter不提供一键清库）。')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('设置')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('最小规则：先同意再读｜一对一｜禁外联｜拉黑举报', style: TextStyle(fontSize: 14)),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: () => _reset(context),
              child: const Text('如何重置（starter）'),
            ),
            const SizedBox(height: 8),
            const Text(
              '上架前你需要准备：隐私政策URL、用户协议、举报处理方式说明。',
              style: TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
