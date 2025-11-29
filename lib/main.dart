import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:fl_chart/fl_chart.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "Expense Tracker",
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Map<String, dynamic>> transactions = [];

  @override
  void initState() {
    super.initState();
    loadData();
  }

  // LOAD DATA
void loadData() async {
  final prefs = await SharedPreferences.getInstance();
  final raw = prefs.getString("transactions");

  if (raw != null) {
    final List decoded = jsonDecode(raw);

    // FIX: Eski kayıtlar için null date/category hatasını engelle
    final fixed = decoded.map((item) {
      return {
        "title": item["title"] ?? "",
        "amount": item["amount"] ?? 0.0,
        "isIncome": item["isIncome"] ?? true,
        "category": item["category"] ?? "Other",
        "date": item["date"] ?? "Unknown",
      };
    }).toList();

    setState(() => transactions = List<Map<String, dynamic>>.from(fixed));
    saveData(); // FIX edilmiş halini diske yaz
  }
}

  // SAVE DATA
  void saveData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("transactions", jsonEncode(transactions));
  }

  @override
  Widget build(BuildContext context) {
    double totalIncome = transactions
        .where((t) => t["isIncome"] == true)
        .fold(0.0, (sum, t) => sum + t["amount"]);

    double totalExpense = transactions
        .where((t) => t["isIncome"] == false)
        .fold(0.0, (sum, t) => sum + t["amount"]);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Expense Tracker"),
        actions: [
          IconButton(
            icon: const Icon(Icons.pie_chart),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ChartPage(transactions: transactions),
                ),
              );
            },
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _summaryCard("Income", totalIncome, Colors.green),
                _summaryCard("Expense", totalExpense, Colors.red),
                _summaryCard("Balance", totalIncome - totalExpense,
                    Colors.blue),
              ],
            ),

            const SizedBox(height: 20),

            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Transactions",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),

            const SizedBox(height: 10),

            Expanded(
              child: ListView.builder(
                itemCount: transactions.length,
                itemBuilder: (context, index) {
                  final t = transactions[index];

                  return Card(
                    child: ListTile(
                      onTap: () => _openEditModal(index),
                      title: Text(t["title"]),
                      subtitle: Text(
                          "${t["category"]} • ${t["date"]} • ${t["isIncome"] ? "Income" : "Expense"}"),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            "${t['amount']} ₺",
                            style: TextStyle(
                              color: t["isIncome"]
                                  ? Colors.green
                                  : Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 10),
                          IconButton(
                            icon:
                                const Icon(Icons.delete, color: Colors.red),
                            onPressed: () {
                              setState(() => transactions.removeAt(index));
                              saveData();
                            },
                          )
                        ],
                      ),
                    ),
                  );
                },
              ),
            )
          ],
        ),
      ),

      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: _openAddModal,
      ),
    );
  }

  // SUMMARY CARD
  Widget _summaryCard(String title, double value, Color color) {
    return Container(
      width: 110,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(title,
              style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Text(
            value.toStringAsFixed(2),
            style: TextStyle(
              color: color,
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          )
        ],
      ),
    );
  }

  // ADD TRANSACTION
  void _openAddModal() {
    TextEditingController titleController = TextEditingController();
    TextEditingController amountController = TextEditingController();
    bool isIncome = true;
    String category = "Other";
    String date = "";

    showModalBottomSheet(
      context: context,
      builder: (context) {
        return StatefulBuilder(builder: (context, setStateModal) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text("Add Transaction",
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),

                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: "Title"),
                ),

                TextField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: "Amount"),
                ),

                DropdownButton<String>(
                  value: category,
                  items: const [
                    DropdownMenuItem(
                        value: "Food", child: Text("Food")),
                    DropdownMenuItem(
                        value: "Rent", child: Text("Rent")),
                    DropdownMenuItem(
                        value: "Salary", child: Text("Salary")),
                    DropdownMenuItem(
                        value: "Shopping", child: Text("Shopping")),
                    DropdownMenuItem(
                        value: "Other", child: Text("Other")),
                  ],
                  onChanged: (v) =>
                      setStateModal(() => category = v!),
                ),

                const SizedBox(height: 8),

                ElevatedButton(
                  onPressed: () async {
                    DateTime? picked = await showDatePicker(
                      context: context,
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                      initialDate: DateTime.now(),
                    );
                    if (picked != null) {
                      setStateModal(() => date =
                          "${picked.year}-${picked.month}-${picked.day}");
                    }
                  },
                  child: Text(date.isEmpty ? "Select Date" : date),
                ),

                Row(
                  children: [
                    Expanded(
                      child: RadioListTile(
                        value: true,
                        groupValue: isIncome,
                        title: const Text("Income"),
                        onChanged: (val) =>
                            setStateModal(() => isIncome = val!),
                      ),
                    ),
                    Expanded(
                      child: RadioListTile(
                        value: false,
                        groupValue: isIncome,
                        title: const Text("Expense"),
                        onChanged: (val) =>
                            setStateModal(() => isIncome = val!),
                      ),
                    ),
                  ],
                ),

                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      transactions.add({
                        "title": titleController.text,
                        "amount": double.tryParse(amountController.text) ?? 0,
                        "category": category,
                        "date": date,
                        "isIncome": isIncome,
                      });
                    });
                    saveData();
                    Navigator.pop(context);
                  },
                  child: const Text("Save"),
                )
              ],
            ),
          );
        });
      },
    );
  }

  // EDIT MODAL
  void _openEditModal(int index) {
    TextEditingController titleController =
        TextEditingController(text: transactions[index]["title"]);

    TextEditingController amountController =
        TextEditingController(text: transactions[index]["amount"].toString());

    bool isIncome = transactions[index]["isIncome"];
    String category = transactions[index]["category"];
    String date = transactions[index]["date"];

    showModalBottomSheet(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModal) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text("Edit Transaction",
                      style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold)),

                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(labelText: "Title"),
                  ),

                  TextField(
                    controller: amountController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: "Amount"),
                  ),

                  DropdownButton<String>(
                    value: category,
                    items: const [
                      DropdownMenuItem(
                          value: "Food", child: Text("Food")),
                      DropdownMenuItem(
                          value: "Rent", child: Text("Rent")),
                      DropdownMenuItem(
                          value: "Salary", child: Text("Salary")),
                      DropdownMenuItem(
                          value: "Shopping", child: Text("Shopping")),
                      DropdownMenuItem(
                          value: "Other", child: Text("Other")),
                    ],
                    onChanged: (v) => setModal(() => category = v!),
                  ),

                  const SizedBox(height: 8),

                  ElevatedButton(
                    onPressed: () async {
                      DateTime? picked = await showDatePicker(
                        context: context,
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                        initialDate: DateTime.now(),
                      );
                      if (picked != null) {
                        setModal(() => date =
                            "${picked.year}-${picked.month}-${picked.day}");
                      }
                    },
                    child: Text(date.isEmpty ? "Select Date" : date),
                  ),

                  Row(
                    children: [
                      Expanded(
                        child: RadioListTile(
                          value: true,
                          groupValue: isIncome,
                          title: const Text("Income"),
                          onChanged: (val) =>
                              setModal(() => isIncome = val!),
                        ),
                      ),
                      Expanded(
                        child: RadioListTile(
                          value: false,
                          groupValue: isIncome,
                          title: const Text("Expense"),
                          onChanged: (val) =>
                              setModal(() => isIncome = val!),
                        ),
                      ),
                    ],
                  ),

                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        transactions[index] = {
                          "title": titleController.text,
                          "amount":
                              double.tryParse(amountController.text) ?? 0,
                          "category": category,
                          "date": date,
                          "isIncome": isIncome,
                        };
                      });
                      saveData();
                      Navigator.pop(context);
                    },
                    child: const Text("Save Changes"),
                  )
                ],
              ),
            );
          },
        );
      },
    );
  }
}

/* ───────────────────────────────────────────────────────────────
   CHART PAGE (Pie chart + Category bars)
──────────────────────────────────────────────────────────────── */
class ChartPage extends StatelessWidget {
  final List<Map<String, dynamic>> transactions;

  const ChartPage({super.key, required this.transactions});

  @override
  Widget build(BuildContext context) {
    double totalIncome = transactions
        .where((t) => t["isIncome"] == true)
        .fold(0.0, (sum, t) => sum + t["amount"]);

    double totalExpense = transactions
        .where((t) => t["isIncome"] == false)
        .fold(0.0, (sum, t) => sum + t["amount"]);

    Map<String, double> categoryTotals = {};

    for (var t in transactions) {
      if (!t["isIncome"]) {
        categoryTotals[t["category"]] =
            (categoryTotals[t["category"]] ?? 0) + t["amount"];
      }
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Charts")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text("Income vs Expense",
                style: TextStyle(
                    fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),

            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sections: [
                    PieChartSectionData(
                      value: totalIncome,
                      color: Colors.green,
                      title: "Income",
                      radius: 60,
                    ),
                    PieChartSectionData(
                      value: totalExpense,
                      color: Colors.red,
                      title: "Expense",
                      radius: 60,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 40),
            const Text("Expenses by Category",
                style: TextStyle(
                    fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),

            ...categoryTotals.entries.map((e) {
              return Column(
                children: [
                  Text(e.key,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  SizedBox(
                    height: 120,
                    child: BarChart(
                      BarChartData(
                        maxY: categoryTotals.values.reduce(
                                (a, b) => a > b ? a : b) +
                            10,
                        barGroups: [
                          BarChartGroupData(
                            x: 0,
                            barRods: [
                              BarChartRodData(
                                toY: e.value,
                                color: Colors.blue,
                                width: 30,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20)
                ],
              );
            }).toList(),
          ],
        ),
      ),
    );
  }
}
