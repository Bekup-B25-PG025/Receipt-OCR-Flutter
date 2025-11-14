import 'package:flutter/foundation.dart';
import 'package:smartnote_flutter/models/receipt.dart';
import 'package:smartnote_flutter/services/gemini_service.dart';

class ReceiptProvider extends ChangeNotifier {
  Receipt? draft;
  Uint8List? draftImage;

  // Multi-image support
  List<Receipt> batchDrafts = [];
  List<Uint8List> batchImages = [];
  bool isProcessingBatch = false;

  Future<void> analyzeImage(Uint8List bytes) async {
    draftImage = bytes;
    notifyListeners();
    final parsed = await GeminiService.analyzeReceipt(bytes);
    draft = parsed.copyWith(id: 'draft');
    notifyListeners();
  }

  // Batch analyze multiple images (max 5)
  Future<void> analyzeMultipleImages(List<Uint8List> imageBytesList) async {
    if (imageBytesList.isEmpty || imageBytesList.length > 5) {
      throw ArgumentError('Jumlah gambar harus antara 1-5');
    }

    isProcessingBatch = true;
    batchImages = imageBytesList;
    batchDrafts = [];
    notifyListeners();

    for (int i = 0; i < imageBytesList.length; i++) {
      try {
        final parsed = await GeminiService.analyzeReceipt(imageBytesList[i]);
        batchDrafts.add(parsed.copyWith(id: 'draft_$i'));
        notifyListeners(); // Update UI after each image processed
      } catch (e) {
        debugPrint('Error analyzing image $i: $e');
        // Continue processing other images even if one fails
      }
    }

    isProcessingBatch = false;
    notifyListeners();
  }

  void updateDraft(Receipt r) {
    draft = r;
    notifyListeners();
  }

  void updateBatchDraft(int index, Receipt r) {
    if (index >= 0 && index < batchDrafts.length) {
      batchDrafts[index] = r;
      notifyListeners();
    }
  }

  void removeBatchDraft(int index) {
    if (index >= 0 && index < batchDrafts.length) {
      batchDrafts.removeAt(index);
      batchImages.removeAt(index);
      notifyListeners();
    }
  }

  void clearDraft() {
    draft = null;
    draftImage = null;
    notifyListeners();
  }

  void clearBatchDrafts() {
    batchDrafts = [];
    batchImages = [];
    isProcessingBatch = false;
    notifyListeners();
  }
}
