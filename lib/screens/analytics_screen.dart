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
                          const SizedBox(height: 24),

                          // Section 1: Total Pengeluaran Card (Last 12 months)
                          Builder(
                            builder: (context) {
                              final now = DateTime.now();
                              final oneYearAgo =
                                  DateTime(now.year - 1, now.month, now.day);
                              final lastYearReceipts = receipts
                                  .where((r) => r.date.isAfter(oneYearAgo))
                                  .toList();
                              final lastYearTotal = lastYearReceipts.fold<num>(
                                  0, (p, r) => p + r.total);

                              return Container(
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      Color(0xFF6366F1),
                                      Color(0xFF8B5CF6),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(24),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF6366F1)
                                          .withValues(alpha: 0.3),
                                      blurRadius: 20,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: Colors.white
                                                .withValues(alpha: 0.2),
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          child: const Icon(
                                            Icons
                                                .account_balance_wallet_rounded,
                                            color: Colors.white,
                                            size: 28,
                                          ),
                                        ),
                                        const Spacer(),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 6,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.white
                                                .withValues(alpha: 0.2),
                                            borderRadius:
                                                BorderRadius.circular(20),
                                          ),
                                          child: Text(
                                            '${lastYearReceipts.length} transaksi',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 20),
                                    Text(
                                      'Total Pengeluaran (12 Bulan Terakhir)',
                                      style: TextStyle(
                                        color:
                                            Colors.white.withValues(alpha: 0.9),
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      '${lastYearReceipts.isNotEmpty ? lastYearReceipts.first.currency : 'IDR'} ${NumberFormat('#,##0', 'id_ID').format(lastYearTotal)}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 36,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: -1,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Section 2: Weekly Bar Chart (Last Year Only)
                  SliverToBoxAdapter(
                    child: _WeeklyBarChartSection(
                      receipts: receipts,
                    ),
                  ),

                  // Section 3: Category Pie Chart (Last Year Only)
                  SliverToBoxAdapter(
                    child: _CategoryPieChartSection(
                      receipts: receipts,
                    ),
                  ),

                  // Section 4: Yearly Expenses List
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

  const _CategoryPieChartSection({
    required this.receipts,
  });

  Map<String, num> _getCategoryTotals() {
    // Get receipts from last 12 months only
    final now = DateTime.now();
    final oneYearAgo = DateTime(now.year - 1, now.month, now.day);

    final Map<String, num> categoryTotals = {};
    for (final receipt in receipts.where((r) => r.date.isAfter(oneYearAgo))) {
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
    final categoryTotals = _getCategoryTotals();

    if (categoryTotals.isEmpty) {
      return const SizedBox.shrink();
    }

    final total = categoryTotals.values.fold<num>(0, (p, v) => p + v);

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
                const Expanded(
                  child: Text(
                    'Kategori Pengeluaran (12 Bulan Terakhir)',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
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
              children:
                  categoryTotals.entries.toList().asMap().entries.map((entry) {
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
                      style:
                          TextStyle(fontSize: 12, color: Colors.grey.shade700),
                    ),
                  ],
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

// Section 3: Monthly Bar Chart
class _WeeklyBarChartSection extends StatelessWidget {
  final List<Receipt> receipts;

  const _WeeklyBarChartSection({
    required this.receipts,
  });

  Map<String, num> _getMonthlyTotals() {
    // Get receipts from last 12 months only
    final now = DateTime.now();
    final oneYearAgo = DateTime(now.year - 1, now.month, now.day);

    final Map<String, num> monthlyTotals = {};
    for (final receipt in receipts.where((r) => r.date.isAfter(oneYearAgo))) {
      final key = DateFormat('MMM yyyy').format(receipt.date);
      monthlyTotals[key] = (monthlyTotals[key] ?? 0) + receipt.total;
    }
    return monthlyTotals;
  }

  @override
  Widget build(BuildContext context) {
    final monthlyTotals = _getMonthlyTotals();

    if (monthlyTotals.isEmpty) {
      return const SizedBox.shrink();
    }

    final maxValue = monthlyTotals.values.reduce((a, b) => a > b ? a : b);

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
                const Expanded(
                  child: Text(
                    'Pengeluaran Per Bulan (12 Bulan Terakhir)',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 220,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: maxValue.toDouble() * 1.2,
                  barTouchData: BarTouchData(
                    enabled: true,
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        final month =
                            monthlyTotals.keys.toList()[group.x.toInt()];
                        return BarTooltipItem(
                          '$month\n${NumberFormat.compact().format(rod.toY)}',
                          const TextStyle(color: Colors.white, fontSize: 12),
                        );
                      },
                    ),
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final months = monthlyTotals.keys.toList();
                          if (value.toInt() >= 0 &&
                              value.toInt() < months.length) {
                            final month = months[value.toInt()];
                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Transform.rotate(
                                angle: -0.5,
                                child: Text(
                                  month.split(' ')[0],
                                  style: TextStyle(
                                    fontSize: 9,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ),
                            );
                          }
                          return const Text('');
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
                  barGroups: monthlyTotals.entries
                      .toList()
                      .asMap()
                      .entries
                      .map((entry) {
                    final index = entry.key;
                    final amount = entry.value.value;
                    return BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: amount.toDouble(),
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFF6366F1),
                              Color(0xFF8B5CF6),
                            ],
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                          ),
                          width: 16,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(4),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
