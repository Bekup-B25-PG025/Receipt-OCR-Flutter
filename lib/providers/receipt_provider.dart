import 'package:flutter/foundation.dart';
import 'package:smartnote_flutter/models/receipt.dart';
import 'package:smartnote_flutter/services/gemini_service.dart';

class ReceiptProvider extends ChangeNotifier {
  Receipt? draft;
  Uint8List? draftImage;

  Future<void> analyzeImage(Uint8List bytes) async {
    draftImage = bytes;
    notifyListeners();
    final parsed = await GeminiService.analyzeReceipt(bytes);
    draft = parsed.copyWith(id: 'draft');
    notifyListeners();
  }

  void updateDraft(Receipt r) {
    draft = r;
    notifyListeners();
  }

  void clearDraft() {
    draft = null;
    draftImage = null;
    notifyListeners();
  }
}
