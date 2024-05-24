class Event {
  final int? id;
  final String name;
  final int amount;
  final bool status;
  final String remark;
  final DateTime date;

  Event({
    this.id,
    required this.name,
    required this.amount,
    this.status = false,
    required this.remark,
    required this.date,
  });

  Event copy({
    int? id,
    String? name,
    int? amount,
    bool? status,
    String? remark,
    DateTime? date,
  }) =>
      Event(
        id: id ?? this.id,
        name: name ?? this.name,
        amount: amount ?? this.amount,
        status: status ?? this.status,
        remark: remark ?? this.remark,
        date: date ?? this.date,
      );

  static Event fromJson(Map<String, Object?> json) => Event(
        id: json['id'] as int?,
        name: json['name'] as String,
        amount: json['amount'] as int,
        status: (json['status'] as int) == 1, // Convert integer to boolean
        remark: json['remark'] as String,
        date: DateTime.fromMillisecondsSinceEpoch(json['date'] as int),
      );

  Map<String, Object?> toJson() => {
        'id': id,
        'name': name,
        'amount': amount,
        'status': status ? 1 : 0, // Convert boolean to integer
        'remark': remark,
        'date': date.millisecondsSinceEpoch,
      };
}
