import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:smartnote_flutter/providers/receipt_provider.dart';
import 'package:smartnote_flutter/screens/review_screen.dart';

class ConfirmImportScreen extends StatefulWidget {
  const ConfirmImportScreen({super.key});

  @override
  State<ConfirmImportScreen> createState() => _ConfirmImportScreenState();
}

class _ConfirmImportScreenState extends State<ConfirmImportScreen> {
  String _selectedCategory = 'Lainnya';

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
                            'Konfirmasi Nota',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1F2937),
                            ),
                          ),
                          Text(
                            'Periksa hasil scan',
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
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Image Preview dengan Hero Animation
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: Image.memory(
                            img,
                            height: 320,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Info Card
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.white,
                              Colors.grey.shade50,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF6366F1)
                                  .withValues(alpha: 0.1),
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
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [
                                        Color(0xFF6366F1),
                                        Color(0xFF8B5CF6),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.check_circle_rounded,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Berhasil Discan',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF1F2937),
                                        ),
                                      ),
                                      Text(
                                        'Data berhasil diambil',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 20),
                            Divider(color: Colors.grey.shade200),
                            const SizedBox(height: 20),

                            // Details
                            _InfoRow(
                              icon: Icons.store_rounded,
                              label: 'Merchant',
                              value: draft.merchant ?? 'Tidak terdeteksi',
                            ),
                            const SizedBox(height: 16),
                            _InfoRow(
                              icon: Icons.calendar_today_rounded,
                              label: 'Tanggal',
                              value:
                                  DateFormat('dd MMMM yyyy').format(draft.date),
                            ),
                            const SizedBox(height: 16),
                            _InfoRow(
                              icon: Icons.payments_rounded,
                              label: 'Total Pembayaran',
                              value:
                                  '${draft.currency} ${NumberFormat('#,##0', 'id_ID').format(draft.total)}',
                              valueColor: const Color(0xFF6366F1),
                              valueBold: true,
                            ),
                            const SizedBox(height: 16),
                            _InfoRow(
                              icon: Icons.shopping_cart_rounded,
                              label: 'Jumlah Item',
                              value: '${draft.items.length} item',
                            ),

                            if (draft.items.isNotEmpty) ...[
                              const SizedBox(height: 20),
                              Divider(color: Colors.grey.shade200),
                              const SizedBox(height: 16),
                              Text(
                                'Preview Item (3 pertama)',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              const SizedBox(height: 12),
                              for (final it in draft.items.take(3))
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 6,
                                        height: 6,
                                        decoration: const BoxDecoration(
                                          color: Color(0xFF6366F1),
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          it.name,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            color: Color(0xFF1F2937),
                                          ),
                                        ),
                                      ),
                                      Text(
                                        '${draft.currency} ${NumberFormat('#,##0', 'id_ID').format(it.price)}',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.grey.shade700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              if (draft.items.length > 3)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Text(
                                    '+ ${draft.items.length - 3} item lainnya',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey.shade500,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ),
                            ],
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Category Selection (Compact)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF6366F1)
                                  .withValues(alpha: 0.08),
                              blurRadius: 12,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Kategori',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade700,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: [
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
                                final isSelected =
                                    _selectedCategory == category;
                                return FilterChip(
                                  selected: isSelected,
                                  visualDensity: VisualDensity.compact,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  label: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        _getCategoryIcon(category),
                                        size: 14,
                                        color: isSelected
                                            ? Colors.white
                                            : const Color(0xFF6366F1),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(category),
                                    ],
                                  ),
                                  onSelected: (selected) {
                                    setState(() {
                                      _selectedCategory = category;
                                    });
                                  },
                                  selectedColor: const Color(0xFF6366F1),
                                  checkmarkColor: Colors.white,
                                  backgroundColor: Colors.grey.shade50,
                                  labelStyle: TextStyle(
                                    fontSize: 11,
                                    color: isSelected
                                        ? Colors.white
                                        : const Color(0xFF1F2937),
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    side: BorderSide(
                                      color: isSelected
                                          ? const Color(0xFF6366F1)
                                          : Colors.grey.shade300,
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Buttons
                      Row(
                        children: [
                          Expanded(
                            child: SizedBox(
                              height: 56,
                              child: OutlinedButton.icon(
                                onPressed: () {
                                  rp.clearDraft();
                                  Navigator.pop(context);
                                },
                                icon: const Icon(Icons.close_rounded),
                                label: const Text('Batal'),
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(
                                    color: Colors.grey.shade300,
                                    width: 2,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: Container(
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
                                onPressed: () {
                                  // Update category before navigation
                                  rp.updateDraft(draft.copyWith(
                                      category: _selectedCategory));
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) => const ReviewScreen()),
                                  );
                                },
                                icon: const Icon(Icons.edit_rounded),
                                label: const Text('Buat Laporan'),
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
                          ),
                        ],
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

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;
  final bool valueBold;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
    this.valueBold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: Colors.grey.shade600,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
        ),
        Flexible(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: valueBold ? FontWeight.bold : FontWeight.w600,
              color: valueColor ?? const Color(0xFF1F2937),
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }
}
