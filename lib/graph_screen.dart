import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pie_chart/pie_chart.dart';
import 'dart:convert';

class GraphScreen extends StatefulWidget {
  final String selectedMonth;
  final String selectedYear;
  final Function(String) onMonthChanged;
  final Function(String) onYearChanged;

  GraphScreen({
    Key? key,
    required this.selectedMonth,
    required this.selectedYear,
    required this.onMonthChanged,
    required this.onYearChanged,
  }) : super(key: key);

  @override
  State<GraphScreen> createState() => _GraphScreenState();
}

class _GraphScreenState extends State<GraphScreen> {
  Map<String, double> categorySummary = {};
  Map<String, double> subcategorySummary = {};
  bool isLoading = true;
  String? selectedDetailCategory;
  double yearlyTotal = 0.0;

  final List<String> months = List.generate(12, (i) => "${i + 1}月");

  @override
  void initState() {
    super.initState();
    loadAndSummarizeExpenses();
  }

  @override
  void didUpdateWidget(GraphScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedMonth != widget.selectedMonth ||
        oldWidget.selectedYear != widget.selectedYear) {
      loadAndSummarizeExpenses();
    }
  }

  void loadAndSummarizeExpenses() async {
    setState(() {
      isLoading = true;
      subcategorySummary.clear();
      selectedDetailCategory = null;
    });

    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('expenses');
    final Map<String, double> summary = {};
    double total = 0;

    if (data != null) {
      final List<dynamic> expenseList = jsonDecode(data);

      for (var item in expenseList) {
        final date = DateTime.parse(item['date']);
        final yearStr = "${date.year}";
        final monthStr = "${date.month}月";

        final amount = double.tryParse(item['amount'].toString()) ?? 0;

        if (yearStr == widget.selectedYear) {
          total += amount;
        }

        if (yearStr == widget.selectedYear &&
            monthStr == widget.selectedMonth) {
          final category = item['category'];
          summary[category] = (summary[category] ?? 0) + amount;
        }
      }
    }

    setState(() {
      categorySummary = summary;
      yearlyTotal = total;
      isLoading = false;
    });
  }

  void loadSubCategoryData(String categoryName) async {
    setState(() {
      isLoading = true;
    });

    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('expenses');
    final Map<String, double> detailMap = {};

    if (data != null) {
      final List<dynamic> expenseList = jsonDecode(data);

      for (var item in expenseList) {
        final date = DateTime.parse(item['date']);
        final yearStr = "${date.year}";
        final monthStr = "${date.month}月";

        if (yearStr == widget.selectedYear &&
            monthStr == widget.selectedMonth &&
            item['category'] == categoryName) {
          final sub = item['subcategory'] ?? 'その他';
          final amount = double.tryParse(item['amount'].toString()) ?? 0;

          if (detailMap.containsKey(sub)) {
            detailMap[sub] = detailMap[sub]! + amount;
          } else {
            detailMap[sub] = amount;
          }
        }
      }
    }

    setState(() {
      selectedDetailCategory = categoryName;
      subcategorySummary = detailMap;
      isLoading = false;
    });
  }

  void showCategorySelector() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return ListView(
          children: categorySummary.keys.map((category) {
            return ListTile(
              title: Text(category),
              onTap: () {
                Navigator.pop(context);
                loadSubCategoryData(category);
              },
            );
          }).toList(),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final chartData =
        selectedDetailCategory != null ? subcategorySummary : categorySummary;

    final chartTitle = selectedDetailCategory != null
        ? '${widget.selectedMonth} - ${selectedDetailCategory}の内訳'
        : '${widget.selectedMonth}のカテゴリ別支出';

    final total = chartData.values.fold(0.0, (a, b) => a + b);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Text(
              '📊 分析',
              style: TextStyle(fontSize: 20),
            ),
            Expanded(
              // ← スペースを埋めて…
              child: Align(
                // ← 中央に寄せる！
                alignment: Alignment.center,
                child: Text(
                  '📅 年間支出：¥$yearlyTotal',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.pink,
                  ),
                ),
              ),
            ),
          ],
        ),
        actions: [
          if (categorySummary.isNotEmpty)
            IconButton(
              icon: Icon(Icons.segment),
              tooltip: 'カテゴリ詳細切り替え',
              onPressed: showCategorySelector,
            ),
          if (selectedDetailCategory != null)
            IconButton(
              icon: Icon(Icons.close),
              tooltip: 'カテゴリ詳細を閉じる',
              onPressed: () {
                setState(() {
                  selectedDetailCategory = null;
                  subcategorySummary.clear();
                });
              },
            ),
        ],
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        // 年ドロップダウン
                        DropdownButton<String>(
                          value: widget.selectedYear,
                          items: List.generate(10, (index) {
                            final year = (2020 + index).toString();
                            return DropdownMenuItem(
                                value: year, child: Text('$year年'));
                          }),
                          onChanged: (newYear) {
                            if (newYear != null) {
                              widget.onYearChanged(newYear);
                              loadAndSummarizeExpenses();
                            }
                          },
                        ),
                        SizedBox(width: 16),
                        // 月ドロップダウン
                        DropdownButton<String>(
                          value: widget.selectedMonth,
                          items: months.map((month) {
                            return DropdownMenuItem(
                                value: month, child: Text(month));
                          }).toList(),
                          onChanged: (newMonth) {
                            if (newMonth != null) {
                              widget.onMonthChanged(newMonth);
                              loadAndSummarizeExpenses();
                            }
                          },
                        ),
                      ],
                    ),
                    SizedBox(height: 12),
                    Text(
                      chartTitle,
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 16),
                    if (chartData.isEmpty)
                      Text("データがないよ〜❤")
                    else ...[
                      PieChart(
                        dataMap: chartData,
                        chartType: ChartType.disc,
                        chartRadius: MediaQuery.of(context).size.width / 2.5,
                        chartValuesOptions: ChartValuesOptions(
                          showChartValuesInPercentage: true,
                        ),
                      ),
                      SizedBox(height: 24),
                      Text(
                        '内訳詳細：',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      ...chartData.entries.map((entry) {
                        final percent =
                            ((entry.value / total) * 100).toStringAsFixed(1);
                        return Text(
                            '・${entry.key}：¥${entry.value.toInt()}（${percent}%）');
                      }).toList(),
                    ],
                  ],
                ),
              ),
            ),
    );
  }
}
