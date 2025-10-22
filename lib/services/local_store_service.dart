import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import 'package:smartnote_flutter/models/receipt.dart';

class LocalStoreService {
  static const _uuid = Uuid();
  static final _controller = StreamController<List<Receipt>>.broadcast();
  static List<Receipt> _cache = [];
  static bool _ready = false;

  // ---- paths ----
  static Future<Directory> _baseDir() async {
    final dir = await getApplicationDocumentsDirectory();
    final base = Directory('${dir.path}/smartnote');
    if (!await base.exists()) await base.create(recursive: true);
    return base;
  }

  static Future<File> _dbFile() async {
    final base = await _baseDir();
    final f = File('${base.path}/receipts.json');
    if (!await f.exists()) {
      await f.create(recursive: true);
      await f.writeAsString(jsonEncode([]));
    }
    return f;
  }

  static Future<Directory> _imagesDir() async {
    final base = await _baseDir();
    final d = Directory('${base.path}/images');
    if (!await d.exists()) await d.create(recursive: true);
    return d;
  }

  // ---- core ----
  static Future<void> _init() async {
    if (_ready) return;
    final f = await _dbFile();
    final txt = await f.readAsString();
    try {
      final List<dynamic> raw = (txt.trim().isEmpty) ? [] : jsonDecode(txt) as List<dynamic>;
      _cache = raw.map((e) => Receipt.fromJson(Map<String, dynamic>.from(e))).toList();
    } catch (_) {
      _cache = [];
    }
    _emit();
    _ready = true;
  }

  static void _emit() {
    _cache.sort((a, b) => b.date.compareTo(a.date));
    _controller.add(List.unmodifiable(_cache));
  }

  static Future<void> _persist() async {
    final f = await _dbFile();
    final list = _cache.map((e) => e.toJson()).toList();
    await f.writeAsString(jsonEncode(list));
  }

  // ---- API mirip FirestoreService ----
  static Stream<List<Receipt>> streamReceipts([String? _]) {
    () async {
      await _init();  // baca file
      _emit();        // pastikan kirim snapshot pertama
    }();
    return _controller.stream;
  }

  static Future<Receipt> saveNewReceipt(Receipt draft, Uint8List imageBytes) async {
    await _init();
    final id = _uuid.v4();
    final images = await _imagesDir();
    final imgPath = '${images.path}/$id.jpg';
    await File(imgPath).writeAsBytes(imageBytes);

    final now = DateTime.now();
    final created = draft.createdAt;
    final r = draft.copyWith(
      id: id,
      imagePath: imgPath,
      status: 'validated',
      createdAt: created.isAfter(DateTime(2001)) ? created : now,
      updatedAt: now,
    );

    _cache.add(r);
    await _persist();
    _emit();
    return r;
  }

  static Future<void> updateReceipt(Receipt r) async {
    await _init();
    final idx = _cache.indexWhere((e) => e.id == r.id);
    if (idx != -1) {
      _cache[idx] = r.copyWith(updatedAt: DateTime.now(), status: 'validated');
      await _persist();
      _emit();
    }
  }

  static Future<void> deleteReceipt(Receipt r) async {
    await _init();
    _cache.removeWhere((e) => e.id == r.id);
    if ((r.imagePath ?? '').isNotEmpty) {
      final f = File(r.imagePath!);
      if (await f.exists()) await f.delete();
    }
    await _persist();
    _emit();
  }

  static Future<List<Receipt>> receiptsInMonth(DateTime month, [String? _]) async {
    await _init();
    final start = DateTime(month.year, month.month, 1);
    final end = DateTime(month.year, month.month + 1, 1);
    return _cache
        .where((r) => !r.date.isBefore(start) && r.date.isBefore(end))
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }
}
