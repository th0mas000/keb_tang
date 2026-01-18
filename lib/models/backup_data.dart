import 'dart:convert';
import 'transaction.dart';

class BackupData {
  final String version;
  final DateTime exportDate;
  final int transactionCount;
  final List<Transaction> transactions;

  BackupData({
    required this.version,
    required this.exportDate,
    required this.transactionCount,
    required this.transactions,
  });

  // Convert BackupData to JSON Map
  Map<String, dynamic> toMap() {
    return {
      'version': version,
      'exportDate': exportDate.toIso8601String(),
      'transactionCount': transactionCount,
      'transactions': transactions.map((t) => t.toMap()).toList(),
    };
  }

  // Create BackupData from JSON Map
  factory BackupData.fromMap(Map<String, dynamic> map) {
    return BackupData(
      version: map['version'] as String,
      exportDate: DateTime.parse(map['exportDate'] as String),
      transactionCount: map['transactionCount'] as int,
      transactions: (map['transactions'] as List<dynamic>)
          .map((t) => Transaction.fromMap(t as Map<String, dynamic>))
          .toList(),
    );
  }

  // Convert to JSON string
  String toJson() => json.encode(toMap());

  // Create from JSON string
  factory BackupData.fromJson(String source) =>
      BackupData.fromMap(json.decode(source) as Map<String, dynamic>);

  // Create backup from transaction list
  factory BackupData.create(List<Transaction> transactions) {
    return BackupData(
      version: '1.0.0',
      exportDate: DateTime.now(),
      transactionCount: transactions.length,
      transactions: transactions,
    );
  }
}
