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
  String _category = 'Lainnya';
  bool _isSaving = false;

  // Daftar kategori
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
    final r = context.read<ReceiptProvider>().draft;
    _merchant = TextEditingController(text: r?.merchant ?? '');
    _currency = TextEditingController(text: r?.currency ?? 'IDR');
    _subtotal = TextEditingController(text: (r?.subtotal ?? 0).toString());
    _tax = TextEditingController(text: (r?.tax ?? 0).toString());
    _total = TextEditingController(text: (r?.total ?? 0).toString());
    _payment = TextEditingController(text: r?.paymentMethod ?? '');
    _date = r?.date ?? DateTime.now();
    _items = [...(r?.items ?? [])];
    _category = r?.category ?? 'Lainnya';

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

  Future<void> _save() async {
    setState(() => _isSaving = true);

    try {
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
        paymentMethod:
            _payment.text.trim().isEmpty ? null : _payment.text.trim(),
        date: _date,
        category: _category,
        status: 'validated',
      );

      if (cur.id == 'draft') {
        final img = rp.draftImage;
        if (img == null) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Tidak ada gambar untuk disimpan')),
            );
          }
          return;
        }
        await LocalStoreService.saveNewReceipt(updated, img);
      } else {
        await LocalStoreService.updateReceipt(updated);
      }

      if (!mounted) return;
      rp.clearDraft();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 12),
              Text('Nota berhasil disimpan!'),
            ],
          ),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = context.watch<ReceiptProvider>().draft;
    if (r == null) {
      return const Scaffold(body: Center(child: Text('Tidak ada draft')));
    }

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
                            'Periksa dan edit detail',
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
                                border: Border.all(
                                  color: Colors.grey.shade200,
                                ),
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
                                  Icon(
                                    Icons.edit_rounded,
                                    color: Colors.grey.shade400,
                                    size: 20,
                                  ),
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

                      // Daftar Belanja Card
                      _SectionCard(
                        title: 'Daftar Belanja',
                        icon: Icons.shopping_cart_rounded,
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color:
                                const Color(0xFF6366F1).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${_items.length} item',
                            style: const TextStyle(
                              color: Color(0xFF6366F1),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        children: [
                          ..._items.asMap().entries.map(
                                (e) => _ModernReceiptItemTile(
                                  key: ValueKey('item-${e.key}'),
                                  item: e.value,
                                  index: e.key,
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
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: () {
                                setState(() => _items.add(ReceiptItem(
                                    name: 'Item Baru', qty: 1, price: 0)));
                                _recalcTotals();
                              },
                              icon:
                                  const Icon(Icons.add_circle_outline_rounded),
                              label: const Text('Tambah Item'),
                              style: OutlinedButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                side: BorderSide(
                                  color: const Color(0xFF6366F1)
                                      .withValues(alpha: 0.3),
                                  width: 2,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Ringkasan Pembayaran Card
                      _SectionCard(
                        title: 'Ringkasan Pembayaran',
                        icon: Icons.receipt_long_rounded,
                        children: [
                          _SummaryRow(
                            label: 'Subtotal',
                            value:
                                '${_currency.text.toUpperCase()} ${NumberFormat('#,##0', 'id_ID').format(_sumItems())}',
                            color: Colors.grey.shade700,
                          ),
                          const SizedBox(height: 12),
                          _ModernTextField(
                            controller: _tax,
                            label: 'Pajak / Service',
                            icon: Icons.percent_rounded,
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                          ),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  Color(0xFF6366F1),
                                  Color(0xFF8B5CF6),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF6366F1)
                                      .withValues(alpha: 0.3),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Total Pembayaran',
                                      style: TextStyle(
                                        color:
                                            Colors.white.withValues(alpha: 0.9),
                                        fontSize: 13,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _currency.text.toUpperCase(),
                                      style: TextStyle(
                                        color:
                                            Colors.white.withValues(alpha: 0.8),
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                                Text(
                                  NumberFormat('#,##0', 'id_ID').format(
                                    _sumItems() +
                                        (num.tryParse(_tax.text) ?? 0),
                                  ),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 32),

                      // Save Button
                      Container(
                        width: double.infinity,
                        height: 56,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFF6366F1),
                              Color(0xFF8B5CF6),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF6366F1)
                                  .withValues(alpha: 0.4),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ElevatedButton.icon(
                          onPressed: _isSaving ? null : _save,
                          icon: _isSaving
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor:
                                        AlwaysStoppedAnimation(Colors.white),
                                  ),
                                )
                              : const Icon(Icons.save_rounded),
                          label: Text(
                            _isSaving
                                ? 'Menyimpan...'
                                : (r.id == 'draft'
                                    ? 'Simpan Nota'
                                    : 'Update Nota'),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 100),
                    ],
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

// Modern Section Card Widget
class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget? trailing;
  final List<Widget> children;

  const _SectionCard({
    required this.title,
    required this.icon,
    this.trailing,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF6366F1).withValues(alpha: 0.1),
                        const Color(0xFF8B5CF6).withValues(alpha: 0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    icon,
                    color: const Color(0xFF6366F1),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                ),
                if (trailing != null) trailing!,
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
        ],
      ),
    );
  }
}

// Modern TextField Widget
class _ModernTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final TextInputType? keyboardType;
  final TextCapitalization textCapitalization;

  const _ModernTextField({
    required this.controller,
    required this.label,
    required this.icon,
    this.keyboardType,
    this.textCapitalization = TextCapitalization.none,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFF6366F1)),
        filled: true,
        fillColor: Colors.grey.shade50,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF6366F1), width: 2),
        ),
      ),
    );
  }
}

// Summary Row Widget
class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;

  const _SummaryRow({
    required this.label,
    required this.value,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 15,
            color: Colors.grey.shade600,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: color ?? const Color(0xFF1F2937),
          ),
        ),
      ],
    );
  }
}

// Modern Receipt Item Tile
class _ModernReceiptItemTile extends StatefulWidget {
  final ReceiptItem item;
  final int index;
  final VoidCallback? onRemove;
  final ValueChanged<ReceiptItem>? onChanged;

  const _ModernReceiptItemTile({
    super.key,
    required this.item,
    required this.index,
    this.onRemove,
    this.onChanged,
  });

  @override
  State<_ModernReceiptItemTile> createState() => _ModernReceiptItemTileState();
}

class _ModernReceiptItemTileState extends State<_ModernReceiptItemTile> {
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
  void didUpdateWidget(covariant _ModernReceiptItemTile oldWidget) {
    super.didUpdateWidget(oldWidget);
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
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF6366F1),
                      Color(0xFF8B5CF6),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    '${widget.index + 1}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Item ${widget.index + 1}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1F2937),
                  ),
                ),
              ),
              IconButton(
                onPressed: widget.onRemove,
                icon: const Icon(Icons.delete_outline_rounded),
                color: Colors.red.shade400,
                style: IconButton.styleFrom(
                  backgroundColor: Colors.red.shade50,
                  padding: const EdgeInsets.all(8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _nameCtrl,
            focusNode: _nameFocus,
            decoration: InputDecoration(
              labelText: 'Nama Item',
              prefixIcon: const Icon(Icons.shopping_bag_outlined, size: 20),
              filled: true,
              fillColor: Colors.white,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide:
                    const BorderSide(color: Color(0xFF6366F1), width: 2),
              ),
            ),
            onChanged: (v) => widget.onChanged?.call(
              ReceiptItem(
                name: v,
                qty: num.tryParse(_qtyCtrl.text) ?? 1,
                price: num.tryParse(_priceCtrl.text) ?? 0,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: TextField(
                  controller: _qtyCtrl,
                  focusNode: _qtyFocus,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'Qty',
                    prefixIcon: const Icon(Icons.numbers_rounded, size: 20),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.grey.shade200),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide:
                          const BorderSide(color: Color(0xFF6366F1), width: 2),
                    ),
                  ),
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
                flex: 3,
                child: TextField(
                  controller: _priceCtrl,
                  focusNode: _priceFocus,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'Harga Total',
                    prefixIcon:
                        const Icon(Icons.attach_money_rounded, size: 20),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.grey.shade200),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide:
                          const BorderSide(color: Color(0xFF6366F1), width: 2),
                    ),
                  ),
                  onChanged: (v) => widget.onChanged?.call(
                    ReceiptItem(
                      name: _nameCtrl.text,
                      qty: num.tryParse(_qtyCtrl.text) ?? 1,
                      price: num.tryParse(v) ?? 0,
                    ),
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
