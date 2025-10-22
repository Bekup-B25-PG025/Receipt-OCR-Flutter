// lib/screens/history_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:smartnote_flutter/models/receipt.dart';
import 'package:smartnote_flutter/providers/receipt_provider.dart';
import 'package:smartnote_flutter/screens/review_screen.dart';
import 'package:smartnote_flutter/services/local_store_service.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Receipt>>(
      stream: LocalStoreService.streamReceipts(),
      initialData: const <Receipt>[], // <-- penting
      builder: (context, snap) {
        final data = snap.data!;
        if (data.isEmpty) {
          return const Center(child: Text('Belum ada riwayat.'));
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: data.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, i) {
            final r = data[i];
            return ListTile(
              leading: const Icon(Icons.receipt_long),
              title: Text(r.merchant ?? 'Nota'),
              subtitle: Text(
                '${DateFormat('dd/MM/yyyy').format(r.date)} • ${r.currency} ${r.total}',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                context.read<ReceiptProvider>().updateDraft(r);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ReviewScreen()),
                );
              },
            );
          },
        );
      },
    );
  }
}
