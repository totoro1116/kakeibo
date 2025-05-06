import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class CategoryManagerScreen extends StatefulWidget {
  const CategoryManagerScreen({super.key});

  @override
  State<CategoryManagerScreen> createState() => _CategoryManagerScreenState();
}

class _CategoryManagerScreenState extends State<CategoryManagerScreen> {
  List<String> categories = [];
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    loadCategories();
  }

  void loadCategories() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getStringList('categories');
    setState(() {
      categories = data ?? ['食費', '光熱費', '趣味', '交通', '雑費'];
    });
  }

  void saveCategories() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setStringList('categories', categories);
  }

  void addCategory() {
    final text = _controller.text.trim();
    if (text.isNotEmpty && !categories.contains(text)) {
      setState(() {
        categories.add(text);
      });
      saveCategories();
      _controller.clear();
    }
  }

  void deleteCategory(String cat) {
    setState(() {
      categories.remove(cat);
    });
    saveCategories();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('📂 カテゴリ管理')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(labelText: '新しいカテゴリ'),
                  ),
                ),
                SizedBox(width: 8),
                ElevatedButton(
                  onPressed: addCategory,
                  child: Text('追加'),
                )
              ],
            ),
            SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  final cat = categories[index];
                  return ListTile(
                    title: Text(cat),
                    trailing: IconButton(
                      icon: Icon(Icons.delete, color: Colors.red),
                      onPressed: () => deleteCategory(cat),
                    ),
                  );
                },
              ),
            )
          ],
        ),
      ),
    );
  }
}
