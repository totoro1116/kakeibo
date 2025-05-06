import 'package:flutter/material.dart';
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
          ListTile(
            leading: Icon(Icons.color_lens),
            title: Text('テーマ切替'),
            trailing: Switch(
              value: false,
              onChanged: (value) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('テーマ切替機能（まだ未実装）❤')),
                );
              },
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
