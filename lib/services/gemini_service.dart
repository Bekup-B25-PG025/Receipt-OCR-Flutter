import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:smartnote_flutter/models/receipt.dart';

class GeminiService {
  // Urutan kandidat model: v1 dulu, lalu kompatibel v1beta
  static const _modelCandidates = <String>[
    'gemini-2.5-flash',        // v1 (baru)
    'gemini-2.5-flash-lite',   // v1beta (kompatibel lama)
    'gemini-1.0-pro-vision',
    'gemini-pro-vision', // alias yang kadang tersedia
  ];

  static const String _systemPrompt = '''
You extract **structured fields** from a photo of a shopping or restaurant receipt.
Return **ONLY JSON** and nothing else. Use this exact schema:

{
  "merchant": "string | null",
  "date": "YYYY-MM-DD",
  "currency": "IDR|USD|EUR|...",
  "payment_method": "string | null",
  "items": [{"name":"string","qty": number,"price": number}],
  "subtotal": number,
  "tax": number,
  "total": number,
  "raw_text": "full OCR text for reference"
}

Rules:
- Parse localized decimal separators (e.g., 54.50 or 54,50).
- If quantity is written like "2x" or "x2", set qty=2.
- Prices are per line item total (qty * unit_price) if only one number shown.
- If date is ambiguous, infer using receipt locale and ensure "YYYY-MM-DD".
- If a field is missing, put a best guess or null. Always include "total".
- The "raw_text" should be a joined text of detected lines.
Return ONLY the JSON object, no explanation.
''';

  static Future<Receipt> analyzeReceipt(Uint8List imageBytes) async {
    final apiKey = dotenv.env['GEMINI_API_KEY']?.trim();
    if (apiKey == null || apiKey.isEmpty) {
      throw StateError('GEMINI_API_KEY kosong. Isi di file .env');
    }

    final userContent = [
      Content.data('image/jpeg', imageBytes),
      Content.text('Extract the receipt with the schema above. Language can be Indonesian or English.'),
    ];

    GenerateContentResponse? response;
    Object? lastError;

    // Coba beberapa model sampai berhasil
    for (final m in _modelCandidates) {
      try {
        final model = GenerativeModel(
          model: m,
          apiKey: apiKey,
          generationConfig: GenerationConfig(
            temperature: 0.2,
            responseMimeType: 'application/json',
          ),
          systemInstruction: Content.text(_systemPrompt),
        );
        response = await model.generateContent(userContent);
        break; // sukses
      } catch (e) {
        lastError = e;
        // lanjut ke kandidat berikutnya
      }
    }

    if (response == null) {
      throw StateError(
        'Gagal memanggil Gemini. Terakhir error: $lastError\n'
        'Coba update package google_generative_ai (flutter pub upgrade) '
        'atau cek koneksi & GEMINI_API_KEY.',
      );
    }

    final text = response.text ?? '{}';
    final Map<String, dynamic> j = _firstJsonObject(text);

    // Parse items
    final itemsList = (j['items'] as List? ?? []);
    final parsedItems = itemsList
        .map((e) => ReceiptItem.fromJson(Map<String, dynamic>.from(e)))
        .toList();

    // Parse date
    DateTime when = DateTime.now();
    final ds = (j['date'] ?? '').toString().trim();
    if (ds.isNotEmpty) {
      try {
        when = DateTime.parse(ds.replaceAll('/', '-'));
      } catch (_) {
        // biarkan fallback ke now
      }
    }

    num subtotal = _asNum(j['subtotal']);
    num tax = _asNum(j['tax']);
    num total = _asNum(j['total']);
    if (total == 0 && subtotal != 0) total = subtotal + tax;

    // (opsional) print model yang dipakai, untuk debug
    // debugPrint('Gemini used model: $usedModel');

    return Receipt(
      id: 'draft',
      merchant: _asStringOrNull(j['merchant']),
      currency: (j['currency'] ?? 'IDR').toString().toUpperCase(),
      items: parsedItems,
      subtotal: subtotal,
      tax: tax,
      total: total,
      paymentMethod: _asStringOrNull(j['payment_method']),
      imagePath: null,
      rawText: _asStringOrNull(j['raw_text']),
      date: when,
      status: 'draft',
    );
  }

  // ---- helpers ----

  static num _asNum(dynamic v) {
    if (v is num) return v;
    if (v is String) {
      // ganti koma -> titik, hapus spasi
      final s = v.replaceAll('.', '').replaceAll(',', '.').trim();
      return num.tryParse(s) ?? 0;
    }
    return 0;
    }

  static String? _asStringOrNull(dynamic v) {
    if (v == null) return null;
    final s = v.toString().trim();
    return s.isEmpty ? null : s;
  }

  /// Ambil JSON object pertama dari respons (kalau model menyisipkan teks tambahan).
  static Map<String, dynamic> _firstJsonObject(String text) {
    try {
      return Map<String, dynamic>.from(jsonDecode(text));
    } catch (_) {
      // cari blok {...} pertama
      final match = RegExp(r'\{[\s\S]*\}').firstMatch(text);
      if (match != null) {
        try {
          return Map<String, dynamic>.from(jsonDecode(match.group(0)!));
        } catch (_) {}
      }
    }
    return <String, dynamic>{};
  }
}
