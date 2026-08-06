import 'package:flutter/material.dart';

import '../models/expense.dart';
import '../models/recurring_bill.dart';
import '../services/database_service.dart';
import '../services/notification_service.dart';
import '../services/preferences_service.dart';
import '../widgets/money.dart';

class TrackerScreen extends StatefulWidget {
  const TrackerScreen({
    super.key,
    required this.prefs,
  });

  final PreferencesService prefs;

  @override
  State<TrackerScreen> createState() => _TrackerScreenState();
}

class _TrackerScreenState extends State<TrackerScreen> {
  final List<String> categories = const [
    'Rent',
    'EMI',
    'Groceries',
    'Utilities',
    'Transport',
    'Entertainment',
    'Subscriptions',
    'Other',
  ];

  List<Expense> items = [];

  @override
  void initState() {
    super.initState();
    loadExpenses();
  }

  Future<void> loadExpenses() async {
    final expenses =
        await DatabaseService.instance.monthExpenses(DateTime.now());

    if (!mounted) {
      return;
    }

    setState(() {
      items = expenses;
    });
  }

  double get total {
    return items.fold<double>(
      0,
      (sum, expense) => sum + expense.amount,
    );
  }

  Future<void> addExpense() async {
    final amountController = TextEditingController();
    final noteController = TextEditingController();
    var selectedCategory = 'Groceries';

    final shouldSave = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Add expense'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: amountController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Amount',
                        prefixText: '₹',
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: selectedCategory,
                      decoration: const InputDecoration(
                        labelText: 'Category',
                      ),
                      items: categories.map((category) {
                        return DropdownMenuItem<String>(
                          value: category,
                          child: Text(category),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value == null) {
                          return;
                        }

                        setDialogState(() {
                          selectedCategory = value;
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: noteController,
                      decoration: const InputDecoration(
                        labelText: 'Note',
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop(false);
                  },
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop(true);
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );

    final amount = double.tryParse(amountController.text.trim());

    if (shouldSave != true || amount == null || amount <= 0) {
      amountController.dispose();
      noteController.dispose();
      return;
    }

    await DatabaseService.instance.addExpense(
      Expense(
        amount: amount,
        category: selectedCategory,
        date: DateTime.now(),
        note: noteController.text.trim().isEmpty
            ? null
            : noteController.text.trim(),
      ),
    );

    amountController.dispose();
    noteController.dispose();

    await loadExpenses();
  }

  Future<void> setBudget() async {
    final controller = TextEditingController(
      text: widget.prefs.budget > 0
          ? widget.prefs.budget.toStringAsFixed(0)
          : '',
    );

    final shouldSave = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Monthly budget'),
          content: TextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(
              decimal: true,
            ),
            decoration: const InputDecoration(
              labelText: 'Budget amount',
              prefixText: '₹',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    final budget = double.tryParse(controller.text.trim());
    controller.dispose();

    if (shouldSave != true || budget == null || budget < 0) {
      return;
    }

    await widget.prefs.setBudget(budget);

    if (mounted) {
      setState(() {});
    }
  }

  Future<void> addRecurringBill() async {
    final nameController = TextEditingController();
    final amountController = TextEditingController();
    final dueDayController = TextEditingController(text: '5');
    final reminderDaysController = TextEditingController(text: '2');

    final shouldSave = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Recurring bill'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Bill name',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: amountController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Amount',
                    prefixText: '₹',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: dueDayController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Due day of month',
                    hintText: 'For example, 5',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: reminderDaysController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Reminder days before due date',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    final name = nameController.text.trim();
    final amount = double.tryParse(amountController.text.trim());
    final dueDay = int.tryParse(dueDayController.text.trim());
    final reminderDays = int.tryParse(
      reminderDaysController.text.trim(),
    );

    nameController.dispose();
    amountController.dispose();
    dueDayController.dispose();
    reminderDaysController.dispose();

    if (shouldSave != true ||
        name.isEmpty ||
        amount == null ||
        amount <= 0 ||
        dueDay == null ||
        dueDay < 1 ||
        dueDay > 28 ||
        reminderDays == null ||
        reminderDays < 0) {
      return;
    }

    final bill = RecurringBill(
      name: name,
      amount: amount,
      category: 'Other',
      dueDay: dueDay,
      reminderDays: reminderDays,
    );

    final id = await DatabaseService.instance.addBill(bill);

    await NotificationService.instance.schedule(
      RecurringBill(
        id: id,
        name: bill.name,
        amount: bill.amount,
        category: bill.category,
        dueDay: bill.dueDay,
        reminderDays: bill.reminderDays,
      ),
    );

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Bill reminder scheduled monthly'),
      ),
    );
  }

  Future<void> deleteExpense(Expense expense) async {
    if (expense.id == null) {
      return;
    }

    await DatabaseService.instance.deleteExpense(expense.id!);
  }

  @override
  Widget build(BuildContext context) {
    final budget = widget.prefs.budget;
    final progress = budget > 0 ? total / budget : 0.0;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Monthly overview',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            IconButton(
              onPressed: setBudget,
              icon: const Icon(Icons.account_balance),
              tooltip: 'Set budget',
            ),
          ],
        ),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Total spent'),
                const SizedBox(height: 4),
                MoneyText(
                  total,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (budget > 0) ...[
                  const SizedBox(height: 12),
                  LinearProgressIndicator(
                    value: progress.clamp(0.0, 1.0),
                    color: progress > 0.9 ? Colors.red : null,
                  ),
                  const SizedBox(height: 6),
                  Text('${money(total)} of ${money(budget)} budget'),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: addExpense,
          icon: const Icon(Icons.add),
          label: const Text('Add Expense'),
        ),
        OutlinedButton.icon(
          onPressed: addRecurringBill,
          icon: const Icon(Icons.notifications),
          label: const Text('Recurring Bills & Reminders'),
        ),
        const SizedBox(height: 8),
        if (items.isEmpty)
          const Padding(
            padding: EdgeInsets.all(24),
            child: Center(
              child: Text('No expenses recorded this month.'),
            ),
          )
        else
          ...items.map(
            (expense) => Dismissible(
              key: ValueKey(expense.id ?? expense.date.toIso8601String()),
              direction: DismissDirection.endToStart,
              background: Container(
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 20),
                color: Colors.red,
                child: const Icon(
                  Icons.delete,
                  color: Colors.white,
                ),
              ),
              onDismissed: (_) async {
                setState(() {
                  items.remove(expense);
                });

                await deleteExpense(expense);
              },
              child: ListTile(
                leading: const CircleAvatar(
                  child: Icon(Icons.receipt_long),
                ),
                title: Text(expense.category),
                subtitle: expense.note == null || expense.note!.isEmpty
                    ? null
                    : Text(expense.note!),
                trailing: MoneyText(expense.amount),
              ),
            ),
          ),
      ],
    );
  }
}
