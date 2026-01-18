import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import '../database/database_helper.dart';
import '../models/backup_data.dart';
import '../models/transaction.dart';

enum ImportStrategy {
  replace, // Delete all existing data and replace with imported data
  merge, // Add imported transactions, skipping duplicates
  addAll, // Import all transactions even if they already exist
}

class ExportImportService {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  // Export all transactions to JSON string
  Future<String> exportToJson() async {
    try {
      final transactions = await _dbHelper.readAllTransactions();
      final backupData = BackupData.create(transactions);
      return backupData.toJson();
    } catch (e) {
      throw Exception('Failed to export data: $e');
    }
  }

  // Export to a file in the app's documents directory
  Future<String> exportToFile() async {
    try {
      final jsonData = await exportToJson();
      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
      final fileName = 'keb_tang_backup_$timestamp.json';
      final file = File('${directory.path}/$fileName');
      
      await file.writeAsString(jsonData);
      return file.path;
    } catch (e) {
      throw Exception('Failed to save backup file: $e');
    }
  }

  // Import from JSON string
  Future<int> importFromJson(String jsonString, ImportStrategy strategy) async {
    try {
      // Parse and validate JSON
      final backupData = BackupData.fromJson(jsonString);
      
      // Validate version compatibility (future-proofing)
      if (!_isVersionCompatible(backupData.version)) {
        throw Exception('Backup version ${backupData.version} is not compatible with this app version');
      }

      // Apply import strategy
      return await _applyImportStrategy(backupData.transactions, strategy);
    } catch (e) {
      throw Exception('Failed to import data: $e');
    }
  }

  // Import from a file
  Future<int> importFromFile(String filePath, ImportStrategy strategy) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        throw Exception('File not found: $filePath');
      }

      final jsonString = await file.readAsString();
      return await importFromJson(jsonString, strategy);
    } catch (e) {
      throw Exception('Failed to read backup file: $e');
    }
  }

  // Check if backup version is compatible
  bool _isVersionCompatible(String version) {
    // For now, we only support version 1.0.0
    // In the future, this can handle version migrations
    final supportedVersions = ['1.0.0'];
    return supportedVersions.contains(version);
  }

  // Apply the selected import strategy
  Future<int> _applyImportStrategy(
    List<Transaction> transactions,
    ImportStrategy strategy,
  ) async {
    switch (strategy) {
      case ImportStrategy.replace:
        return await _replaceAll(transactions);
      case ImportStrategy.merge:
        return await _mergeTransactions(transactions);
      case ImportStrategy.addAll:
        return await _addAll(transactions);
    }
  }

  // Replace strategy: Delete all existing data and import new data
  Future<int> _replaceAll(List<Transaction> transactions) async {
    try {
      final db = await _dbHelper.database;
      await db.delete('transactions'); // Clear all existing data
      
      int importedCount = 0;
      for (var transaction in transactions) {
        await _dbHelper.createTransaction(transaction);
        importedCount++;
      }
      return importedCount;
    } catch (e) {
      throw Exception('Failed to replace data: $e');
    }
  }

  // Merge strategy: Add new transactions, skip duplicates
  Future<int> _mergeTransactions(List<Transaction> transactions) async {
    try {
      final existingTransactions = await _dbHelper.readAllTransactions();
      int importedCount = 0;

      for (var transaction in transactions) {
        if (!_isDuplicate(transaction, existingTransactions)) {
          await _dbHelper.createTransaction(transaction);
          importedCount++;
        }
      }
      return importedCount;
    } catch (e) {
      throw Exception('Failed to merge data: $e');
    }
  }

  // Add all strategy: Import all transactions
  Future<int> _addAll(List<Transaction> transactions) async {
    try {
      int importedCount = 0;
      for (var transaction in transactions) {
        await _dbHelper.createTransaction(transaction);
        importedCount++;
      }
      return importedCount;
    } catch (e) {
      throw Exception('Failed to add data: $e');
    }
  }

  // Check if a transaction is a duplicate
  bool _isDuplicate(Transaction transaction, List<Transaction> existingTransactions) {
    return existingTransactions.any((existing) =>
        existing.title == transaction.title &&
        existing.amount == transaction.amount &&
        existing.type == transaction.type &&
        existing.category == transaction.category &&
        existing.date.isAtSameMomentAs(transaction.date) &&
        existing.description == transaction.description);
  }

  // Get a shareable file path for export
  Future<String> getShareableFilePath() async {
    try {
      final jsonData = await exportToJson();
      final directory = await getTemporaryDirectory();
      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
      final fileName = 'keb_tang_backup_$timestamp.json';
      final file = File('${directory.path}/$fileName');
      
      await file.writeAsString(jsonData);
      return file.path;
    } catch (e) {
      throw Exception('Failed to create shareable file: $e');
    }
  }
}
