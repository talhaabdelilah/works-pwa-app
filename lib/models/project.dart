class Room {
  final int id;
  double? lengthVal;
  double? widthVal;
  String calcMode;
  double pricePerMeter;

  Room({required this.id, this.lengthVal, this.widthVal, this.calcMode = 'area', this.pricePerMeter = 50});

  Map<String, dynamic> toJson() => {
    'id': id, 'lengthVal': lengthVal, 'widthVal': widthVal,
    'calcMode': calcMode, 'pricePerMeter': pricePerMeter,
  };

  factory Room.fromJson(Map<String, dynamic> json) {
    final room = Room(
      id: json['id'] ?? DateTime.now().millisecondsSinceEpoch,
      lengthVal: (json['lengthVal'] as num?)?.toDouble(),
      widthVal: (json['widthVal'] as num?)?.toDouble(),
      calcMode: json['calcMode'] ?? 'area',
      pricePerMeter: (json['pricePerMeter'] as num?)?.toDouble() ?? 50,
    );
    if (json['pricePerMeter'] == null && json['totalCost'] != null && room.meterValue > 0) {
      room.pricePerMeter = (json['totalCost'] as num).toDouble() / room.meterValue;
    }
    return room;
  }

  double get meterValue {
    if (lengthVal == null || widthVal == null) return 0;
    return calcMode == 'area' ? lengthVal! * widthVal! : 2 * (lengthVal! + widthVal!);
  }

  double get totalCost => meterValue * pricePerMeter;
}

class Payment {
  String date;
  double amount;
  String note;

  Payment({required this.date, required this.amount, this.note = ''});

  Map<String, dynamic> toJson() => {'date': date, 'amount': amount, 'note': note};

  factory Payment.fromJson(Map<String, dynamic> json) => Payment(
    date: json['date'] ?? '',
    amount: (json['amount'] as num?)?.toDouble() ?? 0,
    note: json['note'] ?? '',
  );
}

class ProjectAttachment {
  final int id;
  String name;
  String path;
  String type;
  String note;

  ProjectAttachment({required this.id, required this.name, required this.path, this.type = 'image', this.note = ''});

  Map<String, dynamic> toJson() => {
    'id': id, 'name': name, 'path': path, 'type': type, 'note': note,
  };

  factory ProjectAttachment.fromJson(Map<String, dynamic> json) => ProjectAttachment(
    id: json['id'] ?? DateTime.now().millisecondsSinceEpoch,
    name: json['name'] ?? '',
    path: json['path'] ?? '',
    type: json['type'] ?? 'image',
    note: json['note'] ?? '',
  );
}

class Project {
  final int id;
  String name;
  double globalPricePerMeter;
  List<Room> rooms;
  List<Payment> payments;
  String notes;
  List<ProjectAttachment> attachments;

  Project({
    required this.id,
    required this.name,
    this.globalPricePerMeter = 50,
    List<Room>? rooms,
    List<Payment>? payments,
    this.notes = '',
    List<ProjectAttachment>? attachments,
  }) : rooms = rooms ?? [], payments = payments ?? [], attachments = attachments ?? [];

  double get totalCost => rooms.fold(0, (s, r) => s + r.totalCost);
  double get totalPayments => payments.fold(0, (s, p) => s + p.amount);
  double get remaining => totalCost - totalPayments;

  Map<String, dynamic> toJson() => {
    'id': id, 'name': name, 'globalPricePerMeter': globalPricePerMeter,
    'rooms': rooms.map((r) => r.toJson()).toList(),
    'payments': payments.map((p) => p.toJson()).toList(),
    'notes': notes,
    'attachments': attachments.map((a) => a.toJson()).toList(),
  };

  factory Project.fromJson(Map<String, dynamic> json) => Project(
    id: json['id'] ?? DateTime.now().millisecondsSinceEpoch,
    name: json['name'] ?? '',
    globalPricePerMeter: (json['globalPricePerMeter'] as num?)?.toDouble() ?? 50,
    rooms: (json['rooms'] as List?)?.map((r) => Room.fromJson(r)).toList() ?? [],
    payments: (json['payments'] as List?)?.map((p) => Payment.fromJson(p)).toList() ?? [],
    notes: json['notes'] as String? ?? '',
    attachments: (json['attachments'] as List?)?.map((a) => ProjectAttachment.fromJson(a)).toList() ?? [],
  );
}
