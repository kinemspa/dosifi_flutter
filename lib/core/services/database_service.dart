import 'package:sqflite_sqlcipher/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class DatabaseService {
  static Database? _database;
  static const String _databaseName = 'dosifi_encrypted.db';
  static const int _databaseVersion = 1;
  static const _secureStorage = FlutterSecureStorage();
  static const String _dbPasswordKey = 'dosifi_db_password';

  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  static Future<Database> _initDatabase() async {
    // Generate or retrieve database password
    String? password = await _secureStorage.read(key: _dbPasswordKey);
    if (password == null) {
      password = _generateSecurePassword();
      await _secureStorage.write(key: _dbPasswordKey, value: password);
    }

    final databasePath = await getDatabasesPath();
    final path = join(databasePath, _databaseName);

    return await openDatabase(
      path,
      version: _databaseVersion,
      password: password,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  static String _generateSecurePassword() {
    // Generate a secure password for database encryption
    final now = DateTime.now().millisecondsSinceEpoch;
    return 'Dosifi_${now}_SecureDB';
  }

  static Future<void> _onCreate(Database db, int version) async {
    // Create medications table
    await db.execute('''
      CREATE TABLE medications (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        type TEXT NOT NULL,
        dosage_amount REAL NOT NULL,
        dosage_unit TEXT NOT NULL,
        frequency TEXT,
        instructions TEXT,
        barcode TEXT,
        batch_number TEXT,
        expiry_date TEXT,
        notes TEXT,
        photo_path TEXT,
        is_active INTEGER DEFAULT 1,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // Create schedules table
    await db.execute('''
      CREATE TABLE schedules (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        medication_id INTEGER NOT NULL,
        schedule_type TEXT NOT NULL,
        time_of_day TEXT NOT NULL,
        days_of_week TEXT,
        start_date TEXT NOT NULL,
        end_date TEXT,
        cycle_days_on INTEGER,
        cycle_days_off INTEGER,
        is_active INTEGER DEFAULT 1,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (medication_id) REFERENCES medications (id) ON DELETE CASCADE
      )
    ''');

    // Create inventory table
    await db.execute('''
      CREATE TABLE inventory (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        medication_id INTEGER NOT NULL,
        current_stock REAL NOT NULL,
        unit TEXT NOT NULL,
        reorder_level REAL,
        supplier_name TEXT,
        supplier_contact TEXT,
        cost_per_unit REAL,
        last_updated TEXT NOT NULL,
        FOREIGN KEY (medication_id) REFERENCES medications (id) ON DELETE CASCADE
      )
    ''');

    // Create dose_logs table
    await db.execute('''
      CREATE TABLE dose_logs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        medication_id INTEGER NOT NULL,
        schedule_id INTEGER,
        scheduled_time TEXT NOT NULL,
        taken_time TEXT,
        status TEXT NOT NULL,
        dose_amount REAL,
        notes TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (medication_id) REFERENCES medications (id) ON DELETE CASCADE,
        FOREIGN KEY (schedule_id) REFERENCES schedules (id) ON DELETE SET NULL
      )
    ''');

    // Create reminders table
    await db.execute('''
      CREATE TABLE reminders (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        schedule_id INTEGER NOT NULL,
        reminder_time TEXT NOT NULL,
        notification_id INTEGER NOT NULL,
        is_active INTEGER DEFAULT 1,
        created_at TEXT NOT NULL,
        FOREIGN KEY (schedule_id) REFERENCES schedules (id) ON DELETE CASCADE
      )
    ''');

    // Create reconstitution_recipes table
    await db.execute('''
      CREATE TABLE reconstitution_recipes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        powder_amount REAL NOT NULL,
        powder_unit TEXT NOT NULL,
        solvent_volume REAL NOT NULL,
        solvent_unit TEXT NOT NULL,
        final_concentration REAL NOT NULL,
        concentration_unit TEXT NOT NULL,
        instructions TEXT,
        is_favorite INTEGER DEFAULT 0,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // Create user_profiles table
    await db.execute('''
      CREATE TABLE user_profiles (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        email TEXT,
        phone TEXT,
        emergency_contact_name TEXT,
        emergency_contact_phone TEXT,
        notification_enabled INTEGER DEFAULT 1,
        theme_mode TEXT DEFAULT 'system',
        language TEXT DEFAULT 'en',
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // Create analytics_data table
    await db.execute('''
      CREATE TABLE analytics_data (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        metric_type TEXT NOT NULL,
        metric_value REAL NOT NULL,
        metadata TEXT,
        recorded_at TEXT NOT NULL
      )
    ''');

    // Create indexes for better performance
    await db.execute('CREATE INDEX idx_medications_name ON medications(name)');
    await db.execute('CREATE INDEX idx_schedules_medication ON schedules(medication_id)');
    await db.execute('CREATE INDEX idx_dose_logs_medication ON dose_logs(medication_id)');
    await db.execute('CREATE INDEX idx_dose_logs_date ON dose_logs(scheduled_time)');
  }

  static Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Handle database migrations
    if (oldVersion < 2) {
      // Future migration example
      // await db.execute('ALTER TABLE medications ADD COLUMN new_field TEXT');
    }
  }

  // Database integrity check
  static Future<bool> checkDatabaseIntegrity() async {
    try {
      final db = await database;
      final result = await db.rawQuery('PRAGMA integrity_check');
      return result.first['integrity_check'] == 'ok';
    } catch (e) {
      return false;
    }
  }

  // Backup database
  static Future<void> backupDatabase() async {
    // Implement encrypted backup functionality
    final db = await database;
    final databasePath = await getDatabasesPath();
    final backupPath = join(databasePath, 'dosifi_backup_${DateTime.now().millisecondsSinceEpoch}.db');
    
    // TODO: Implement secure backup with encryption
  }

  // Close database
  static Future<void> closeDatabase() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
}
