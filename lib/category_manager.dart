import 'package:flutter/material.dart';
import 'utils/category_utils.dart'; // ← 先ほど作ったユーティリティをimport

class CategoryManagerScreen extends StatefulWidget {
  @override
  _CategoryManagerScreenState createState() => _CategoryManagerScreenState();
}

class _CategoryManagerScreenState extends State<CategoryManagerScreen> {
  Map<String, List<String>> categoryMap = {};
  final TextEditingController parentController = TextEditingController();
  final TextEditingController subController = TextEditingController();
  String? currentParentForSub; // サブカテゴリ追加時の親カテゴリ

  @override
  void initState() {
    super.initState();
    _load(); // 起動時にロード
  }

  Future<void> _load() async {
    final loaded = await loadCategories();
    setState(() {
      categoryMap = loaded;
    });
  }

  Future<void> _save() async {
    await saveCategories(categoryMap);
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('カテゴリーを保存したよ〜❤')));
  }

  void _addParent() {
    final name = parentController.text.trim();
    if (name.isNotEmpty && !categoryMap.containsKey(name)) {
      setState(() {
        categoryMap[name] = [];
        parentController.clear();
      });
      _save();
    }
  }

  /// 指定した親カテゴリにサブカテゴリを追加して保存
  void _addSub(String parent) {
    final name = subController.text.trim();
    if (name.isEmpty) return; // 空なら何もしない
    if (categoryMap[parent]!.contains(name)) return; // 重複もスルー

    setState(() {
      categoryMap[parent]!.add(name); // サブリストに追加
      subController.clear(); // フォームをクリア
    });
    saveCategories(categoryMap); // SharedPreferencesに保存
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('「$parent > $name」を追加したよ❤')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('カテゴリ管理')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: ListView(
          children: [
            Text('■ 親カテゴリを追加', style: TextStyle(fontWeight: FontWeight.bold)),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: parentController,
                    decoration: InputDecoration(labelText: '親カテゴリ名'),
                  ),
                ),
                ElevatedButton(onPressed: _addParent, child: Text('追加')),
              ],
            ),
            Divider(),
            Text('■ 既存カテゴリ一覧', style: TextStyle(fontWeight: FontWeight.bold)),
            ...categoryMap.entries.map((e) {
              final parent = e.key;
              final subs = e.value;
              return ExpansionTile(
                title: Text(parent),
                children: [
                  // サブカテゴリ表示
                  ...subs.map((sub) => ListTile(
                        title: Text(sub),
                        trailing: IconButton(
                          icon: Icon(Icons.delete, color: Colors.red),
                          onPressed: () {
                            setState(() {
                              subs.remove(sub);
                            });
                            _save();
                          },
                        ),
                      )),
                  // サブカテゴリ追加フォーム
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: subController,
                            decoration: InputDecoration(
                              labelText: 'サブカテゴリ名',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () =>
                              _addSub(parent), // ← ここで _addSub を呼ぶよ
                          child: Text('追加'),
                        ),
                      ],
                    ),
                  ),
                  // 親カテゴリ削除
                  ListTile(
                    title: TextButton(
                      onPressed: () {
                        setState(() {
                          categoryMap.remove(parent);
                        });
                        _save();
                      },
                      child:
                          Text('親カテゴリを削除', style: TextStyle(color: Colors.red)),
                    ),
                  ),
                ],
              );
            }).toList(),
          ],
        ),
      ),
    );
  }
}
