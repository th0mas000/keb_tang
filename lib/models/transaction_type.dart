enum TransactionType {
  income,
  expense;

  String get displayName {
    switch (this) {
      case TransactionType.income:
        return 'Income';
      case TransactionType.expense:
        return 'Expense';
    }
  }

  static TransactionType fromString(String value) {
    return TransactionType.values.firstWhere(
      (type) => type.name == value.toLowerCase(),
      orElse: () => TransactionType.expense,
    );
  }
}
