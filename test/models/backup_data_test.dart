import 'package:flutter_test/flutter_test.dart';
import 'package:keb_tang/models/backup_data.dart';
import 'package:keb_tang/models/transaction.dart';
import 'package:keb_tang/models/transaction_type.dart';

void main() {
  group('BackupData Tests', () {
    test('should properly serialize and deserialize BackupData', () {
      final transaction = Transaction(
        id: 1,
        title: 'Test Transaction',
        amount: 100.0,
        type: TransactionType.expense,
        category: 'Food',
        date: DateTime(2023, 1, 1),
        description: 'Lunch',
      );

      final backupData = BackupData(
        version: '1.0.0',
        exportDate: DateTime(2023, 1, 2),
        transactionCount: 1,
        transactions: [transaction],
      );

      final json = backupData.toJson();
      final decoded = BackupData.fromJson(json);

      expect(decoded.version, '1.0.0');
      expect(decoded.transactionCount, 1);
      expect(decoded.transactions.length, 1);
      expect(decoded.transactions.first.title, 'Test Transaction');
      expect(decoded.transactions.first.amount, 100.0);
      expect(decoded.transactions.first.type, TransactionType.expense);
    });

    test('should handle empty transaction list', () {
      final backupData = BackupData(
        version: '1.0.0',
        exportDate: DateTime.now(),
        transactionCount: 0,
        transactions: [],
      );

      final json = backupData.toJson();
      final decoded = BackupData.fromJson(json);

      expect(decoded.transactions, isEmpty);
      expect(decoded.transactionCount, 0);
    });
  });
}
