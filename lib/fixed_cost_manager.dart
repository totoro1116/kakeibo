import 'package:flutter/material.dart';
import 'utils/category_utils.dart'; // カテゴリ読み書き
import 'utils/fixed_cost_utils.dart'; // 固定費読み書き

enum FixedFrequency { monthly, halfYearly, yearly }

class FixedCostManagerScreen extends StatefulWidget {
  const FixedCostManagerScreen({super.key});

  @override
  State<FixedCostManagerScreen> createState() => _FixedCostManagerScreenState();
}

class _FixedCostManagerScreenState extends State<FixedCostManagerScreen> {
  Map<String, List<String>> categoryMap = {};
  String? selectedParent;
  String? selectedChild;
  FixedFrequency frequency = FixedFrequency.monthly;
  int payDay = 1;

  List<Map<String, dynamic>> fixedCosts = [];

  List<int> get selectableDays => List.generate(28, (i) => i + 1);

  final TextEditingController amountController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadCategories();
    _loadFixedCosts();
  }

  Future<void> _loadCategories() async {
    final loaded = await loadCategories();
    setState(() {
      categoryMap = loaded;
      selectedParent = null;
      selectedChild = null;
    });
  }

  Future<void> _loadFixedCosts() async {
    final loaded = await loadFixedCosts();
    setState(() {
      fixedCosts = loaded;
    });
  }

  Future<void> _saveFixedCosts() async {
    await saveFixedCosts(fixedCosts);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('固定費の管理')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 親カテゴリ選択
            DropdownButtonFormField<String>(
              decoration: InputDecoration(labelText: '親カテゴリ'),
              value: selectedParent,
              items: categoryMap.keys
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (val) {
                setState(() {
                  selectedParent = val;
                  selectedChild = null;
                });
              },
            ),
            SizedBox(height: 16),
            // 子カテゴリ選択
            DropdownButtonFormField<String>(
              decoration: InputDecoration(labelText: '子カテゴリ'),
              value: selectedChild,
              items: (selectedParent == null)
                  ? []
                  : categoryMap[selectedParent]!
                      .map((sub) =>
                          DropdownMenuItem(value: sub, child: Text(sub)))
                      .toList(),
              onChanged: (val) {
                setState(() {
                  selectedChild = val;
                });
              },
            ),
            SizedBox(height: 16),
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: '金額（円）'),
            ),
            SizedBox(height: 16),
            // 頻度
            DropdownButtonFormField<FixedFrequency>(
              decoration: InputDecoration(labelText: '頻度'),
              value: frequency,
              items: [
                DropdownMenuItem(
                    value: FixedFrequency.monthly, child: Text('毎月')),
                DropdownMenuItem(
                    value: FixedFrequency.halfYearly, child: Text('半年ごと')),
                DropdownMenuItem(
                    value: FixedFrequency.yearly, child: Text('年ごと')),
              ],
              onChanged: (val) => setState(() {
                if (val != null) frequency = val;
              }),
            ),
            SizedBox(height: 16),
            // 支払日
            DropdownButtonFormField<int>(
              decoration: InputDecoration(labelText: '支払日'),
              value: payDay,
              items: selectableDays
                  .map((d) => DropdownMenuItem(value: d, child: Text('$d日')))
                  .toList(),
              onChanged: (val) => setState(() {
                if (val != null) payDay = val;
              }),
            ),
            SizedBox(height: 24),
            // 追加ボタン
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: (selectedParent != null && selectedChild != null)
                    ? () async {
                        setState(() {
                          fixedCosts.add({
                            'parent': selectedParent!,
                            'child': selectedChild!,
                            'frequency': frequency.toString(),
                            'payDay': payDay,
                            'amount': amountController.text,
                            'nextDate': calculateNextDate(
                                    payDay, frequency.toString())
                                .toIso8601String(),
                          });
                        });
                        await _saveFixedCosts(); // 保存
                        await autoAddFixedCosts();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('固定費として追加したよ❤')),
                        );
                      }
                    : null,
                child: Text('固定費として追加'),
              ),
            ),
            SizedBox(height: 32),
            Text('追加済みの固定費', style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                itemCount: fixedCosts.length,
                itemBuilder: (context, idx) {
                  final cost = fixedCosts[idx];
                  return Card(
                    color: Colors.pink.shade50, // 色付き
                    child: ListTile(
                      title: Text(
                          '${cost['parent']} > ${cost['child']}（¥${cost['amount']}）'),
                      subtitle: Text(
                          '頻度: ${_freqToStr(cost['frequency'])} / 支払日: ${cost['payDay']}日'),
                      trailing: IconButton(
                        icon: Icon(Icons.delete, color: Colors.red),
                        onPressed: () async {
                          setState(() {
                            fixedCosts.removeAt(idx);
                          });
                          await _saveFixedCosts(); // 削除も保存！
                        },
                      ),
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

  String _freqToStr(String f) {
    switch (f) {
      case 'FixedFrequency.monthly':
        return '毎月';
      case 'FixedFrequency.halfYearly':
        return '半年ごと';
      case 'FixedFrequency.yearly':
        return '年ごと';
      default:
        return '';
    }
  }
}
