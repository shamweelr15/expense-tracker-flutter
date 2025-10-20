import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class SpendingPieChart extends StatefulWidget {
  final Map<String, double> categoryData;

  const SpendingPieChart({super.key, required this.categoryData});

  @override
  _SpendingPieChartState createState() => _SpendingPieChartState();
}

class _SpendingPieChartState extends State<SpendingPieChart>
    with SingleTickerProviderStateMixin {
  int? touchedIndex;
  Offset? tapPosition;
  late AnimationController _animationController;
  late Animation<double> _animation;

  // Professional color palette
  final List<Color> categoryColors = [
    const Color(0xFF667eea),
    const Color(0xFFf093fb),
    const Color(0xFF4facfe),
    const Color(0xFFfa709a),
    const Color(0xFFfee140),
    const Color(0xFF30cfd0),
    const Color(0xFFa8edea),
    const Color(0xFFff9a9e),
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutCubic,
      ),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Column(
          children: [
            SizedBox(
              height: 280,
              child: Stack(
                children: [
                  PieChart(
                    PieChartData(
                      sectionsSpace: 3,
                      centerSpaceRadius: 50,
                      pieTouchData: PieTouchData(
                        touchCallback: (event, pieTouchResponse) {
                          setState(() {
                            final section = pieTouchResponse
                                ?.touchedSection
                                ?.touchedSectionIndex;

                            if (!event.isInterestedForInteractions ||
                                pieTouchResponse == null ||
                                section == null ||
                                section < 0) {
                              touchedIndex = null;
                              tapPosition = null;
                              return;
                            }

                            touchedIndex = section;
                            tapPosition = event.localPosition;
                          });
                        },
                      ),
                      sections: widget.categoryData.entries.map((entry) {
                        final index = widget.categoryData.keys
                            .toList()
                            .indexOf(entry.key);
                        final isTouched = index == touchedIndex;
                        final animatedValue = entry.value * _animation.value;

                        return PieChartSectionData(
                          value: animatedValue,
                          radius: isTouched ? 85 : 70,
                          color: categoryColors[index % categoryColors.length],
                          title: isTouched
                              ? "${(entry.value / widget.categoryData.values.reduce((a, b) => a + b) * 100).toStringAsFixed(1)}%"
                              : "",
                          titleStyle: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            shadows: [
                              Shadow(
                                color: Colors.black26,
                                blurRadius: 2,
                              ),
                            ],
                          ),
                          borderSide: BorderSide(
                            color: Colors.white,
                            width: isTouched ? 3 : 2,
                          ),
                          badgeWidget: isTouched
                              ? _buildBadge(
                                  _getCategoryIcon(entry.key),
                                  categoryColors[
                                      index % categoryColors.length],
                                )
                              : null,
                          badgePositionPercentageOffset: 1.3,
                        );
                      }).toList(),
                    ),
                    swapAnimationDuration: const Duration(milliseconds: 400),
                    swapAnimationCurve: Curves.easeInOutCubic,
                  ),
                  // Center text
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          "Total",
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "₹${(widget.categoryData.values.reduce((a, b) => a + b) * _animation.value).toStringAsFixed(2)}",
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF667eea),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Enhanced Legend Section
            _buildLegend(),
          ],
        );
      },
    );
  }

  Widget _buildBadge(IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 8,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Icon(
        icon,
        size: 20,
        color: color,
      ),
    );
  }

  Widget _buildLegend() {
    return Column(
      children: widget.categoryData.entries.map((entry) {
        final index = widget.categoryData.keys.toList().indexOf(entry.key);
        final color = categoryColors[index % categoryColors.length];
        final total = widget.categoryData.values.reduce((a, b) => a + b);
        final percentage = (entry.value / total * 100);

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: index == touchedIndex
                  ? color.withOpacity(0.5)
                  : Colors.transparent,
              width: 2,
            ),
          ),
          child: Row(
            children: [
              // Color indicator with icon
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  _getCategoryIcon(entry.key),
                  color: color,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              // Category name
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.key,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "${percentage.toStringAsFixed(1)}%",
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              // Amount
              Text(
                "₹${(entry.value * _animation.value).toStringAsFixed(2)}",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: color,
                ),
              ),
            ],
          ),
        );
      }).toList(),
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
      case 'others':
        return Icons.more_horiz_rounded;
      default:
        return Icons.category_rounded;
    }
  }
}
