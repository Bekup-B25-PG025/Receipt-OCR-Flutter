import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:smartnote_flutter/models/receipt.dart';
import 'package:smartnote_flutter/providers/receipt_provider.dart';
import 'package:smartnote_flutter/services/local_store_service.dart';
import 'package:smartnote_flutter/screens/batch_review_screen.dart';

class BatchConfirmScreen extends StatefulWidget {
  const BatchConfirmScreen({super.key});

  @override
  State<BatchConfirmScreen> createState() => _BatchConfirmScreenState();
}

class _BatchConfirmScreenState extends State<BatchConfirmScreen> {
  bool _isSaving = false;

  // Store selected category for each receipt by index
  final Map<int, String> _selectedCategories = {};

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Kebutuhan Bisnis':
        return Icons.business_center_rounded;
      case 'Makanan':
        return Icons.restaurant_rounded;
      case 'Transportasi':
        return Icons.directions_car_rounded;
      case 'Kesehatan':
        return Icons.health_and_safety_rounded;
      case 'Pendidikan':
        return Icons.school_rounded;
      case 'Kebutuhan Harian':
        return Icons.shopping_bag_rounded;
      case 'Kebutuhan Bulanan':
        return Icons.calendar_month_rounded;
      case 'Belanja':
        return Icons.shopping_cart_rounded;
      default:
        return Icons.category_rounded;
    }
  }

  // Group receipts by date
  Map<String, List<int>> _groupByDate(List<Receipt> receipts) {
    final Map<String, List<int>> grouped = {};

    for (int i = 0; i < receipts.length; i++) {
      final dateKey = DateFormat('yyyy-MM-dd').format(receipts[i].date);
      (grouped[dateKey] ??= []).add(i);
    }

    return grouped;
  }

  Future<void> _saveAll() async {
    setState(() => _isSaving = true);

    try {
      final rp = context.read<ReceiptProvider>();
      final receipts = rp.batchDrafts;
      final images = rp.batchImages;

      if (receipts.isEmpty || images.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Tidak ada data untuk disimpan')),
          );
        }
        return;
      }

      // Apply selected categories to receipts
      final updatedReceipts = <Receipt>[];
      for (int i = 0; i < receipts.length; i++) {
        final category = _selectedCategories[i] ?? receipts[i].category;
        updatedReceipts.add(receipts[i].copyWith(category: category));
      }

      // Save all receipts
      await LocalStoreService.saveBatchReceipts(updatedReceipts, images);

      if (!mounted) return;
      rp.clearBatchDrafts();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 12),
              Text('${receipts.length} nota berhasil disimpan!'),
            ],
          ),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );

      // Navigate back to home
      Navigator.popUntil(context, (route) => route.isFirst);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _removeReceipt(int index) {
    context.read<ReceiptProvider>().removeBatchDraft(index);
  }

  void _editReceipt(int index) async {
    final rp = context.read<ReceiptProvider>();
    final receipt = rp.batchDrafts[index];
    final image = rp.batchImages[index];

    // Navigate to review screen for this specific receipt
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BatchReviewScreen(
          receipt: receipt,
          image: image,
          index: index,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final rp = context.watch<ReceiptProvider>();
    final receipts = rp.batchDrafts;
    final images = rp.batchImages;

    if (receipts.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Konfirmasi Batch')),
        body: const Center(child: Text('Tidak ada data untuk dikonfirmasi')),
      );
    }

    final groupedByDate = _groupByDate(receipts);
    final sortedDates = groupedByDate.keys.toList()
      ..sort((a, b) => b.compareTo(a)); // newest first

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
                            'Konfirmasi Batch',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1F2937),
                            ),
                          ),
                          Text(
                            '${receipts.length} nota terdeteksi',
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

              // Processing indicator
              if (rp.isProcessingBatch)
                Container(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Memproses nota... ${receipts.length}/${images.length}',
                        style: TextStyle(
                          color: Colors.blue.shade900,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),

              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(24),
                  itemCount: sortedDates.length,
                  itemBuilder: (context, dateIndex) {
                    final dateKey = sortedDates[dateIndex];
                    final indices = groupedByDate[dateKey]!;
                    final date = receipts[indices.first].date;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Date Header
                        Padding(
                          padding: EdgeInsets.only(
                              left: 8, bottom: 12, top: dateIndex > 0 ? 24 : 0),
                          child: Row(
                            children: [
                              Icon(
                                Icons.calendar_today_rounded,
                                size: 18,
                                color: Colors.grey.shade700,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                DateFormat('EEEE, dd MMMM yyyy').format(date),
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey.shade800,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF6366F1)
                                      .withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '${indices.length} nota',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF6366F1),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Receipts in this date
                        ...indices.map((index) {
                          final receipt = receipts[index];
                          final image = images[index];
                          final selectedCategory =
                              _selectedCategories[index] ?? receipt.category;

                          return _ReceiptCard(
                            receipt: receipt,
                            image: image,
                            index: index,
                            selectedCategory: selectedCategory,
                            onCategoryChanged: (category) {
                              setState(() {
                                _selectedCategories[index] = category;
                              });
                            },
                            onRemove: () => _removeReceipt(index),
                            onEdit: () => _editReceipt(index),
                            getCategoryIcon: _getCategoryIcon,
                          );
                        }),
                      ],
                    );
                  },
                ),
              ),

              // Bottom Action Bar
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
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed:
                              _isSaving ? null : () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            side: const BorderSide(color: Color(0xFF6366F1)),
                          ),
                          child: const Text(
                            'Batal',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed:
                              _isSaving || receipts.isEmpty ? null : _saveAll,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            backgroundColor: const Color(0xFF6366F1),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: _isSaving
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(
                                  'Simpan Semua (${receipts.length})',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),
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

class _ReceiptCard extends StatelessWidget {
  final Receipt receipt;
  final Uint8List image;
  final int index;
  final String selectedCategory;
  final ValueChanged<String> onCategoryChanged;
  final VoidCallback onRemove;
  final VoidCallback onEdit;
  final IconData Function(String) getCategoryIcon;

  const _ReceiptCard({
    required this.receipt,
    required this.image,
    required this.index,
    required this.selectedCategory,
    required this.onCategoryChanged,
    required this.onRemove,
    required this.onEdit,
    required this.getCategoryIcon,
  });

  @override
  Widget build(BuildContext context) {
    final money = NumberFormat('#,##0', 'id_ID');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            Colors.grey.shade50,
          ],
        ),
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
          // Image Preview
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            child: Image.memory(
              image,
              height: 180,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            receipt.merchant ?? 'Nota #${index + 1}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1F2937),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${receipt.currency} ${money.format(receipt.total)}',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF6366F1),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: onRemove,
                      icon: const Icon(Icons.delete_outline_rounded),
                      color: Colors.red.shade400,
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.red.shade50,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Category Label
                Text(
                  'Kategori',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 6),

                // Category Dropdown (Compact)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.grey.shade300,
                    ),
                  ),
                  child: DropdownButton<String>(
                    value: selectedCategory,
                    isExpanded: true,
                    underline: const SizedBox(),
                    isDense: true,
                    icon: Icon(Icons.arrow_drop_down,
                        size: 20, color: Colors.grey.shade600),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade800,
                      fontWeight: FontWeight.w500,
                    ),
                    items: [
                      'Kebutuhan Bisnis',
                      'Makanan',
                      'Transportasi',
                      'Kesehatan',
                      'Pendidikan',
                      'Kebutuhan Harian',
                      'Kebutuhan Bulanan',
                      'Belanja',
                      'Lainnya',
                    ].map((category) {
                      return DropdownMenuItem(
                        value: category,
                        child: Row(
                          children: [
                            Icon(
                              getCategoryIcon(category),
                              size: 14,
                              color: const Color(0xFF6366F1),
                            ),
                            const SizedBox(width: 6),
                            Text(category),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        onCategoryChanged(value);
                      }
                    },
                  ),
                ),
                const SizedBox(height: 10),

                Row(
                  children: [
                    Expanded(
                      child: _InfoChip(
                        icon: Icons.shopping_basket_rounded,
                        label: '${receipt.items.length} item',
                      ),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      onPressed: onEdit,
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      label: const Text('Edit'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF6366F1),
                        side: const BorderSide(color: Color(0xFF6366F1)),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.grey.shade700),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
