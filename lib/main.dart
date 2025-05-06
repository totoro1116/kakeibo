import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'graph_screen.dart';
import 'setting_screen.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ココ家計簿❤',
      theme: ThemeData(
        primarySwatch: Colors.pink,
        useMaterial3: true,
        textTheme: ThemeData.light().textTheme.apply(
              fontFamily: 'NotoSansJP',
            ),
        iconTheme: const IconThemeData(
          color: Colors.black, // アイコン色も指定できるよ
        ),
      ),
      home: HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  String selectedMonth = '';
  String selectedYear = '';

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    selectedMonth = '${now.month}月';
    selectedYear = '${now.year}';
  }

  // 🌀 月が変更されたときに呼ばれる関数
  void updateMonth(String newMonth) {
    setState(() {
      selectedMonth = newMonth;
    });
  }

  // 📅 年が変更されたときに呼ばれる関数
  void updateYear(String newYear) {
    setState(() {
      selectedYear = newYear;
    });
  }

  @override
  Widget build(BuildContext context) {
    // 💡 画面リスト（ここに渡す！）
    final List<Widget> _screens = [
      HomeContent(
        selectedMonth: selectedMonth,
        selectedYear: selectedYear,
        onMonthChanged: updateMonth,
        onYearChanged: updateYear,
      ),
      GraphScreen(
        selectedMonth: selectedMonth,
        selectedYear: selectedYear,
        onMonthChanged: updateMonth,
        onYearChanged: updateYear,
      ),
      SettingScreen(), // 設定画面とか
    ];

    return Scaffold(
      body: SafeArea(
        child: _screens[_currentIndex],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: Colors.pink, // 🩷選ばれてるタブの色
        unselectedItemColor: Colors.grey, // 🩶選ばれてないやつの色
        showUnselectedLabels: true, // 未選択のラベルも表示！
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'ホーム',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: '分析',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: '設定',
          ),
        ],
      ),
    );
  }
}

class MonthlyExpenseCard extends StatelessWidget {
  final String selectedMonth;
  final String selectedYear;
  final Function(String) onChanged;
  final Function(String) onYearChanged;
  final List<Map<String, dynamic>> expenses;

  MonthlyExpenseCard({
    required this.selectedMonth,
    required this.selectedYear,
    required this.onChanged,
    required this.onYearChanged,
    required this.expenses,
  });

  @override
  Widget build(BuildContext context) {
    // 💸 月の合計計算するよ！
    int total = expenses.where((entry) {
      final date = DateTime.parse(entry['date']);
      final monthStr = "${date.month}月";
      return monthStr == selectedMonth;
    }).fold(0, (sum, e) => sum + int.parse(e['amount']));

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      margin: EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '📅 $selectedMonthの支出',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Row(
                  children: [
                    DropdownButton<String>(
                      value: selectedYear,
                      items: List.generate(5, (index) {
                        final year = (2022 + index).toString();
                        return DropdownMenuItem(
                            value: year, child: Text('$year年'));
                      }),
                      onChanged: (newYear) {
                        if (newYear != null) onYearChanged(newYear);
                      },
                    ),
                    SizedBox(width: 8),
                    DropdownButton<String>(
                      value: selectedMonth,
                      items: List.generate(12, (index) {
                        final month = "${index + 1}月";
                        return DropdownMenuItem(
                            value: month, child: Text(month));
                      }),
                      onChanged: (newMonth) {
                        if (newMonth != null) onChanged(newMonth);
                      },
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 12),
            Text(
              '💸 ¥$total',
              style: TextStyle(
                fontSize: 24,
                color: Colors.pink,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class HomeContent extends StatefulWidget {
  final String selectedMonth;
  final String selectedYear;
  final Function(String) onMonthChanged;
  final Function(String) onYearChanged;

  HomeContent({
    required this.selectedMonth,
    required this.selectedYear,
    required this.onMonthChanged,
    required this.onYearChanged,
  });

  @override
  State<HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<HomeContent> {
  final TextEditingController amountController = TextEditingController();
  final Map<String, List<String>> categoryMap = {
    '食費': ['お菓子', '弁当', '外食'],
    '光熱費': ['電気', 'ガス', '水道'],
    '趣味': ['ゲーム', '本', '映画'],
    '交通': ['電車', 'バス', 'タクシー'],
    '雑費': ['文房具', '日用品', 'その他'],
  };

  String selectedParentCategory = '食費';
  String selectedSubCategory = 'お菓子';

  List<Map<String, dynamic>> expenses = [];
  DateTime selectedDate = DateTime.now(); // ← 日付入力のデフォ

  @override
  void initState() {
    super.initState();
    loadExpenses();
  }

  void addExpense() async {
    final amount = amountController.text;
    if (amount.isEmpty) return;

    final entry = {
      'amount': amount,
      'category': selectedParentCategory,
      'subcategory': selectedSubCategory,
      'date': selectedDate.toIso8601String(),
    };

    setState(() {
      expenses.add(entry);
    });

    await saveExpenses();
    amountController.clear();
    selectedDate = DateTime.now(); // ← 入力終わったら今日に戻す
  }

  void deleteExpense(String dateKey) async {
    setState(() {
      expenses.removeWhere((e) => e['date'] == dateKey);
    });

    await saveExpenses();
  }

  Future<void> saveExpenses() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('expenses', jsonEncode(expenses));
  }

  void loadExpenses() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('expenses');

    if (data != null) {
      setState(() {
        expenses = List<Map<String, dynamic>>.from(jsonDecode(data));
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredExpenses = expenses.where((entry) {
      final date = DateTime.parse(entry['date']);
      final yearStr = "${date.year}";
      final monthStr = "${date.month}月";
      return yearStr == widget.selectedYear && monthStr == widget.selectedMonth;
    }).toList();

    return Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MonthlyExpenseCard(
            selectedMonth: widget.selectedMonth,
            selectedYear: widget.selectedYear,
            onChanged: widget.onMonthChanged,
            onYearChanged: widget.onYearChanged,
            expenses: expenses,
          ),
          SizedBox(height: 16),

          // 💸 支出入力フォーム
          Text('支出を記録', style: TextStyle(fontSize: 18)),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(labelText: '金額'),
                ),
              ),
              SizedBox(width: 8),
              // 親カテゴリ選択
              DropdownButton<String>(
                value: selectedParentCategory,
                onChanged: (value) {
                  setState(() {
                    selectedParentCategory = value!;
                    selectedSubCategory =
                        categoryMap[selectedParentCategory]!.first;
                  });
                },
                items: categoryMap.keys.map((parent) {
                  return DropdownMenuItem(
                    value: parent,
                    child: Text(parent),
                  );
                }).toList(),
              ),

              SizedBox(width: 8),

// サブカテゴリ選択
              DropdownButton<String>(
                value: selectedSubCategory,
                onChanged: (value) {
                  setState(() {
                    selectedSubCategory = value!;
                  });
                },
                items: categoryMap[selectedParentCategory]!.map((sub) {
                  return DropdownMenuItem(
                    value: sub,
                    child: Text(sub),
                  );
                }).toList(),
              ),

              SizedBox(width: 8),
              ElevatedButton(
                onPressed: addExpense,
                child: Text('追加'),
              ),
            ],
          ),

          // 🗓 日付選択（デフォルトは今日）
          SizedBox(height: 8),
          Row(
            children: [
              Text(
                  "📅 ${selectedDate.year}/${selectedDate.month}/${selectedDate.day}"),
              SizedBox(width: 8),
              ElevatedButton(
                onPressed: () async {
                  DateTime? picked = await showDatePicker(
                    context: context,
                    initialDate: selectedDate,
                    firstDate: DateTime(2000),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) {
                    setState(() {
                      selectedDate = picked;
                    });
                  }
                },
                child: Text("日付選択"),
              ),
            ],
          ),

          SizedBox(height: 24),
          Text(
            '保存された支出リスト：',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),

          // 📜 リスト表示
          Expanded(
            child: ListView.builder(
              itemCount: filteredExpenses.length,
              itemBuilder: (context, index) {
                final item =
                    filteredExpenses[filteredExpenses.length - 1 - index];
                final date = DateTime.parse(item['date']).toLocal();
                final dateStr =
                    "${date.month}/${date.day} ${date.hour}:${date.minute.toString().padLeft(2, '0')}";

                return Dismissible(
                  key: Key(item['date']),
                  direction: DismissDirection.endToStart,
                  onDismissed: (direction) {
                    deleteExpense(item['date']);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("削除したよ〜❤")),
                    );
                  },
                  background: Container(
                    color: Colors.red,
                    alignment: Alignment.centerRight,
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Icon(Icons.delete, color: Colors.white),
                  ),
                  child: ListTile(
                    title: Text(
                        "¥${item['amount']} - ${item['category']} > ${item['subcategory']}"),
                    subtitle: Text(dateStr),
                    trailing: IconButton(
                      icon: Icon(Icons.delete, color: Colors.red),
                      onPressed: () => deleteExpense(item['date']),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
