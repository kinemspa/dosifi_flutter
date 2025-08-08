import 'package:sqflite_sqlcipher/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import 'dart:math';
import 'dart:convert';

class DatabaseService {
  static Database? _database;
  static const String _databaseName = 'dosifi_encrypted.db';
  static const int _databaseVersion = 8;
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
      onConfigure: (db) async {
        // Enforce foreign keys for referential integrity
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: _onCreate,n      onUpgrade: _onUpgrade,
    );
  }

  static String _generateSecurePassword() {
    // Generate a cryptographically secure random key for database encryption
    final rng = Random.secure();
    final bytes = List<int>.generate(32, (_) => rng.nextInt(256)); // 256-bit key
    return base64UrlEncode(bytes);
  }

  static Future<void> _onCreate(Database db, int version) async {
    // Create medications table
    await db.execute('''
      CREATE TABLE medications (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        type TEXT NOT NULL,
        brand_manufacturer TEXT,
        strength_per_unit REAL NOT NULL,
        strength_unit TEXT NOT NULL,
        stock_quantity REAL NOT NULL,
        reconstitution_volume REAL,
        final_concentration REAL,
        reconstitution_notes TEXT,
        lot_batch_number TEXT,
        expiration_date TEXT,
        description TEXT,
        instructions TEXT,
        notes TEXT,
        barcode TEXT,
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
        dose_amount REAL NOT NULL,
        dose_unit TEXT NOT NULL,
        dose_form TEXT NOT NULL,
        strength_per_unit REAL NOT NULL,
        is_active INTEGER DEFAULT 1,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
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

    // Create supplies table
    await db.execute('''
      CREATE TABLE supplies (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        category TEXT NOT NULL,
        brand TEXT,
        size TEXT,
        quantity INTEGER NOT NULL DEFAULT 0,
        reorder_level INTEGER,
        unit TEXT DEFAULT 'pieces',
        lot_number TEXT,
        expiration_date TEXT,
        location TEXT,
        notes TEXT,
        is_active INTEGER DEFAULT 1,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // Create medication_stock_logs table for comprehensive stock tracking
    await db.execute('''
      CREATE TABLE medication_stock_logs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        medication_id INTEGER NOT NULL,
        timestamp TEXT NOT NULL,
        change_amount REAL NOT NULL,
        new_total REAL NOT NULL,
        reason TEXT NOT NULL,
        notes TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (medication_id) REFERENCES medications (id) ON DELETE CASCADE
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
      // Migration from version 1 to 2: Update inventory table
      await db.execute('DROP TABLE IF EXISTS inventory');
      await db.execute('''
        CREATE TABLE inventory (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          medication_id INTEGER NOT NULL,
          quantity REAL NOT NULL,
          unit TEXT NOT NULL,
          reorder_level REAL,
          batch_number TEXT,
          expiry_date TEXT,
          location TEXT,
          notes TEXT,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL,
          FOREIGN KEY (medication_id) REFERENCES medications (id) ON DELETE CASCADE
        )
      ''');
    }
    
    if (oldVersion < 3) {
      // Migration from version 2 to 3: Update medications table
      // First, backup existing data
      await db.execute('ALTER TABLE medications RENAME TO medications_backup');
      
      // Create new medications table with updated schema
      await db.execute('''
        CREATE TABLE medications (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          type TEXT NOT NULL,
          brand_manufacturer TEXT,
          strength_per_unit REAL NOT NULL,
          strength_unit TEXT NOT NULL,
          number_of_units INTEGER NOT NULL,
          lot_batch_number TEXT,
          expiration_date TEXT,
          description TEXT,
          instructions TEXT,
          notes TEXT,
          barcode TEXT,
          photo_path TEXT,
          is_active INTEGER DEFAULT 1,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL
        )
      ''');
      
      // Migrate existing data (with defaults for new columns)
      await db.execute('''
        INSERT INTO medications (
          id, name, type, strength_per_unit, strength_unit, 
          number_of_units, lot_batch_number, expiration_date,
          instructions, notes, barcode, photo_path, is_active,
          created_at, updated_at
        )
        SELECT 
          id, name, type, dosage_amount, dosage_unit,
          0, batch_number, expiry_date,
          instructions, notes, barcode, photo_path, is_active,
          created_at, updated_at
        FROM medications_backup
      ''');
      
      // Drop the backup table
      await db.execute('DROP TABLE medications_backup');
    }
    
    if (oldVersion < 4) {
      // Migration from version 3 to 4: Add supplies table
      await db.execute('''
        CREATE TABLE IF NOT EXISTS supplies (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          category TEXT NOT NULL,
          brand TEXT,
          size TEXT,
          quantity INTEGER NOT NULL DEFAULT 0,
          reorder_level INTEGER,
          unit TEXT DEFAULT 'pieces',
          lot_number TEXT,
          expiration_date TEXT,
          location TEXT,
          notes TEXT,
          is_active INTEGER DEFAULT 1,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL
        )
      ''');
    }
    
    if (oldVersion < 5) {
      // Migration from version 4 to 5: Update medications table and remove inventory table
      
      // Drop inventory table as it's now redundant
      await db.execute('DROP TABLE IF EXISTS inventory');
      
      // Backup existing medications data
      await db.execute('ALTER TABLE medications RENAME TO medications_backup');
      
      // Create new medications table with updated schema
      await db.execute('''
        CREATE TABLE medications (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          type TEXT NOT NULL,
          brand_manufacturer TEXT,
          strength_per_unit REAL NOT NULL,
          strength_unit TEXT NOT NULL,
          stock_quantity REAL NOT NULL,
          reconstitution_volume REAL,
          final_concentration REAL,
          reconstitution_notes TEXT,
          lot_batch_number TEXT,
          expiration_date TEXT,
          description TEXT,
          instructions TEXT,
          notes TEXT,
          barcode TEXT,
          photo_path TEXT,
          is_active INTEGER DEFAULT 1,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL
        )
      ''');
      
      // Migrate existing data (with defaults for new columns)
      await db.execute('''
        INSERT INTO medications (
          id, name, type, brand_manufacturer, strength_per_unit, strength_unit, 
          stock_quantity, lot_batch_number, expiration_date,
          description, instructions, notes, barcode, photo_path, is_active,
          created_at, updated_at
        )
        SELECT 
          id, name, type, brand_manufacturer, strength_per_unit, strength_unit,
          COALESCE(number_of_units, 0), lot_batch_number, expiration_date,
          description, instructions, notes, barcode, photo_path, is_active,
          created_at, updated_at
        FROM medications_backup
      ''');
      
      // Drop the backup table
      await db.execute('DROP TABLE medications_backup');
    }
    
    if (oldVersion < 6) {
      // Migration from version 5 to 6: Fix stock_quantity column name
      try {
        // Check if medications table has number_of_units column
        final result = await db.rawQuery('PRAGMA table_info(medications)');
        final hasNumberOfUnits = result.any((col) => col['name'] == 'number_of_units');
        final hasStockQuantity = result.any((col) => col['name'] == 'stock_quantity');
        
        if (hasNumberOfUnits && !hasStockQuantity) {
          // Rename number_of_units to stock_quantity
          await db.execute('ALTER TABLE medications RENAME COLUMN number_of_units TO stock_quantity');
        }
      } catch (e) {
        // If the above fails, do a full table recreation
        await db.execute('ALTER TABLE medications RENAME TO medications_backup_v6');
        
        // Create new medications table
        await db.execute('''
          CREATE TABLE medications (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            type TEXT NOT NULL,
            brand_manufacturer TEXT,
            strength_per_unit REAL NOT NULL,
            strength_unit TEXT NOT NULL,
            stock_quantity REAL NOT NULL,
            reconstitution_volume REAL,
            final_concentration REAL,
            reconstitution_notes TEXT,
            lot_batch_number TEXT,
            expiration_date TEXT,
            description TEXT,
            instructions TEXT,
            notes TEXT,
            barcode TEXT,
            photo_path TEXT,
            is_active INTEGER DEFAULT 1,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL
          )
        ''');
        
        // Migrate data
        await db.execute('''
          INSERT INTO medications (
            id, name, type, brand_manufacturer, strength_per_unit, strength_unit, 
            stock_quantity, lot_batch_number, expiration_date,
            description, instructions, notes, barcode, photo_path, is_active,
            created_at, updated_at
          )
          SELECT 
            id, name, type, brand_manufacturer, strength_per_unit, strength_unit,
            COALESCE(number_of_units, stock_quantity, 0), lot_batch_number, expiration_date,
            description, instructions, notes, barcode, photo_path, is_active,
            created_at, updated_at
          FROM medications_backup_v6
        ''');
        
        await db.execute('DROP TABLE medications_backup_v6');
      }
    }
    
    if (oldVersion < 7) {
      // Migration from version 6 to 7: Add dose columns to schedules table
      try {
        // Check if schedules table already has dose columns
        final result = await db.rawQuery('PRAGMA table_info(schedules)');
        final hasDoseAmount = result.any((col) => col['name'] == 'dose_amount');
        
        if (!hasDoseAmount) {
          // Add dose columns to schedules table
          await db.execute('ALTER TABLE schedules ADD COLUMN dose_amount REAL DEFAULT 1.0');
          await db.execute('ALTER TABLE schedules ADD COLUMN dose_unit TEXT DEFAULT "tablet"');
          await db.execute('ALTER TABLE schedules ADD COLUMN dose_form TEXT DEFAULT "tablet"');
          await db.execute('ALTER TABLE schedules ADD COLUMN strength_per_unit REAL DEFAULT 1.0');
          
          // Update existing schedules with default values
          await db.execute('''
            UPDATE schedules 
            SET dose_amount = 1.0, 
                dose_unit = 'tablet',
                dose_form = 'tablet',
                strength_per_unit = 1.0
            WHERE dose_amount IS NULL
          ''');
          
          // Make dose columns NOT NULL
          await db.execute('ALTER TABLE schedules RENAME TO schedules_backup_v7');
          
          // Create new schedules table with proper schema
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
              dose_amount REAL NOT NULL,
              dose_unit TEXT NOT NULL,
              dose_form TEXT NOT NULL,
              strength_per_unit REAL NOT NULL,
              is_active INTEGER DEFAULT 1,
              created_at TEXT NOT NULL,
              updated_at TEXT NOT NULL,
              FOREIGN KEY (medication_id) REFERENCES medications (id) ON DELETE CASCADE
            )
          ''');
          
          // Migrate data
          await db.execute('''
            INSERT INTO schedules (
              id, medication_id, schedule_type, time_of_day, days_of_week,
              start_date, end_date, cycle_days_on, cycle_days_off,
              dose_amount, dose_unit, dose_form, strength_per_unit,
              is_active, created_at, updated_at
            )
            SELECT 
              id, medication_id, schedule_type, time_of_day, days_of_week,
              start_date, end_date, cycle_days_on, cycle_days_off,
              COALESCE(dose_amount, 1.0), COALESCE(dose_unit, 'tablet'),
              COALESCE(dose_form, 'tablet'), COALESCE(strength_per_unit, 1.0),
              is_active, created_at, updated_at
            FROM schedules_backup_v7
          ''');
          
          await db.execute('DROP TABLE schedules_backup_v7');
        }
      } catch (e) {
        // If migration fails, log error but continue
        debugPrint('Schedule table migration error: $e');
      }
    }
    
    if (oldVersion < 8) {
      // Migration from version 7 to 8: Update supplies table schema
      try {
        // Check if supplies table exists and has the correct structure
        final result = await db.rawQuery('PRAGMA table_info(supplies)');
        final hasTypeColumn = result.any((col) => col['name'] == 'type');
        final quantityColumn = result.firstWhere((col) => col['name'] == 'quantity', orElse: () => {});
        final reorderColumn = result.firstWhere((col) => col['name'] == 'reorder_level', orElse: () => {});
        
        // Check if we need to update the table
        bool needsUpdate = !hasTypeColumn || 
                          quantityColumn['type'] == 'INTEGER' || 
                          reorderColumn['type'] == 'INTEGER';
        
        if (needsUpdate) {
          // Backup existing supplies data
          await db.execute('ALTER TABLE supplies RENAME TO supplies_backup_v8');
          
          // Create new supplies table with correct schema
          await db.execute('''
            CREATE TABLE supplies (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              name TEXT NOT NULL,
              type TEXT NOT NULL,
              brand TEXT,
              size TEXT,
              quantity REAL NOT NULL DEFAULT 0.0,
              reorder_level REAL,
              unit TEXT DEFAULT 'pieces',
              lot_number TEXT,
              expiration_date TEXT,
              location TEXT,
              notes TEXT,
              is_active INTEGER DEFAULT 1,
              created_at TEXT NOT NULL,
              updated_at TEXT NOT NULL
            )
          ''');
          
          // Migrate existing data if any exists
          final existingData = await db.rawQuery('SELECT COUNT(*) as count FROM supplies_backup_v8');
          if ((existingData.first['count'] as int) > 0) {
            // Map old 'category' to 'type' and convert quantities to REAL
            await db.execute('''
              INSERT INTO supplies (
                id, name, type, brand, size, quantity, reorder_level,
                unit, lot_number, expiration_date, location, notes,
                is_active, created_at, updated_at
              )
              SELECT 
                id, name, 
                CASE 
                  WHEN LOWER(category) = 'fluid' THEN 'fluid'
                  WHEN LOWER(category) = 'diluent' THEN 'diluent'
                  ELSE 'item'
                END,
                brand, size, 
                CAST(quantity as REAL), 
                CAST(reorder_level as REAL),
                unit, lot_number, expiration_date, location, notes,
                is_active, created_at, updated_at
              FROM supplies_backup_v8
            ''');
          }
          
          // Drop the backup table
          await db.execute('DROP TABLE supplies_backup_v8');
        }
      } catch (e) {
        // If migration fails, log error but continue
        debugPrint('Supplies table migration error: $e');
      }
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
  static Future<String> backupDatabase() async {
    try {
      // Get database instance to ensure it's initialized
      final databasePath = await getDatabasesPath();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final backupPath = join(databasePath, 'dosifi_backup_$timestamp.db');
      
      // Copy database file to backup location
      final sourceFile = File(join(databasePath, _databaseName));
      if (await sourceFile.exists()) {
        await sourceFile.copy(backupPath);
        debugPrint('Database backup created at: $backupPath');
        return backupPath;
      } else {
        throw Exception('Source database file not found');
      }
    } catch (e) {
      debugPrint('Backup failed: $e');
      rethrow;
    }
  }

  // Close database
  static Future<void> closeDatabase() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
}
