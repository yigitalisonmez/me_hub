class QuickAddAmount {
  final int amountMl;
  final String label;

  const QuickAddAmount({
    required this.amountMl,
    required this.label,
  });

  Map<String, dynamic> toJson() => {
        'amountMl': amountMl,
        'label': label,
      };

  factory QuickAddAmount.fromJson(Map<String, dynamic> json) => QuickAddAmount(
        amountMl: json['amountMl'] as int,
        label: json['label'] as String,
      );

  QuickAddAmount copyWith({
    int? amountMl,
    String? label,
  }) =>
      QuickAddAmount(
        amountMl: amountMl ?? this.amountMl,
        label: label ?? this.label,
      );
}

