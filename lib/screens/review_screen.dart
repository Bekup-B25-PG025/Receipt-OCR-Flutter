import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:smartnote_flutter/models/receipt.dart';
import 'package:smartnote_flutter/providers/receipt_provider.dart';
import 'package:smartnote_flutter/services/local_store_service.dart';

class ReviewScreen extends StatefulWidget {
  const ReviewScreen({super.key});

  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  late TextEditingController _merchant;
  late TextEditingController _currency;
  late TextEditingController _subtotal;
  late TextEditingController _tax;
  late TextEditingController _total;
  late TextEditingController _payment;

  DateTime _date = DateTime.now();
  List<ReceiptItem> _items = [];

  @override
  void initState() {
    super.initState();
    final r = context.read<ReceiptProvider>().draft;
    _merchant  = TextEditingController(text: r?.merchant ?? '');
    _currency  = TextEditingController(text: r?.currency ?? 'IDR');
    _subtotal  = TextEditingController(text: (r?.subtotal ?? 0).toString());
    _tax       = TextEditingController(text: (r?.tax ?? 0).toString());
    _total     = TextEditingController(text: (r?.total ?? 0).toString());
    _payment   = TextEditingController(text: r?.paymentMethod ?? '');
    _date      = r?.date ?? DateTime.now();
    _items     = [...(r?.items ?? [])];
  }

  @override
  void dispose() {
    _merchant.dispose();
    _currency.dispose();
    _subtotal.dispose();
    _tax.dispose();
    _total.dispose();
    _payment.dispose();
    super.dispose();
  }

  num _sumItems() => _items.fold<num>(0, (p, e) => p + e.price);

  Future<void> _save() async {
    final rp  = context.read<ReceiptProvider>();
    final cur = rp.draft;
    if (cur == null) return;

    final updated = cur.copyWith(
      merchant: _merchant.text.trim().isEmpty ? null : _merchant.text.trim(),
      currency: _currency.text.trim().toUpperCase(),
      items: _items,
      subtotal: num.tryParse(_subtotal.text) ?? _sumItems(),
      tax:      num.tryParse(_tax.text) ?? 0,
      total:    num.tryParse(_total.text) ?? (_sumItems() + (num.tryParse(_tax.text) ?? 0)),
      paymentMethod: _payment.text.trim().isEmpty ? null : _payment.text.trim(),
      date: _date,
      status: 'validated',
    );

    if (cur.id == 'draft') {
      // create baru: butuh image bytes
      final img = rp.draftImage;
      if (img == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tidak ada gambar untuk disimpan')),
        );
        return;
      }
      await LocalStoreService.saveNewReceipt(updated, img);
    } else {
      // edit existing
      await LocalStoreService.updateReceipt(updated);
    }

    if (!mounted) return;
    rp.clearDraft();
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tersimpan')));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final r = context.watch<ReceiptProvider>().draft;
    if (r == null) {
      return const Scaffold(body: Center(child: Text('Tidak ada draft')));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Validasi Hasil OCR')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Expanded(
                child: TextField(
                  controller: _merchant,
                  decoration: const InputDecoration(labelText: 'Merchant/Toko'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _currency,
                  decoration: const InputDecoration(labelText: 'Mata Uang'),
                ),
              ),
            ]),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(
                child: TextField(
                  controller: _payment,
                  decoration: const InputDecoration(labelText: 'Metode Pembayaran (opsional)'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                      initialDate: _date,
                    );
                    if (picked != null) setState(() => _date = picked);
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(labelText: 'Tanggal'),
                    child: Text(DateFormat('dd/MM/yyyy').format(_date)),
                  ),
                ),
              ),
            ]),
            const SizedBox(height: 16),
            const Text('Belanja:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),

            ..._items.asMap().entries.map((e) => _ReceiptItemTile(
                  item: e.value,
                  onRemove: () => setState(() => _items.removeAt(e.key)),
                  onChanged: (ni) => setState(() => _items[e.key] = ni),
                )),

            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton.icon(
                onPressed: () => setState(() => _items.add(ReceiptItem(name: 'Item', qty: 1, price: 0))),
                icon: const Icon(Icons.add),
                label: const Text('Tambah Item'),
              ),
            ),

            const SizedBox(height: 16),
            Row(children: [
              Expanded(
                child: TextField(
                  controller: _subtotal,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Subtotal'),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _tax,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Pajak/Service'),
                  onChanged: (_) => setState(() {}),
                ),
              ),
            ]),
            const SizedBox(height: 8),
            TextField(
              controller: _total,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Total'),
            ),

            const SizedBox(height: 12),
            Text('Perhitungan cepat: subtotal(items) = ${_sumItems()}'),
            const SizedBox(height: 20),

            FilledButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.save),
              label: Text(r.id == 'draft' ? 'Simpan ke Database' : 'Update'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReceiptItemTile extends StatelessWidget {
  final ReceiptItem item;
  final VoidCallback? onRemove;
  final ValueChanged<ReceiptItem>? onChanged;
  const _ReceiptItemTile({required this.item, this.onRemove, this.onChanged});

  @override
  Widget build(BuildContext context) {
    final nameCtrl  = TextEditingController(text: item.name);
    final qtyCtrl   = TextEditingController(text: item.qty.toString());
    final priceCtrl = TextEditingController(text: item.price.toString());

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Row(children: [
              Expanded(
                child: TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Nama Item'),
                  onChanged: (v) => onChanged?.call(ReceiptItem(name: v, qty: item.qty, price: item.price)),
                ),
              ),
              IconButton(icon: const Icon(Icons.delete_outline), onPressed: onRemove),
            ]),
            Row(children: [
              Expanded(
                child: TextField(
                  controller: qtyCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Qty'),
                  onChanged: (v) => onChanged?.call(ReceiptItem(
                    name: item.name,
                    qty: num.tryParse(v) ?? 1,
                    price: item.price,
                  )),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: priceCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Harga (total item)'),
                  onChanged: (v) => onChanged?.call(ReceiptItem(
                    name: item.name,
                    qty: item.qty,
                    price: num.tryParse(v) ?? 0,
                  )),
                ),
              ),
            ]),
          ],
        ),
      ),
    );
  }
}
