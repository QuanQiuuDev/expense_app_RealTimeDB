import 'package:flutter/material.dart';
import 'expense_service.dart';

class ExpensePage extends StatefulWidget {
  const ExpensePage({super.key});

  @override
  State<ExpensePage> createState() => _ExpensePageState();
}

class _ExpensePageState extends State<ExpensePage> {
  final service = ExpenseService();

  final TextEditingController amountController = TextEditingController();
  final TextEditingController noteController = TextEditingController();

  String selectedCategory = "Ăn uống";

  final List<String> categories  = [
    "Ăn uống",
    "Đi lại",
    "Mua sắm",
    "Giải trí"
  ];

  void addExpense() {
    if (amountController.text.isEmpty) return;

    int amount = int.tryParse(amountController.text) ?? 0;

    service.addExpense(amount, noteController.text, selectedCategory);

    amountController.clear();
    noteController.clear();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Đã thêm")),
    );
  }

  // ICON
  IconData getIcon(String category) {
    switch (category) {
      case "Ăn uống":
        return Icons.restaurant;
      case "Đi lại":
        return Icons.directions_car;
      case "Mua sắm":
        return Icons.shopping_cart;
      case "Giải trí":
        return Icons.movie;
      default:
        return Icons.money;
    }
  }

  // 
  Color getColor(String category) {
    switch (category) {
      case "Ăn uống":
        return Colors.orange;
      case "Đi lại":
        return Colors.blue;
      case "Mua sắm":
        return Colors.green;
      case "Giải trí":
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  //  SỬA
  void showEditDialog(String key, Map item) {
    final amountEdit = TextEditingController(text: item["amount"].toString());
    final noteEdit = TextEditingController(text: item["note"]);

    String categoryEdit = item["category"];

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Sửa chi tiêu"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: amountEdit,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "Số tiền"),
            ),
            TextField(
              controller: noteEdit,
              decoration: const InputDecoration(labelText: "Ghi chú"),
            ),
            DropdownButtonFormField(
              value: categoryEdit,
              items: categories
                  .map((e) => DropdownMenuItem(
                        value: e,
                        child: Text(e),
                      ))
                  .toList(),
              onChanged: (value) {
                categoryEdit = value.toString();
              },
              decoration: const InputDecoration(labelText: "Danh mục"),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Hủy"),
          ),
          ElevatedButton(
            onPressed: () {
              service.updateExpense(
                key,
                int.parse(amountEdit.text),
                noteEdit.text,
                categoryEdit,
              );
              Navigator.pop(context);
            },
            child: const Text("Lưu"),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dbRef = service.getRef();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Quản lý chi tiêu"),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // INPUT
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: "Số tiền",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),

                TextField(
                  controller: noteController,
                  decoration: const InputDecoration(
                    labelText: "Ghi chú",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),

                DropdownButtonFormField(
                  value: selectedCategory,
                  items: categories
                      .map((e) => DropdownMenuItem(
                            value: e,
                            child: Text(e),
                          ))
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedCategory = value.toString();
                    });
                  },
                  decoration: const InputDecoration(
                    labelText: "Danh mục",
                    border: OutlineInputBorder(),
                  ),
                ),

                const SizedBox(height: 10),

                ElevatedButton(
                  onPressed: addExpense,
                  child: const Text("Thêm"),
                ),
              ],
            ),
          ),

          // LIST
          Expanded(
            child: StreamBuilder(
              stream: dbRef.onValue,
              builder: (context, snapshot) {
                // LOADING
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData ||
                    snapshot.data!.snapshot.value == null) {
                  return const Center(child: Text("Chưa có dữ liệu"));
                }

                final data = Map<String, dynamic>.from(
                    snapshot.data!.snapshot.value as dynamic);

              
                int total = data.values.fold(0, (sum, e) {
                  final item = Map<String, dynamic>.from(e);
                  return sum + (item["amount"] ?? 0) as int;
                });

                final items = data.entries.map((e) {
                  final item = Map<String, dynamic>.from(e.value);

                  int amount = item["amount"] ?? 0;
                  String category = item["category"] ?? "";
                  String note = item["note"] ?? "";

                  return Card(
                    margin:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    elevation: 3,
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: getColor(category),
                        child: Icon(getIcon(category), color: Colors.white),
                      ),
                      title: Text("$category - $amount đ"),
                      subtitle: Text(note),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blue),
                            onPressed: () =>
                                showEditDialog(e.key, item),
                          ),
                          IconButton(
                            icon:
                                const Icon(Icons.delete, color: Colors.red),
                            onPressed: () =>
                                service.deleteExpense(e.key),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList();

                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(10),
                      child: Text(
                        "Tổng: $total đ",
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ),
                    Expanded(child: ListView(children: items)),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}