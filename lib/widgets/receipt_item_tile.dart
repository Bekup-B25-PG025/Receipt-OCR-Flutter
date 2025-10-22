import 'package:flutter/material.dart';
import 'package:smartnote_flutter/models/receipt.dart';

class ReceiptItemTile extends StatelessWidget {
  final ReceiptItem item;
  final VoidCallback? onRemove;
  final ValueChanged<ReceiptItem>? onChanged;
  const ReceiptItemTile({super.key, required this.item, this.onRemove, this.onChanged});

  @override
  Widget build(BuildContext context) {
    final nameCtrl = TextEditingController(text: item.name);
    final qtyCtrl = TextEditingController(text: item.qty.toString());
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
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: qtyCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Qty'),
                    onChanged: (v) => onChanged?.call(ReceiptItem(name: item.name, qty: num.tryParse(v) ?? 1, price: item.price)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: priceCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Harga (total item)'),
                    onChanged: (v) => onChanged?.call(ReceiptItem(name: item.name, qty: item.qty, price: num.tryParse(v) ?? 0)),
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
