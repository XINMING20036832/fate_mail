\
import 'package:flutter/material.dart';
import '../services/local_store.dart';
import '../widgets/fate_scaffold.dart';
import '../widgets/fate_card.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  Future<void> _confirmClear(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('清空本机数据？'),
        content: const Text('将清除命运坐标、邮票、信件与请求卡（仅本机）。'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('取消')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('清空')),
        ],
      ),
    );
    if (ok == true) {
      await LocalStore.clearAll();
      if (context.mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/', (r) => false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return FateScaffold(
      title: '设置',
      body: ListView(
        children: [
          FateCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('账号与资料', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 10),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.person),
                  title: const Text('命运坐标 / 邮箱'),
                  subtitle: const Text('24小时内各可改 1 次'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.pushNamed(context, '/profile'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          FateCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('规则与隐私', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 10),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.auto_awesome),
                  title: const Text('查看完整规则'),
                  subtitle: const Text('为什么会让人想写信？怎么投递？如何保护隐私？'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.pushNamed(context, '/rules'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          FateCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('开发 / 维护', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 10),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.delete_forever),
                  title: const Text('清空本机数据'),
                  subtitle: const Text('只影响本机，方便你测试'),
                  onTap: () => _confirmClear(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
