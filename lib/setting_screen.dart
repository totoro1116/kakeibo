import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:koko_kakeibo/utils/theme_notifier.dart';
import 'category_manager.dart';

class SettingScreen extends StatelessWidget {
  const SettingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('⚙️ 設定'),
      ),
      body: ListView(
        children: [
          ListTile(
            leading: Icon(Icons.category),
            title: Text('カテゴリ管理'),
            trailing: Icon(Icons.arrow_forward_ios),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CategoryManagerScreen(),
                ),
              );
            },
          ),
          Consumer<ThemeNotifier>(
            builder: (context, notifier, _) => ListTile(
              leading: Icon(Icons.color_lens),
              title: Text('ダークモード'),
              trailing: Switch(
                value: notifier.mode == ThemeMode.dark,
                onChanged: (enabled) {
                  notifier.toggle(enabled);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        enabled ? 'ダークモードにしたよ❤' : 'ライトモードに戻したよ❤',
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          ListTile(
            leading: Icon(Icons.backup),
            title: Text('バックアップと復元'),
            trailing: Icon(Icons.arrow_forward_ios),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('バックアップ機能（まだ未実装）❤')),
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.repeat),
            title: Text('固定費の管理'),
            trailing: Icon(Icons.arrow_forward_ios),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('固定費管理（準備中だよ〜❤）')),
              );
            },
          ),
        ],
      ),
    );
  }
}
