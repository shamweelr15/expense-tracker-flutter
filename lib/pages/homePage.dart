import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:expense_calculator/services/firestroe_service.dart';
import 'package:expense_calculator/utils/theme.dart';
import 'package:expense_calculator/widget/appDrawer.dart';
import 'package:expense_calculator/widget/piechart.dart';
import 'package:expense_calculator/widget/playfullIcons.dart';
import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  final FirestoreService firestoreService = FirestoreService();

  HomePage({super.key});

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return "Good Morning";
    if (hour < 17) return "Good Afternoon";
    return "Good Evening";
  }

  String _getGreetingEmoji() {
    final hour = DateTime.now().hour;
    if (hour < 12) return "☀️";
    if (hour < 17) return "🌤️";
    return "🌙";
  }

  @override
  Widget build(BuildContext context) {
    DateTime now = DateTime.now();
    DateTime startOfMonth = DateTime(now.year, now.month, 1);
    DateTime startOfToday = DateTime(now.year, now.month, now.day);

    // Calculate last month's date range
    DateTime startOfLastMonth = DateTime(now.year, now.month - 1, 1);
    DateTime endOfLastMonth = DateTime(now.year, now.month, 0, 23, 59, 59);

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(70),
        child: AppBar(
          automaticallyImplyLeading: false,
          elevation: 0,
          backgroundColor: Colors.transparent,
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppTheme.primaryPurple, AppTheme.secondaryPurple],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    // Menu Icon with animation
                    Builder(
                      builder: (context) => PlayfulIconButton(
                        icon: Icons.menu_rounded,
                        onPressed: () => Scaffold.of(context).openDrawer(),
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Greeting Text
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                _getGreeting(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                _getGreetingEmoji(),
                                style: const TextStyle(fontSize: 18),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            "Track your expenses smartly",
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.85),
                              fontSize: 13,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Notification Bell
                    PlayfulIconButton(
                      icon: Icons.notifications_rounded,
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("No new notifications"),
                            behavior: SnackBarBehavior.floating,
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: firestoreService.getAllSpendings(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.account_balance_wallet_outlined,
                    size: 80,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "No spendings yet",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Tap the + button to add your first expense",
                    style: TextStyle(color: Colors.grey.shade500),
                  ),
                ],
              ),
            );
          }

          final docs = snapshot.data!.docs;

          // 🔹 Monthly
          final monthlyDocs = docs.where((doc) {
            DateTime date = (doc['date'] as Timestamp).toDate();
            return date.isAfter(startOfMonth) ||
                date.isAtSameMomentAs(startOfMonth);
          }).toList();

          // 🔹 Last Month
          final lastMonthDocs = docs.where((doc) {
            DateTime date = (doc['date'] as Timestamp).toDate();
            return date.isAfter(
                  startOfLastMonth.subtract(const Duration(seconds: 1)),
                ) &&
                date.isBefore(endOfLastMonth.add(const Duration(seconds: 1)));
          }).toList();

          // 🔹 Today
          final todayDocs = docs.where((doc) {
            DateTime date = (doc['date'] as Timestamp).toDate();
            return date.isAfter(startOfToday) ||
                date.isAtSameMomentAs(startOfToday);
          }).toList();

          // Totals
          double monthlyTotal = monthlyDocs.fold(
            0,
            (sum, doc) => sum + (doc['amount'] as num).toDouble(),
          );
          double lastMonthTotal = lastMonthDocs.fold(
            0,
            (sum, doc) => sum + (doc['amount'] as num).toDouble(),
          );
          double todayTotal = todayDocs.fold(
            0,
            (sum, doc) => sum + (doc['amount'] as num).toDouble(),
          );

          // 🔹 Pie chart data
          Map<String, double> categoryData = {};
          for (var doc in todayDocs) {
            String category = doc['category'];
            double amount = (doc['amount'] as num).toDouble();
            categoryData[category] = (categoryData[category] ?? 0) + amount;
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Summary Cards Row
                Row(
                  children: [
                    // Monthly Card
                    Expanded(
                      child: _buildGradientCard(
                        title: "This Month",
                        amount: monthlyTotal,
                        icon: Icons.calendar_month_rounded,
                        gradient: const LinearGradient(
                          colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Today's Card
                    Expanded(
                      child: _buildGradientCard(
                        title: "Today",
                        amount: todayTotal,
                        icon: Icons.today_rounded,
                        gradient: const LinearGradient(
                          colors: [Color(0xFFF093FB), Color(0xFFF5576C)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Last Month Card (Full Width)
                _buildLastMonthCard(lastMonthTotal, monthlyTotal),
                const SizedBox(height: 24),

                // Pie Chart Section
                if (categoryData.isNotEmpty) ...[
                  _buildSectionHeader(
                    "Spending Breakdown",
                    Icons.pie_chart_rounded,
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: SpendingPieChart(categoryData: categoryData),
                  ),
                  const SizedBox(height: 24),
                ],

                // Transactions Section
                _buildSectionHeader(
                  "Today's Transactions",
                  Icons.receipt_long_rounded,
                ),
                const SizedBox(height: 12),

                if (todayDocs.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(
                            Icons.inbox_rounded,
                            size: 48,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "No transactions today",
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  ...todayDocs.map((doc) {
                    var spending = doc.data() as Map<String, dynamic>;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        leading: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: _getCategoryColor(
                              spending['category'],
                            ).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            _getCategoryIcon(spending['category']),
                            color: _getCategoryColor(spending['category']),
                            size: 24,
                          ),
                        ),
                        title: Text(
                          spending['category'],
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                        subtitle: Text(
                          spending['note'] ?? "No description",
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              "₹${spending['amount']}",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Color(0xFF667eea),
                              ),
                            ),
                            Text(
                              (spending['date'] as Timestamp)
                                  .toDate()
                                  .toString()
                                  .split(' ')[1]
                                  .substring(0, 5),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                const SizedBox(height: 80), // Space for FAB
              ],
            ),
          );
        },
      ),

      // 🔹 Floating Action Button → open bottom sheet
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF667eea),
        onPressed: () => _showAddSpendingBottomSheet(context),
        icon: const Icon(Icons.add),
        label: const Text("Add Expense"),
        elevation: 4,
      ),
      drawer: AppDrawer(),
    );
  }

  Widget _buildGradientCard({
    required String title,
    required double amount,
    required IconData icon,
    required Gradient gradient,
  }) {
    return _AnimatedGradientCard(
      title: title,
      amount: amount,
      icon: icon,
      gradient: gradient,
    );
  }

  Widget _buildLastMonthCard(double lastMonthTotal, double currentMonthTotal) {
    double difference = currentMonthTotal - lastMonthTotal;
    double percentageChange = lastMonthTotal != 0
        ? (difference / lastMonthTotal * 100)
        : 0;
    bool isIncrease = difference > 0;

    return _AnimatedLastMonthCard(
      lastMonthTotal: lastMonthTotal,
      percentageChange: percentageChange,
      isIncrease: isIncrease,
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF667eea), size: 24),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2d3436),
          ),
        ),
      ],
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'food':
        return Icons.restaurant_rounded;
      case 'transport':
        return Icons.directions_car_rounded;
      case 'shopping':
        return Icons.shopping_bag_rounded;
      case 'bills':
        return Icons.receipt_rounded;
      default:
        return Icons.category_rounded;
    }
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'food':
        return const Color(0xFFFF6B6B);
      case 'transport':
        return const Color(0xFF4ECDC4);
      case 'shopping':
        return const Color(0xFFFFBE0B);
      case 'bills':
        return const Color(0xFF8338EC);
      default:
        return const Color(0xFF667eea);
    }
  }

  // 🔹 Reused bottom sheet function from SpendingList
  void _showAddSpendingBottomSheet(BuildContext context) {
    final _formKey = GlobalKey<FormState>();
    final TextEditingController amountController = TextEditingController();
    final TextEditingController noteController = TextEditingController();
    String? selectedCategory;
    DateTime selectedDate = DateTime.now();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 16,
                left: 20,
                right: 20,
                top: 24,
              ),
              child: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header with icon
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  AppTheme.primaryPurple,
                                  AppTheme.secondaryPurple,
                                ],
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.add_card_rounded,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 16),
                          const Text(
                            "Add New Expense",
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Amount Field
                      TextFormField(
                        controller: amountController,
                        keyboardType: TextInputType.number,
                        autofocus: true,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                        decoration: InputDecoration(
                          labelText: "Amount",
                          hintText: "0.00",
                          prefixText: "₹ ",
                          prefixStyle: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryPurple,
                          ),
                          prefixIcon: const Icon(Icons.currency_rupee_rounded),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                        ),
                        validator: (value) => value == null || value.isEmpty
                            ? "Please enter amount"
                            : null,
                      ),
                      const SizedBox(height: 16),

                      // Category Selector
                      const Text(
                        "Category",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _buildCategoryChip(
                            "Food",
                            Icons.restaurant_rounded,
                            selectedCategory,
                            (cat) {
                              setState(() => selectedCategory = cat);
                            },
                          ),
                          _buildCategoryChip(
                            "Transport",
                            Icons.directions_car_rounded,
                            selectedCategory,
                            (cat) {
                              setState(() => selectedCategory = cat);
                            },
                          ),
                          _buildCategoryChip(
                            "Shopping",
                            Icons.shopping_bag_rounded,
                            selectedCategory,
                            (cat) {
                              setState(() => selectedCategory = cat);
                            },
                          ),
                          _buildCategoryChip(
                            "Bills",
                            Icons.receipt_rounded,
                            selectedCategory,
                            (cat) {
                              setState(() => selectedCategory = cat);
                            },
                          ),
                          _buildCategoryChip(
                            "Others",
                            Icons.more_horiz_rounded,
                            selectedCategory,
                            (cat) {
                              setState(() => selectedCategory = cat);
                            },
                          ),
                        ],
                      ),
                      if (selectedCategory == null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            "Please select a category",
                            style: TextStyle(
                              color: Colors.red.shade700,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      const SizedBox(height: 16),

                      // Note Field
                      TextFormField(
                        controller: noteController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          labelText: "Note (Optional)",
                          hintText: "Add a description...",
                          prefixIcon: const Icon(Icons.note_rounded),
                          alignLabelWithHint: true,
                          filled: true,
                          fillColor: Colors.grey.shade50,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Date Picker
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: ListTile(
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryPurple.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.calendar_today_rounded,
                              color: AppTheme.primaryPurple,
                              size: 20,
                            ),
                          ),
                          title: const Text(
                            "Date",
                            style: TextStyle(
                              fontSize: 14,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                          subtitle: Text(
                            "${selectedDate.day}/${selectedDate.month}/${selectedDate.year}",
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          trailing: const Icon(Icons.edit_rounded, size: 20),
                          onTap: () async {
                            DateTime? pickedDate = await showDatePicker(
                              context: context,
                              initialDate: selectedDate,
                              firstDate: DateTime(2000),
                              lastDate: DateTime.now(),
                            );
                            if (pickedDate != null) {
                              setState(() => selectedDate = pickedDate);
                            }
                          },
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Action Buttons
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(context),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                              ),
                              child: const Text("Cancel"),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: ElevatedButton(
                              onPressed: () async {
                                if (_formKey.currentState!.validate() &&
                                    selectedCategory != null) {
                                  await firestoreService.addSpending(
                                    amount: double.parse(amountController.text),
                                    category: selectedCategory!,
                                    note: noteController.text,
                                    date: selectedDate,
                                  );
                                  if (context.mounted) {
                                    Navigator.pop(context);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          "Expense added successfully!",
                                        ),
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                  }
                                } else if (selectedCategory == null) {
                                  setState(() {});
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                              ),
                              child: const Text("Add Expense"),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildCategoryChip(
    String label,
    IconData icon,
    String? selectedCategory,
    Function(String) onTap,
  ) {
    final isSelected = selectedCategory == label;
    return GestureDetector(
      onTap: () => onTap(label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryPurple : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppTheme.primaryPurple : Colors.grey.shade300,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected ? Colors.white : AppTheme.textSecondary,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : AppTheme.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Animated Gradient Card Widget
class _AnimatedGradientCard extends StatefulWidget {
  final String title;
  final double amount;
  final IconData icon;
  final Gradient gradient;

  const _AnimatedGradientCard({
    required this.title,
    required this.amount,
    required this.icon,
    required this.gradient,
  });

  @override
  State<_AnimatedGradientCard> createState() => _AnimatedGradientCardState();
}

class _AnimatedGradientCardState extends State<_AnimatedGradientCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 0.05,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) => _controller.reverse(),
      onTapCancel: () => _controller.reverse(),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Transform.rotate(
              angle: _rotationAnimation.value,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: widget.gradient,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    // Animated Circle Shapes
                    Positioned(
                      right: -20,
                      top: -20,
                      child: Transform.rotate(
                        angle: _controller.value * 3.14,
                        child: Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.1),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      left: -10,
                      bottom: -10,
                      child: Transform.rotate(
                        angle: -_controller.value * 3.14,
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.08),
                          ),
                        ),
                      ),
                    ),
                    // Content
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          widget.icon,
                          color: Colors.white.withOpacity(0.9),
                          size: 28,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          widget.title,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "₹${widget.amount.toStringAsFixed(2)}",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// Animated Last Month Card Widget
class _AnimatedLastMonthCard extends StatefulWidget {
  final double lastMonthTotal;
  final double percentageChange;
  final bool isIncrease;

  const _AnimatedLastMonthCard({
    required this.lastMonthTotal,
    required this.percentageChange,
    required this.isIncrease,
  });

  @override
  State<_AnimatedLastMonthCard> createState() => _AnimatedLastMonthCardState();
}

class _AnimatedLastMonthCardState extends State<_AnimatedLastMonthCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.97,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) => _controller.reverse(),
      onTapCancel: () => _controller.reverse(),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF4facfe), Color(0xFF00f2fe)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // Animated Background Shapes
                  Positioned(
                    right: 20,
                    top: 10,
                    child: Transform.rotate(
                      angle: _controller.value * 6.28,
                      child: Icon(
                        Icons.trending_up_rounded,
                        size: 80,
                        color: Colors.white.withOpacity(0.08),
                      ),
                    ),
                  ),
                  Positioned(
                    left: -20,
                    bottom: -20,
                    child: Transform.scale(
                      scale: 1 + (_controller.value * 0.2),
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.05),
                        ),
                      ),
                    ),
                  ),
                  // Content
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.calendar_today_rounded,
                                color: Colors.white.withOpacity(0.9),
                                size: 24,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                "Last Month",
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          if (widget.lastMonthTotal > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: widget.isIncrease
                                    ? Colors.red.withOpacity(0.2)
                                    : Colors.green.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    widget.isIncrease
                                        ? Icons.arrow_upward
                                        : Icons.arrow_downward,
                                    color: Colors.white,
                                    size: 14,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    "${widget.percentageChange.abs().toStringAsFixed(1)}%",
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        "₹${widget.lastMonthTotal.toStringAsFixed(2)}",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.lastMonthTotal > 0
                            ? (widget.isIncrease
                                  ? "You spent more this month"
                                  : "You saved money this month!")
                            : "No data from last month",
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.85),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
