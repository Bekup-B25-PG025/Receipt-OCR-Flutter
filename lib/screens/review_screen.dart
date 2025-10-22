// lib/screens/review_screen.dart
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
    _merchant = TextEditingController(text: r?.merchant ?? '');
    _currency = TextEditingController(text: r?.currency ?? 'IDR');
    _subtotal = TextEditingController(text: (r?.subtotal ?? 0).toString());
    _tax = TextEditingController(text: (r?.tax ?? 0).toString());
    _total = TextEditingController(text: (r?.total ?? 0).toString());
    _payment = TextEditingController(text: r?.paymentMethod ?? '');
    _date = r?.date ?? DateTime.now();
    _items = [...(r?.items ?? [])];

    // Hitung ulang total ketika pajak berubah
    _tax.addListener(_recalcTotals);
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

  void _recalcTotals() {
    final subtotalVal = _sumItems();
    final taxVal = num.tryParse(_tax.text) ?? 0;
    final totalVal = subtotalVal + taxVal;

    // Update text tanpa mengubah selection/focus user
    _subtotal.value = TextEditingValue(
      text: subtotalVal.toString(),
      selection: _subtotal.selection,
    );
    _total.value = TextEditingValue(
      text: totalVal.toString(),
      selection: _total.selection,
    );
    setState(() {}); // untuk update tampilan "Perhitungan cepat"
  }

  Future<void> _save() async {
    final rp = context.read<ReceiptProvider>();
    final cur = rp.draft;
    if (cur == null) return;

    final updated = cur.copyWith(
      merchant: _merchant.text.trim().isEmpty ? null : _merchant.text.trim(),
      currency: _currency.text.trim().toUpperCase(),
      items: _items,
      subtotal: _sumItems(),
      tax: num.tryParse(_tax.text) ?? 0,
      total: (_sumItems() + (num.tryParse(_tax.text) ?? 0)),
      paymentMethod: _payment.text.trim().isEmpty ? null : _payment.text.trim(),
      date: _date,
      status: 'validated',
    );

    if (cur.id == 'draft') {
      final img = rp.draftImage;
      if (img == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tidak ada gambar untuk disimpan')),
        );
        return;
      }
      await LocalStoreService.saveNewReceipt(updated, img);
    } else {
      await LocalStoreService.updateReceipt(updated);
    }

    if (!mounted) return;
    rp.clearDraft();
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Tersimpan')));
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
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(labelText: 'Mata Uang'),
                ),
              ),
            ]),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(
                child: TextField(
                  controller: _payment,
                  decoration: const InputDecoration(
                    labelText: 'Metode Pembayaran (opsional)',
                  ),
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
                    decoration:
                        const InputDecoration(labelText: 'Tanggal'),
                    child: Text(DateFormat('dd/MM/yyyy').format(_date)),
                  ),
                ),
              ),
            ]),
            const SizedBox(height: 16),
            const Text('Belanja:',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),

            // daftar item
            ..._items.asMap().entries.map(
              (e) => _ReceiptItemTile(
                key: ValueKey('item-${e.key}'),
                item: e.value,
                onRemove: () {
                  setState(() => _items.removeAt(e.key));
                  _recalcTotals();
                },
                onChanged: (ni) {
                  setState(() => _items[e.key] = ni);
                  _recalcTotals();
                },
              ),
            ),

            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton.icon(
                onPressed: () {
                  setState(() => _items
                      .add(ReceiptItem(name: 'Item', qty: 1, price: 0)));
                  _recalcTotals();
                },
                icon: const Icon(Icons.add),
                label: const Text('Tambah Item'),
              ),
            ),

            const SizedBox(height: 16),
            Row(children: [
              Expanded(
                child: TextField(
                  controller: _subtotal,
                  readOnly: true,
                  decoration:
                      const InputDecoration(labelText: 'Subtotal (auto)'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _tax,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration:
                      const InputDecoration(labelText: 'Pajak/Service'),
                ),
              ),
            ]),
            const SizedBox(height: 8),
            TextField(
              controller: _total,
              readOnly: true,
              decoration: const InputDecoration(labelText: 'Total (auto)'),
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

/// Tile item yang **stateful** agar controller & fokus tidak hilang saat rebuild.
class _ReceiptItemTile extends StatefulWidget {
  final ReceiptItem item;
  final VoidCallback? onRemove;
  final ValueChanged<ReceiptItem>? onChanged;
  const _ReceiptItemTile({
    super.key,
    required this.item,
    this.onRemove,
    this.onChanged,
  });

  @override
  State<_ReceiptItemTile> createState() => _ReceiptItemTileState();
}

class _ReceiptItemTileState extends State<_ReceiptItemTile> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _qtyCtrl;
  late final TextEditingController _priceCtrl;

  final _nameFocus = FocusNode();
  final _qtyFocus = FocusNode();
  final _priceFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.item.name);
    _qtyCtrl = TextEditingController(text: widget.item.qty.toString());
    _priceCtrl = TextEditingController(text: widget.item.price.toString());
  }

  @override
  void didUpdateWidget(covariant _ReceiptItemTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Sinkronkan text jika nilai dari parent berubah dan fieldnya TIDAK sedang fokus.
    if (!_nameFocus.hasFocus && oldWidget.item.name != widget.item.name) {
      _nameCtrl.text = widget.item.name;
    }
    if (!_qtyFocus.hasFocus && oldWidget.item.qty != widget.item.qty) {
      _qtyCtrl.text = widget.item.qty.toString();
    }
    if (!_priceFocus.hasFocus && oldWidget.item.price != widget.item.price) {
      _priceCtrl.text = widget.item.price.toString();
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _qtyCtrl.dispose();
    _priceCtrl.dispose();
    _nameFocus.dispose();
    _qtyFocus.dispose();
    _priceFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Row(children: [
              Expanded(
                child: TextField(
                  controller: _nameCtrl,
                  focusNode: _nameFocus,
                  decoration:
                      const InputDecoration(labelText: 'Nama Item'),
                  onChanged: (v) => widget.onChanged?.call(
                    ReceiptItem(
                      name: v,
                      qty: num.tryParse(_qtyCtrl.text) ?? 1,
                      price: num.tryParse(_priceCtrl.text) ?? 0,
                    ),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: widget.onRemove,
              ),
            ]),
            Row(children: [
              Expanded(
                child: TextField(
                  controller: _qtyCtrl,
                  focusNode: _qtyFocus,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Qty'),
                  onChanged: (v) => widget.onChanged?.call(
                    ReceiptItem(
                      name: _nameCtrl.text,
                      qty: num.tryParse(v) ?? 1,
                      price: num.tryParse(_priceCtrl.text) ?? 0,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _priceCtrl,
                  focusNode: _priceFocus,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                      labelText: 'Harga (total item)'),
                  onChanged: (v) => widget.onChanged?.call(
                    ReceiptItem(
                      name: _nameCtrl.text,
                      qty: num.tryParse(_qtyCtrl.text) ?? 1,
                      price: num.tryParse(v) ?? 0,
                    ),
                  ),
                ),
              ),
            ]),
          ],
        ),
      ),
    );
  }
}
