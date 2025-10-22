import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:smartnote_flutter/providers/receipt_provider.dart';
import 'package:smartnote_flutter/screens/review_screen.dart';

class ConfirmImportScreen extends StatelessWidget {
  const ConfirmImportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final rp = context.watch<ReceiptProvider>();
    final draft = rp.draft;
    final img = rp.draftImage;

    if (draft == null || img == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Konfirmasi')),
        body: const Center(child: Text('Tidak ada data untuk dikonfirmasi')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Konfirmasi Gambar Nota')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.memory(img, height: 360, fit: BoxFit.cover),
            ),
            const SizedBox(height: 16),
            Text('Lanjut Membuat Laporan ?',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),

            // Ringkasan hasil OCR
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (draft.merchant != null)
                      Text('Toko: ${draft.merchant!}',
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                    Text('Tanggal: ${DateFormat('dd/MM/yyyy').format(draft.date)}'),
                    Text('Total: ${draft.currency} ${draft.total}'),
                    const SizedBox(height: 8),
                    const Text('Ringkasan item:'),
                    const SizedBox(height: 6),
                    for (final it in draft.items.take(3))
                      Row(
                        children: [
                          Expanded(child: Text(it.name)),
                          Text('${draft.currency} ${it.price}'),
                        ],
                      ),
                    if (draft.items.length > 3)
                      Text(
                        '+ ${draft.items.length - 3} item lainnya…',
                        style: TextStyle(color: Theme.of(context).hintColor),
                      ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: FilledButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const ReviewScreen()),
                      );
                    },
                    child: const Text('Ya, Buat laporan'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      rp.clearDraft(); // kosongkan draft & gambar
                      Navigator.pop(context); // balik ke Home
                    },
                    child: const Text('Tidak, ganti Gambar'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
