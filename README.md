# SmartNote Flutter (Receipt OCR -> JSON -> Firestore)

A minimal Flutter skeleton that scans/chooses a receipt image, uses **Gemini** to extract
structured JSON, lets the user **validate/edit**, then saves to **Firebase** (Firestore + Storage).
Anonymous Auth is enabled by default.

> This is a starter. Run `flutterfire configure` to generate `lib/firebase_options.dart`
  and connect your Firebase project.

## Quickstart
1. **Install Flutter** and create an empty project if you haven't.
2. Copy this folder, then run:
   ```bash
   flutter pub get
   dart pub global activate flutterfire_cli
   flutterfire configure
   ```
   This generates `lib/firebase_options.dart` and sets up iOS/Android config.
3. Create `.env` from `.env.example` and set `GEMINI_API_KEY` (from AI Studio).
4. Run the app:
   ```bash
   flutter run
   ```

## Flow
- Home: pick from **Camera** or **Gallery**.
- OCR: send image to **Gemini** (`gemini-1.5-flash`) with a strict JSON schema prompt.
- Review: edit fields (merchant, date, items, totals). Save to Firestore + upload image to Storage.
- History: list receipts (tap to edit).
- Report: monthly totals (client-side aggregation).

## Collections
- `users/{uid}/receipts/{receiptId}`
- Image at `receipts/{uid}/{receiptId}.jpg`

## Dev Notes
- This uses **Provider** for state management.
- If Gemini returns non-JSON text, the code attempts to extract the first JSON block.
- Firestore rules in `firebase.rules` (dev only). Change before production.
