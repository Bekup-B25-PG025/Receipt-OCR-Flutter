class ReceiptItem {
  String name;
  num qty;
  num price;

  ReceiptItem({required this.name, this.qty = 1, required this.price});

  factory ReceiptItem.fromJson(Map<String, dynamic> j) => ReceiptItem(
        name: j['name'] ?? '',
        qty: (j['qty'] ?? 1),
        price: (j['price'] ?? 0),
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'qty': qty,
        'price': price,
      };
}

class Receipt {
  String id;
  String? merchant;
  String currency;
  List<ReceiptItem> items;
  num subtotal;
  num tax;
  num total;
  String? paymentMethod;
  String? imagePath; // local file path
  String? rawText;
  DateTime date;
  DateTime createdAt;
  DateTime updatedAt;
  String status; // 'draft' | 'validated'

  Receipt({
    required this.id,
    required this.date,
    required this.items,
    this.merchant,
    this.currency = 'IDR',
    this.subtotal = 0,
    this.tax = 0,
    this.total = 0,
    this.paymentMethod,
    this.imagePath,
    this.rawText,
    this.status = 'draft',
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Receipt copyWith({
    String? id,
    String? merchant,
    String? currency,
    List<ReceiptItem>? items,
    num? subtotal,
    num? tax,
    num? total,
    String? paymentMethod,
    String? imagePath,
    String? rawText,
    DateTime? date,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Receipt(
      id: id ?? this.id,
      merchant: merchant ?? this.merchant,
      currency: currency ?? this.currency,
      items: items ?? this.items,
      subtotal: subtotal ?? this.subtotal,
      tax: tax ?? this.tax,
      total: total ?? this.total,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      imagePath: imagePath ?? this.imagePath,
      rawText: rawText ?? this.rawText,
      date: date ?? this.date,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory Receipt.fromJson(Map<String, dynamic> j) {
    final items = (j['items'] as List? ?? [])
        .map((e) => ReceiptItem.fromJson(Map<String, dynamic>.from(e)))
        .toList();
    DateTime parseDT(dynamic v) {
      if (v == null) return DateTime.now();
      if (v is DateTime) return v;
      return DateTime.tryParse(v.toString()) ?? DateTime.now();
    }

    return Receipt(
      id: j['id'] ?? '',
      merchant: j['merchant'],
      currency: j['currency'] ?? 'IDR',
      items: items,
      subtotal: j['subtotal'] ?? 0,
      tax: j['tax'] ?? 0,
      total: j['total'] ?? 0,
      paymentMethod: j['paymentMethod'],
      imagePath: j['imagePath'],
      rawText: j['rawText'],
      date: parseDT(j['date']),
      createdAt: parseDT(j['createdAt']),
      updatedAt: parseDT(j['updatedAt']),
      status: j['status'] ?? 'draft',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'merchant': merchant,
        'currency': currency,
        'items': items.map((e) => e.toJson()).toList(),
        'subtotal': subtotal,
        'tax': tax,
        'total': total,
        'paymentMethod': paymentMethod,
        'imagePath': imagePath,
        'rawText': rawText,
        'date': date.toIso8601String(),
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'status': status,
      };
}
