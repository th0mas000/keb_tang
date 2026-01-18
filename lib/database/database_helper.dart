import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' show join;
import '../models/transaction.dart' as models;
import '../models/transaction_type.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('transactions.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const textType = 'TEXT NOT NULL';
    const realType = 'REAL NOT NULL';

    await db.execute('''
      CREATE TABLE transactions (
        id $idType,
        title $textType,
        amount $realType,
        type $textType,
        category TEXT,
        date $textType,
        description TEXT,
        created_at $textType
      )
    ''');
  }

  // Create a new transaction
  Future<models.Transaction> createTransaction(models.Transaction transaction) async {
    final db = await database;
    final id = await db.insert('transactions', transaction.toMap());
    return transaction.copyWith(id: id);
  }

  // Read a single transaction by ID
  Future<models.Transaction?> readTransaction(int id) async {
    final db = await database;
    final maps = await db.query(
      'transactions',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return models.Transaction.fromMap(maps.first);
    }
    return null;
  }

  // Read all transactions
  Future<List<models.Transaction>> readAllTransactions() async {
    final db = await database;
    const orderBy = 'date DESC';
    final result = await db.query('transactions', orderBy: orderBy);
    return result.map((json) => models.Transaction.fromMap(json)).toList();
  }

  // Read transactions by type
  Future<List<models.Transaction>> readTransactionsByType(
      TransactionType type) async {
    final db = await database;
    final result = await db.query(
      'transactions',
      where: 'type = ?',
      whereArgs: [type.name],
      orderBy: 'date DESC',
    );
    return result.map((json) => models.Transaction.fromMap(json)).toList();
  }

  // Update a transaction
  Future<int> updateTransaction(models.Transaction transaction) async {
    final db = await database;
    return db.update(
      'transactions',
      transaction.toMap(),
      where: 'id = ?',
      whereArgs: [transaction.id],
    );
  }

  // Delete a transaction
  Future<int> deleteTransaction(int id) async {
    final db = await database;
    return await db.delete(
      'transactions',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Get total income
  Future<double> getTotalIncome() async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT SUM(amount) as total FROM transactions WHERE type = ?',
      [TransactionType.income.name],
    );
    return (result.first['total'] as double?) ?? 0.0;
  }

  // Get total expenses
  Future<double> getTotalExpenses() async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT SUM(amount) as total FROM transactions WHERE type = ?',
      [TransactionType.expense.name],
    );
    return (result.first['total'] as double?) ?? 0.0;
  }

  // Get balance (income - expenses)
  Future<double> getBalance() async {
    final income = await getTotalIncome();
    final expenses = await getTotalExpenses();
    return income - expenses;
  }

  // Close the database
  Future<void> close() async {
    final db = await database;
    db.close();
  }
}
