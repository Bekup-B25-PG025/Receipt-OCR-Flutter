import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:smartnote_flutter/models/receipt.dart';
import 'package:smartnote_flutter/providers/receipt_provider.dart';

class BatchReviewScreen extends StatefulWidget {
  final Receipt receipt;
  final Uint8List image;
  final int index;

  const BatchReviewScreen({
    super.key,
    required this.receipt,
    required this.image,
    required this.index,
  });

  @override
  State<BatchReviewScreen> createState() => _BatchReviewScreenState();
}

class _BatchReviewScreenState extends State<BatchReviewScreen> {
  late TextEditingController _merchant;
  late TextEditingController _currency;
  late TextEditingController _subtotal;
  late TextEditingController _tax;
  late TextEditingController _total;
  late TextEditingController _payment;

  DateTime _date = DateTime.now();
  List<ReceiptItem> _items = [];
  String _category = 'Lainnya';

  static const List<String> _categories = [
    'Kebutuhan Bisnis',
    'Makanan',
    'Transportasi',
    'Kesehatan',
    'Pendidikan',
    'Kebutuhan Harian',
    'Kebutuhan Bulanan',
    'Belanja',
    'Lainnya',
  ];

  @override
  void initState() {
    super.initState();
    _merchant = TextEditingController(text: widget.receipt.merchant ?? '');
    _currency = TextEditingController(text: widget.receipt.currency);
    _subtotal = TextEditingController(text: widget.receipt.subtotal.toString());
    _tax = TextEditingController(text: widget.receipt.tax.toString());
    _total = TextEditingController(text: widget.receipt.total.toString());
    _payment = TextEditingController(text: widget.receipt.paymentMethod ?? '');
    _date = widget.receipt.date;
    _items = [...widget.receipt.items];
    _category = widget.receipt.category;

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

    _subtotal.value = TextEditingValue(
      text: subtotalVal.toString(),
      selection: _subtotal.selection,
    );
    _total.value = TextEditingValue(
      text: totalVal.toString(),
      selection: _total.selection,
    );
    setState(() {});
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Kebutuhan Bisnis':
        return Icons.business_center_rounded;
      case 'Makanan':
        return Icons.restaurant_rounded;
      case 'Transportasi':
        return Icons.directions_car_rounded;
      case 'Kesehatan':
        return Icons.medical_services_rounded;
      case 'Pendidikan':
        return Icons.school_rounded;
      case 'Kebutuhan Harian':
        return Icons.shopping_basket_rounded;
      case 'Kebutuhan Bulanan':
        return Icons.calendar_month_rounded;
      case 'Belanja':
        return Icons.shopping_bag_rounded;
      default:
        return Icons.category_rounded;
    }
  }

  void _save() {
    final updated = widget.receipt.copyWith(
      merchant: _merchant.text.trim().isEmpty ? null : _merchant.text.trim(),
      currency: _currency.text.trim().toUpperCase(),
      items: _items,
      subtotal: _sumItems(),
      tax: num.tryParse(_tax.text) ?? 0,
      total: (_sumItems() + (num.tryParse(_tax.text) ?? 0)),
      paymentMethod: _payment.text.trim().isEmpty ? null : _payment.text.trim(),
      date: _date,
      category: _category,
    );

    // Update in provider
    context.read<ReceiptProvider>().updateBatchDraft(widget.index, updated);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 12),
            Text('Perubahan tersimpan!'),
          ],
        ),
        backgroundColor: const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 1),
      ),
    );

    // Go back to batch confirm screen
    Navigator.pop(context);
  }

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
          child: Column(
            children: [
              // Custom AppBar
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back_rounded),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white,
                        padding: const EdgeInsets.all(12),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Edit Nota',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1F2937),
                            ),
                          ),
                          Text(
                            'Nota #${widget.index + 1}',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Image Preview
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.memory(
                            widget.image,
                            height: 200,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Info Umum Card
                      _SectionCard(
                        title: 'Informasi Umum',
                        icon: Icons.info_outline_rounded,
                        children: [
                          _ModernTextField(
                            controller: _merchant,
                            label: 'Nama Toko/Merchant',
                            icon: Icons.store_rounded,
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: _ModernTextField(
                                  controller: _currency,
                                  label: 'Mata Uang',
                                  icon: Icons.attach_money_rounded,
                                  textCapitalization:
                                      TextCapitalization.characters,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _ModernTextField(
                                  controller: _payment,
                                  label: 'Metode Bayar',
                                  icon: Icons.payment_rounded,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          InkWell(
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: context,
                                firstDate: DateTime(2000),
                                lastDate: DateTime(2100),
                                initialDate: _date,
                                builder: (context, child) {
                                  return Theme(
                                    data: Theme.of(context).copyWith(
                                      colorScheme: const ColorScheme.light(
                                        primary: Color(0xFF6366F1),
                                      ),
                                    ),
                                    child: child!,
                                  );
                                },
                              );
                              if (picked != null) {
                                setState(() => _date = picked);
                              }
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey.shade200),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.calendar_today_rounded,
                                    color: Color(0xFF6366F1),
                                    size: 20,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Tanggal Transaksi',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          DateFormat('dd MMMM yyyy')
                                              .format(_date),
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFF1F2937),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Icon(Icons.edit_rounded,
                                      size: 18, color: Colors.grey.shade400),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Category Dropdown
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _category,
                                isExpanded: true,
                                icon: const Icon(Icons.arrow_drop_down_rounded,
                                    color: Color(0xFF6366F1)),
                                items: _categories.map((String category) {
                                  return DropdownMenuItem<String>(
                                    value: category,
                                    child: Row(
                                      children: [
                                        Icon(
                                          _getCategoryIcon(category),
                                          size: 20,
                                          color: const Color(0xFF6366F1),
                                        ),
                                        const SizedBox(width: 12),
                                        Text(category),
                                      ],
                                    ),
                                  );
                                }).toList(),
                                onChanged: (String? newValue) {
                                  setState(() {
                                    _category = newValue ?? 'Lainnya';
                                  });
                                },
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Items Card
                      _SectionCard(
                        title: 'Daftar Item',
                        icon: Icons.shopping_basket_rounded,
                        children: [
                          ..._items.asMap().entries.map((entry) {
                            final i = entry.key;
                            final item = entry.value;
                            return _ItemRow(
                              item: item,
                              onChanged: (updated) {
                                setState(() {
                                  _items[i] = updated;
                                  _recalcTotals();
                                });
                              },
                              onDelete: () {
                                setState(() {
                                  _items.removeAt(i);
                                  _recalcTotals();
                                });
                              },
                            );
                          }),
                          const SizedBox(height: 12),
                          OutlinedButton.icon(
                            onPressed: () {
                              setState(() {
                                _items.add(
                                    ReceiptItem(name: 'Item Baru', price: 0));
                                _recalcTotals();
                              });
                            },
                            icon: const Icon(Icons.add_rounded),
                            label: const Text('Tambah Item'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF6366F1),
                              side: const BorderSide(color: Color(0xFF6366F1)),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Summary Card
                      _SectionCard(
                        title: 'Ringkasan',
                        icon: Icons.receipt_long_rounded,
                        children: [
                          _ModernTextField(
                            controller: _subtotal,
                            label: 'Subtotal',
                            icon: Icons.calculate_rounded,
                            keyboardType: TextInputType.number,
                            enabled: false,
                          ),
                          const SizedBox(height: 16),
                          _ModernTextField(
                            controller: _tax,
                            label: 'Pajak',
                            icon: Icons.percent_rounded,
                            keyboardType: TextInputType.number,
                          ),
                          const SizedBox(height: 16),
                          _ModernTextField(
                            controller: _total,
                            label: 'Total',
                            icon: Icons.account_balance_wallet_rounded,
                            keyboardType: TextInputType.number,
                            enabled: false,
                          ),
                        ],
                      ),

                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),

              // Save Button
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 20,
                      offset: const Offset(0, -5),
                    ),
                  ],
                ),
                child: SafeArea(
                  top: false,
                  child: ElevatedButton(
                    onPressed: _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6366F1),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      minimumSize: const Size(double.infinity, 56),
                    ),
                    child: const Text(
                      'Simpan Perubahan',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Supporting Widgets
class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
                child: Icon(icon, color: const Color(0xFF6366F1), size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }
}

class _ModernTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final TextInputType? keyboardType;
  final bool enabled;
  final TextCapitalization textCapitalization;

  const _ModernTextField({
    required this.controller,
    required this.label,
    required this.icon,
    this.keyboardType,
    this.enabled = true,
    this.textCapitalization = TextCapitalization.none,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      enabled: enabled,
      textCapitalization: textCapitalization,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFF6366F1)),
        filled: true,
        fillColor: enabled ? Colors.grey.shade50 : Colors.grey.shade100,
      ),
    );
  }
}

class _ItemRow extends StatefulWidget {
  final ReceiptItem item;
  final Function(ReceiptItem) onChanged;
  final VoidCallback onDelete;

  const _ItemRow({
    required this.item,
    required this.onChanged,
    required this.onDelete,
  });

  @override
  State<_ItemRow> createState() => _ItemRowState();
}

class _ItemRowState extends State<_ItemRow> {
  late TextEditingController _nameCtrl;
  late TextEditingController _qtyCtrl;
  late TextEditingController _priceCtrl;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.item.name);
    _qtyCtrl = TextEditingController(text: widget.item.qty.toString());
    _priceCtrl = TextEditingController(text: widget.item.price.toString());

    _nameCtrl.addListener(_notify);
    _qtyCtrl.addListener(_notify);
    _priceCtrl.addListener(_notify);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _qtyCtrl.dispose();
    _priceCtrl.dispose();
    super.dispose();
  }

  void _notify() {
    widget.onChanged(ReceiptItem(
      name: _nameCtrl.text,
      qty: num.tryParse(_qtyCtrl.text) ?? 1,
      price: num.tryParse(_priceCtrl.text) ?? 0,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                flex: 3,
                child: TextField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Nama Item',
                    isDense: true,
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: widget.onDelete,
                icon: const Icon(Icons.delete_outline),
                color: Colors.red,
                iconSize: 20,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _qtyCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Qty',
                    isDense: true,
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: TextField(
                  controller: _priceCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Harga',
                    isDense: true,
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
