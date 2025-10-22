// lib/screens/report_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:smartnote_flutter/models/receipt.dart';
import 'package:smartnote_flutter/services/local_store_service.dart';

class ReportScreen extends StatelessWidget {
  const ReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Receipt>>(
      stream: LocalStoreService.streamReceipts(),
      initialData: const <Receipt>[],
      builder: (context, snap) {
        final source = snap.data ?? const <Receipt>[];

        if (source.isEmpty) {
          return const Center(child: Text('Belum ada data laporan.'));
        }

        // SALIN dulu baru sort (jangan sort list unmodifiable dari stream).
        final all = List<Receipt>.of(source)
          ..sort((a, b) => b.date.compareTo(a.date));

        // Kelompokkan per bulan.
        final byMonth = <String, List<Receipt>>{};
        for (final r in all) {
          final key = DateFormat('MM / yyyy')
              .format(DateTime(r.date.year, r.date.month));
          (byMonth[key] ??= <Receipt>[]).add(r);
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              'Laporan Smart Note',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            for (final entry in byMonth.entries) ...[
              _MonthSection(monthLabel: entry.key, receipts: entry.value),
              const SizedBox(height: 12),
            ],
          ],
        );
      },
    );
  }
}

class _MonthSection extends StatelessWidget {
  final String monthLabel;
  final List<Receipt> receipts;
  const _MonthSection({required this.monthLabel, required this.receipts});

  @override
  Widget build(BuildContext context) {
    final currency = receipts.isNotEmpty ? receipts.first.currency : 'IDR';
    final money = NumberFormat('#,##0', 'id_ID');
    final dateFmt = DateFormat('dd/MM');
    final total = receipts.fold<num>(0, (p, r) => p + r.total);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Total Pengeluaran Bulan $monthLabel',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),

            // Detail transaksi per bulan
            for (final r in receipts) ...[
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Transaksi ${r.merchant ?? "Nota"} • ${dateFmt.format(r.date)}',
                    ),
                  ),
                  Text('$currency ${money.format(r.total)}'),
                ],
              ),
              const SizedBox(height: 6),
            ],

            const Divider(),
            Row(
              children: [
                const Expanded(child: Text('Total')),
                Text(
                  '$currency ${money.format(total)}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
