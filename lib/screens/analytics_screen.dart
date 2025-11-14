import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:smartnote_flutter/models/receipt.dart';
import 'package:smartnote_flutter/services/local_store_service.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  int _expandedYearlyLimit = 3;
  int _expandedWeeklyLimit = 3;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF6366F1).withValues(alpha: 0.1),
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: StreamBuilder<List<Receipt>>(
            stream: LocalStoreService.streamReceipts(),
            initialData: const <Receipt>[],
            builder: (context, snapshot) {
              final receipts = snapshot.data ?? [];

              if (receipts.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.analytics_outlined,
                        size: 120,
                        color: const Color(0xFF6366F1).withValues(alpha: 0.4),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Belum ada data analitik',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade800,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Scan nota untuk melihat analitik',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return CustomScrollView(
                slivers: [
                  // Header
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Analytics',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1F2937),
                              letterSpacing: -1,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Analisis pengeluaran Anda',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Section 1: Yearly Expenses (Dropdown)
                  SliverToBoxAdapter(
                    child: _YearlyExpensesSection(
                      receipts: receipts,
                      limit: _expandedYearlyLimit,
                      onLoadMore: () {
                        setState(() {
                          if (_expandedYearlyLimit > 3) {
                            _expandedYearlyLimit = 3;
                          } else {
                            _expandedYearlyLimit += 3;
                          }
                        });
                      },
                    ),
                  ),

                  // Section 2: Category Pie Chart
                  SliverToBoxAdapter(
                    child: _CategoryPieChartSection(
                      receipts: receipts,
                      limit: _expandedYearlyLimit,
                      onLoadMore: () {
                        setState(() {
                          if (_expandedYearlyLimit > 3) {
                            _expandedYearlyLimit = 3;
                          } else {
                            _expandedYearlyLimit += 3;
                          }
                        });
                      },
                    ),
                  ),

                  // Section 3: Weekly Bar Chart
                  SliverToBoxAdapter(
                    child: _WeeklyBarChartSection(
                      receipts: receipts,
                      limit: _expandedWeeklyLimit,
                      onLoadMore: () {
                        setState(() {
                          if (_expandedWeeklyLimit > 3) {
                            _expandedWeeklyLimit = 3;
                          } else {
                            _expandedWeeklyLimit += 3;
                          }
                        });
                      },
                    ),
                  ),

                  const SliverToBoxAdapter(
                    child: SizedBox(height: 100),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

// Section 1: Yearly Expenses Dropdown
class _YearlyExpensesSection extends StatefulWidget {
  final List<Receipt> receipts;
  final int limit;
  final VoidCallback onLoadMore;

  const _YearlyExpensesSection({
    required this.receipts,
    required this.limit,
    required this.onLoadMore,
  });

  @override
  State<_YearlyExpensesSection> createState() => _YearlyExpensesSectionState();
}

class _YearlyExpensesSectionState extends State<_YearlyExpensesSection> {
  final Set<int> _expandedYears = {};

  Map<int, num> _getYearlyTotals() {
    final Map<int, num> yearlyTotals = {};
    for (final receipt in widget.receipts) {
      final year = receipt.date.year;
      yearlyTotals[year] = (yearlyTotals[year] ?? 0) + receipt.total;
    }
    return yearlyTotals;
  }

  @override
  Widget build(BuildContext context) {
    final yearlyTotals = _getYearlyTotals();
    final sortedYears = yearlyTotals.keys.toList()
      ..sort((a, b) => b.compareTo(a));
    final displayedYears = sortedYears.take(widget.limit).toList();
    final money = NumberFormat('#,##0', 'id_ID');
    final currency =
        widget.receipts.isNotEmpty ? widget.receipts.first.currency : 'IDR';

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF6366F1).withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6366F1).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.calendar_today_rounded,
                    color: Color(0xFF6366F1),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Pengeluaran Per Tahun',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...displayedYears.map((year) {
              final total = yearlyTotals[year]!;
              final isExpanded = _expandedYears.contains(year);

              return Column(
                children: [
                  InkWell(
                    onTap: () {
                      setState(() {
                        if (isExpanded) {
                          _expandedYears.remove(year);
                        } else {
                          _expandedYears.add(year);
                        }
                      });
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isExpanded ? Icons.expand_less : Icons.expand_more,
                            color: const Color(0xFF6366F1),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Tahun $year',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF1F2937),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '$currency ${money.format(total)}',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF6366F1),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (isExpanded) ...[
                    const SizedBox(height: 8),
                    _YearDetailList(year: year, receipts: widget.receipts),
                  ],
                  const SizedBox(height: 8),
                ],
              );
            }),
            if (sortedYears.length > widget.limit)
              Center(
                child: TextButton.icon(
                  onPressed: widget.onLoadMore,
                  icon: const Icon(Icons.expand_more_rounded),
                  label: const Text('Muat Lebih Banyak'),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF6366F1),
                  ),
                ),
              ),
            if (widget.limit > 3 && sortedYears.length <= widget.limit)
              Center(
                child: TextButton.icon(
                  onPressed: widget.onLoadMore,
                  icon: const Icon(Icons.expand_less_rounded),
                  label: const Text('Sembunyikan'),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF6366F1),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _YearDetailList extends StatelessWidget {
  final int year;
  final List<Receipt> receipts;

  const _YearDetailList({required this.year, required this.receipts});

  @override
  Widget build(BuildContext context) {
    final yearReceipts = receipts.where((r) => r.date.year == year).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    final money = NumberFormat('#,##0', 'id_ID');

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: yearReceipts.take(10).map((receipt) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Icon(Icons.receipt_rounded,
                    size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    receipt.merchant ?? 'Nota',
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  '${receipt.currency} ${money.format(receipt.total)}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1F2937),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

// Section 2: Category Pie Chart
class _CategoryPieChartSection extends StatelessWidget {
  final List<Receipt> receipts;
  final int limit;
  final VoidCallback onLoadMore;

  const _CategoryPieChartSection({
    required this.receipts,
    required this.limit,
    required this.onLoadMore,
  });

  Map<String, num> _getCategoryTotals(int year) {
    final Map<String, num> categoryTotals = {};
    for (final receipt in receipts.where((r) => r.date.year == year)) {
      final category = receipt.category;
      categoryTotals[category] =
          (categoryTotals[category] ?? 0) + receipt.total;
    }
    return categoryTotals;
  }

  Color _getCategoryColor(int index) {
    final colors = [
      const Color(0xFF6366F1),
      const Color(0xFF8B5CF6),
      const Color(0xFFEC4899),
      const Color(0xFFF59E0B),
      const Color(0xFF10B981),
      const Color(0xFF3B82F6),
      const Color(0xFFEF4444),
      const Color(0xFF14B8A6),
      const Color(0xFF6B7280),
    ];
    return colors[index % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    final years = receipts.map((r) => r.date.year).toSet().toList()
      ..sort((a, b) => b.compareTo(a));
    final displayedYears = years.take(limit).toList();

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF6366F1).withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6366F1).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.pie_chart_rounded,
                    color: Color(0xFF6366F1),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Kategori Per Tahun',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            ...displayedYears.map((year) {
              final categoryTotals = _getCategoryTotals(year);
              final total = categoryTotals.values.fold<num>(0, (p, e) => p + e);

              if (total == 0) return const SizedBox.shrink();

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tahun $year',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 200,
                    child: PieChart(
                      PieChartData(
                        sections: categoryTotals.entries
                            .toList()
                            .asMap()
                            .entries
                            .map((entry) {
                          final index = entry.key;
                          final amount = entry.value.value;
                          final percentage = (amount / total * 100);

                          return PieChartSectionData(
                            value: amount.toDouble(),
                            title: '${percentage.toStringAsFixed(1)}%',
                            color: _getCategoryColor(index),
                            radius: 80,
                            titleStyle: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          );
                        }).toList(),
                        sectionsSpace: 2,
                        centerSpaceRadius: 40,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    children: categoryTotals.entries
                        .toList()
                        .asMap()
                        .entries
                        .map((entry) {
                      final index = entry.key;
                      final category = entry.value.key;
                      return Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: _getCategoryColor(index),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            category,
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey.shade700),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                ],
              );
            }),
            if (years.length > limit)
              Center(
                child: TextButton.icon(
                  onPressed: onLoadMore,
                  icon: const Icon(Icons.expand_more_rounded),
                  label: const Text('Muat Lebih Banyak'),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF6366F1),
                  ),
                ),
              ),
            if (limit > 3 && years.length <= limit)
              Center(
                child: TextButton.icon(
                  onPressed: onLoadMore,
                  icon: const Icon(Icons.expand_less_rounded),
                  label: const Text('Sembunyikan'),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF6366F1),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// Section 3: Weekly Bar Chart
class _WeeklyBarChartSection extends StatelessWidget {
  final List<Receipt> receipts;
  final int limit;
  final VoidCallback onLoadMore;

  const _WeeklyBarChartSection({
    required this.receipts,
    required this.limit,
    required this.onLoadMore,
  });

  Map<int, num> _getWeeklyTotals(int year, int month) {
    final Map<int, num> weeklyTotals = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0};

    for (final receipt in receipts
        .where((r) => r.date.year == year && r.date.month == month)) {
      final week = ((receipt.date.day - 1) ~/ 7) + 1;
      weeklyTotals[week] = (weeklyTotals[week] ?? 0) + receipt.total;
    }

    return weeklyTotals;
  }

  @override
  Widget build(BuildContext context) {
    // Get unique year-month combinations
    final yearMonths = <String, DateTime>{};
    for (final receipt in receipts) {
      final key =
          '${receipt.date.year}-${receipt.date.month.toString().padLeft(2, '0')}';
      yearMonths[key] = DateTime(receipt.date.year, receipt.date.month);
    }

    final sortedYearMonths = yearMonths.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final displayedMonths = sortedYearMonths.take(limit).toList();

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF6366F1).withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6366F1).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.bar_chart_rounded,
                    color: Color(0xFF6366F1),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Pengeluaran Per Minggu',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            ...displayedMonths.map((entry) {
              final date = entry.value;
              final year = date.year;
              final month = date.month;
              final weeklyTotals = _getWeeklyTotals(year, month);
              final maxValue =
                  weeklyTotals.values.reduce((a, b) => a > b ? a : b);

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    DateFormat('MMMM yyyy').format(date),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 200,
                    child: BarChart(
                      BarChartData(
                        alignment: BarChartAlignment.spaceAround,
                        maxY: maxValue.toDouble() * 1.2,
                        barTouchData: BarTouchData(enabled: true),
                        titlesData: FlTitlesData(
                          show: true,
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) {
                                return Text(
                                  'W${value.toInt()}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                );
                              },
                            ),
                          ),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 40,
                              getTitlesWidget: (value, meta) {
                                if (value == 0) return const Text('');
                                return Text(
                                  NumberFormat.compact().format(value),
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey.shade600,
                                  ),
                                );
                              },
                            ),
                          ),
                          topTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false)),
                          rightTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false)),
                        ),
                        gridData: FlGridData(
                          show: true,
                          drawVerticalLine: false,
                          horizontalInterval:
                              maxValue > 0 ? maxValue.toDouble() / 4 : 1,
                        ),
                        borderData: FlBorderData(show: false),
                        barGroups: weeklyTotals.entries.map((entry) {
                          return BarChartGroupData(
                            x: entry.key,
                            barRods: [
                              BarChartRodData(
                                toY: entry.value.toDouble(),
                                color: const Color(0xFF6366F1),
                                width: 20,
                                borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(4)),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              );
            }),
            if (sortedYearMonths.length > limit)
              Center(
                child: TextButton.icon(
                  onPressed: onLoadMore,
                  icon: const Icon(Icons.expand_more_rounded),
                  label: const Text('Muat Lebih Banyak'),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF6366F1),
                  ),
                ),
              ),
            if (limit > 3 && sortedYearMonths.length <= limit)
              Center(
                child: TextButton.icon(
                  onPressed: onLoadMore,
                  icon: const Icon(Icons.expand_less_rounded),
                  label: const Text('Sembunyikan'),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF6366F1),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
