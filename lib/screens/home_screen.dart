// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:smartnote_flutter/providers/receipt_provider.dart';
// ⬇️ tambahkan import ini
import 'package:smartnote_flutter/screens/confirm_import_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _picker = ImagePicker();
  bool _busy = false;

  Future<void> _pick(ImageSource source) async {
    try {
      setState(() => _busy = true);
      final provider = context.read<ReceiptProvider>();
      final x = await _picker.pickImage(source: source, imageQuality: 95);
      if (x == null) return;
      final bytes = await x.readAsBytes();

      // Jalankan OCR → isi draft & draftImage di provider
      await provider.analyzeImage(bytes);

      if (mounted) {
        // ⬇️ arahkan ke layar konfirmasi
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ConfirmImportScreen()),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.camera_alt, size: 120, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            FilledButton.icon(
              icon: const Icon(Icons.photo_camera),
              label: const Text('Take Bill Photo'),
              onPressed: _busy ? null : () => _pick(ImageSource.camera),
            ),
            const SizedBox(height: 12),
            FilledButton.tonalIcon(
              icon: const Icon(Icons.photo_library_outlined),
              label: const Text('Add From Device'),
              onPressed: _busy ? null : () => _pick(ImageSource.gallery),
            ),
            const SizedBox(height: 24),
            if (_busy) const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
