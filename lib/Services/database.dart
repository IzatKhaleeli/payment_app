import 'dart:io';
import 'package:intl/intl.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'package:sqflite/sqflite.dart';
import '../Models/CheckImage.dart';

class DatabaseProvider {
  static Future<void> setVoucherNumberForCheckImages(
      int paymentId, String voucherSerialNumber) async {
    Database db = await database;
    await db.update(
      'check_images',
      {'voucherSerialNumber': voucherSerialNumber},
      where: 'paymentId = ?',
      whereArgs: [paymentId],
    );
  }

  static Future<List<Map<String, dynamic>>> getConfirmedCheckImages() async {
    Database db = await database;
    return await db
        .query('check_images', where: 'status = ?', whereArgs: ['confirmed']);
  }

  static const _databaseName = 'payments.db';
  static const _databaseVersion = 7;
  static Database? _database;
  DatabaseProvider._();

  static Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  static Future<Database> _initDatabase() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, _databaseName);
    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  static Future<void> _onUpgrade(
      Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
      ALTER TABLE payments ADD COLUMN isDepositChecked BOOLEAN DEFAULT 0;
    ''');
    }
    if (oldVersion < 3) {
      await db.execute('''
      ALTER TABLE payments ADD COLUMN transactionId TEXT;
    ''');
    }
    if (oldVersion < 4) {
      await db.execute('''
      ALTER TABLE payments ADD COLUMN msisdnReceipt TEXT;
    ''');
      await db.execute('''
      ALTER TABLE payments ADD COLUMN isDisconnected BOOLEAN DEFAULT 0;
    ''');

      await db.execute('''
    ALTER TABLE payments ADD COLUMN cancellationStatus TEXT;
  ''');
    }
    if (oldVersion < 5) {
      await db.execute('''
      ALTER TABLE payments ADD COLUMN checkApproval BOOLEAN DEFAULT 0;
    ''');
      await db.execute('''
      ALTER TABLE payments ADD COLUMN notifyFinance BOOLEAN DEFAULT 0;
    ''');
    }
    if (oldVersion < 6) {
      await db.execute('''
      CREATE TABLE IF NOT EXISTS check_images (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        voucherSerialNumber TEXT,
        fileName TEXT,
        mimeType TEXT,
        base64Content TEXT,
        status TEXT
      );
    ''');
    }
    if (oldVersion < 7) {
      try {
        await db
            .execute("ALTER TABLE check_images ADD COLUMN paymentId INTEGER;");
      } catch (e) {
        print('Column paymentId may already exist: $e');
      }
    }
  }

  static Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE payments (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        voucherSerialNumber TEXT,
        customerName TEXT,
        msisdn TEXT,
        prNumber TEXT,
        paymentMethod TEXT,
        amount REAL,
        amountCheck REAL,
        checkNumber NUMERIC,
        bankBranch TEXT,
        dueDateCheck TEXT,
        currency TEXT,
        paymentInvoiceFor TEXT,
        status TEXT,
        cancelReason TEXT,
        lastUpdatedDate TEXT,
        transactionDate TEXT,
        cancellationDate TEXT,
        userId ,
        isDepositChecked BOOLEAN DEFAULT 0,
  checkApproval BOOLEAN DEFAULT 0,
  notifyFinance BOOLEAN DEFAULT 0,
        transactionId TEXT,
        msisdnReceipt TEXT,
        isDisconnected BOOLEAN DEFAULT 0,
        cancellationStatus TEXT
      )
      
    ''');

    await db.execute('''
      CREATE TABLE currencies (
        id TEXT PRIMARY KEY,
        arabicName TEXT,
        englishName TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE banks(
        id TEXT PRIMARY KEY,
        arabicName TEXT,
        englishName TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS check_images (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        paymentId INTEGER,
        voucherSerialNumber TEXT,
        fileName TEXT,
        mimeType TEXT,
        base64Content TEXT,
        status TEXT
      );
    ''');
  }

  static Future<void> markAllCheckImagesAsSynced(
      String voucherNumber, String status) async {
    Database db = await database;
    await db.update(
      'check_images',
      {'status': 'synced'},
      where: 'voucherSerialNumber = ? AND status = ?',
      whereArgs: [voucherNumber, status],
    );
  }

  static Future<int> insertConfirmedCheckImage(
      Map<String, dynamic> imageData) async {
    Database db = await database;
    imageData['status'] = 'confirmed';
    return await db.insert('check_images', imageData,
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<List<int>> addCheckImagesToPayment(
      String voucherNumber, List<Map<String, dynamic>> images) async {
    Database db = await database;
    List<int> ids = [];
    await db.transaction((txn) async {
      for (var imageData in images) {
        imageData['voucherSerialNumber'] = voucherNumber;
        int id = await txn.insert('check_images', imageData,
            conflictAlgorithm: ConflictAlgorithm.ignore);
        ids.add(id);
      }
    });
    return ids;
  }

  static Future<void> updatePaymentsFromPortalStatus(
      List<Map<String, dynamic>> portalData) async {
    // print("updatePaymentsFromPortalStatus started");
    if (portalData.isEmpty) return;

    try {
      Database db = await database;

      await db.transaction((txn) async {
        for (var item in portalData) {
          final voucher = item['voucherSerialNumber'];
          final acceptanceStatus = item['acceptanceStatus'];
          final cancelStatus = item['cancelStatus'];

          if (voucher == null) continue;

          final Map<String, dynamic> updates = {};

          if (acceptanceStatus != null &&
              acceptanceStatus.toString().toLowerCase() != 'pending') {
            updates['status'] = acceptanceStatus.toString().toLowerCase();
          }

          if (cancelStatus != null &&
              cancelStatus.toString().toLowerCase() != 'pending') {
            updates['cancellationStatus'] =
                cancelStatus.toString().toLowerCase();
          }

          if (updates.isNotEmpty) {
            print(
                "Updating voucher $voucher → ${updates.map((k, v) => MapEntry(k, v))}");

            await txn.update(
              'payments',
              updates,
              where: 'voucherSerialNumber = ?',
              whereArgs: [voucher],
            );
          } else {
            // print("Skipping voucher $voucher — statuses are 'Pending' or null");
          }
        }
      });

      // print("updatePaymentsFromPortalStatus finished successfully");
    } catch (e) {
      print("Error updating portal statuses: $e");
      throw Exception('Failed to update payments from portal status');
    }
  }

  static Future<List<Map<String, dynamic>>> getAllPayments(
      String userId) async {
    print("printAllPayments method , database.dart started");

    Database db = await database;

    // Query the database to get all payments based on userId
    List<Map<String, dynamic>> payments = await db.query(
      'payments',
      where: 'userId = ?',
      whereArgs: [userId],
    );
    print("printAllPayments method , database.dart finished");
    return payments;
  }

  //Retrieve ConfirmedPayments
  static Future<List<Map<String, dynamic>>>
      getConfirmedOrCancelledPendingPayments() async {
    // print(
    //     "getConfirmedOrCancelledPendingPayments method , database.dart started");

    Database db = await database;

    List<Map<String, dynamic>> payments = await db.query(
      'payments',
      where: 'status = ? OR cancellationStatus = ?',
      whereArgs: ['Confirmed', 'CancelPending'],
    );

    return payments;
  }

  //Retrieve a specific payment
  static Future<Map<String, dynamic>?> getPaymentById(int id) async {
    // print("getPaymentById method , database.dart started");

    Database db = await database;
    List<Map<String, dynamic>> result = await db.query(
      'payments',
      where: 'id = ?',
      whereArgs: [id],
    );
    return result.isNotEmpty ? result.first : null;
  }

  static Future<void> updateSyncedPaymentDetail(
      int id, String voucherSerialNumber, String status) async {
    // print("updateSyncedPaymentDetail method , database.dart started");

    try {
      Database db = await database;

      // Validate the voucherSerialNumber
      if (voucherSerialNumber.isEmpty) {
        throw ArgumentError('Voucher serial number must not be empty');
      }

      // Prepare the values to update
      Map<String, dynamic> updates = {
        'voucherSerialNumber': voucherSerialNumber,
        'status': status,
      };

      // Perform the update operation
      int updatedRows = await db.update(
        'payments',
        updates,
        where: 'id = ?',
        whereArgs: [id],
      );

      if (updatedRows > 0) {
        print('Payment details updated successfully for payment with id $id');
      } else {
        throw Exception('Payment with id $id not found');
      }
    } catch (e) {
      print('Error updating payment details: $e');
      // Handle the error as per your application's requirements
      throw Exception('Failed to update payment details');
    }
  }

  // Update payment status
  static Future<void> updatePaymentStatus(int id, String status) async {
    print("updatePaymentStatus method , database.dart started");

    try {
      Database db = await database;
      // Update payment status
      await db.update(
        'payments',
        {'status': status},
        where: 'id = ?',
        whereArgs: [id],
      );
      print('Payment status updated successfully for payment with id $id');

      // If the status is 'Confirmed', also update the transaction date
      if (status.toLowerCase() == 'confirmed') {
        await updateTransactionDate(id);
      }
    } catch (e) {
      print('Error updating payment status: $e');
      throw Exception('Failed to update payment status');
    }
  }

  static Future<void> updateCancellationStatus(int id, String status) async {
    print("updateCancellationStatus method , database.dart started");

    try {
      Database db = await database;
      // Update payment status
      await db.update(
        'payments',
        {'cancellationStatus': status},
        where: 'id = ?',
        whereArgs: [id],
      );
      print('Payment status updated successfully for payment with id $id');

      // If the status is 'Confirmed', also update the transaction date
      if (status.toLowerCase() == 'confirmed') {
        await updateTransactionDate(id);
      }
    } catch (e) {
      print('Error updating payment status: $e');
      throw Exception('Failed to update payment status');
    }
  }

  // Update Transaction Date
  static Future<void> updateTransactionDate(int id) async {
    print("updateTransactionDate method , database.dart started");

    try {
      Database db = await database;
      Map<String, dynamic>? payment = await getPaymentById(id);
      if (payment != null) {
        String? currentTransactionDate = payment['transactionDate'];

        // Only update if the current transaction date is null
        if (currentTransactionDate == null) {
          String now = formatDateTimeWithMilliseconds(DateTime.now());
          await db.update(
            'payments',
            {'transactionDate': now},
            where: 'id = ?',
            whereArgs: [id],
          );
          print('Transaction date updated to now for payment with id $id');
        } else {
          print(
              'Transaction date already exists for payment with id $id. Skipping update.');
        }
      } else {
        throw Exception('Payment with id $id not found');
      }
    } catch (e) {
      print('Error updating transaction date: $e');
      throw Exception('Failed to update transaction date');
    }
  }

  // Update last Update Date
  static Future<void> updateLastUpdatedDate(
      int id, String lastUpdatedDate) async {
    print("updateLastUpdatedDate method , database.dart started");

    try {
      Database db = await database;
      await db.update(
        'payments',
        {'lastUpdatedDate': lastUpdatedDate},
        where: 'id = ?',
        whereArgs: [id],
      );
      print('Last updated date updated for payment with id $id');
    } catch (e) {
      print('Error updating last updated date: $e');
      throw Exception('Failed to update last updated date');
    }
  }

  static Future<void> updatePayment(
      int id, Map<String, dynamic> updatedData) async {
    print("updatePayment method in database.dart started");
    print(updatedData);
    updatedData['lastUpdatedDate'] =
        formatDateTimeWithMilliseconds(DateTime.now());
    if (updatedData["status"].toLowerCase() == "confirmed") {
      updatedData['transactionDate'] =
          formatDateTimeWithMilliseconds(DateTime.now());
    }
    Database db = await database;
    await db.update('payments', updatedData, where: 'id = ?', whereArgs: [id]);
    print("updatePayment method in database.dart finished");
  }

  static Future<int> savePayment(Map<String, dynamic> paymentData) async {
    print("savePayment method in database.dart started");
    Database db = await database;

    if (paymentData['status'] != null &&
        paymentData['status'].toLowerCase() == 'confirmed') {
      paymentData['transactionDate'] =
          formatDateTimeWithMilliseconds(DateTime.now());
      paymentData['lastUpdatedDate'] =
          formatDateTimeWithMilliseconds(DateTime.now());
    } else if (paymentData['status'] != null &&
        paymentData['status'].toLowerCase() == 'saved') {
      // Set the last updated date to now
      paymentData['lastUpdatedDate'] =
          formatDateTimeWithMilliseconds(DateTime.now());
    }

    var uuid = Uuid();
    paymentData['transactionId'] = uuid.v4();

    int id = await db.insert('payments', paymentData);
    print("the id of new payment is to return : ${id}");
    Map<String, dynamic>? newPayment = await getPaymentById(id);
    // print("the new payment after saved to db : $newPayment");
    // print("savePayment method in database.dart finished");
    return id;
  }

  // Delete a payment by ID
  static Future<void> deletePayment(int id) async {
    print("deletePayment method , database.dart started");

    Database db = await database;
    await db.delete('payments', where: 'id = ?', whereArgs: [id]);
  }

  static Future<void> deleteRecordsOlderThan(int days) async {
    print("deleteRecordsOlderThan method , database.dart started");

    Database db = await database;

    // Calculate the threshold date
    DateTime now = DateTime.now();
    DateTime thresholdDate = now.subtract(Duration(days: days));

    // Start of day for threshold date
    DateTime startOfDay =
        DateTime(thresholdDate.year, thresholdDate.month, thresholdDate.day);

    // Log the threshold date for debugging
    // print('Deleting records older than: ${startOfDay.toIso8601String()}');

    try {
      await db.transaction((Transaction txn) async {
        // Execute delete commands within the transaction
        await txn.execute(
          'DELETE FROM payments WHERE status != ? AND transactionDate < ?',
          ['saved', startOfDay.toIso8601String()],
        );
        await txn.execute(
          'DELETE FROM payments WHERE status = ? AND lastUpdatedDate < ?',
          ['saved', startOfDay.toIso8601String()],
        );
      });
    } catch (e) {
      print('Error during delete operation: $e');
    }
  }

  // Clear Date base
  static Future<void> clearDatabase() async {
    Database db = await database;
    await db.delete('payments');
    print('Database cleared');
  }

  static String formatDateTimeWithMilliseconds(DateTime dateTime) {
    print("formatDateTimeWithMilliseconds method , database.dart started");

    final DateFormat formatter = DateFormat('yyyy-MM-ddTHH:mm:ss.SSS');
    print(formatter.format(
        dateTime)); // This should print the date and time without milliseconds
    return formatter.format(dateTime);
  }

  // Cancel a payment by voucherSerialNumber
// Cancel a payment by voucherSerialNumber
  static Future<void> cancelPayment(
      String voucherSerialNumber,
      String cancelReason,
      String formattedCancelDateTime,
      String newStatus) async {
    print("cancelPayment method, database.dart started");
    try {
      Database db = await database;

      await db.update(
        'payments',
        {
          'cancellationStatus': newStatus,
          'cancelReason': cancelReason,
          'cancellationDate': formattedCancelDateTime,
        },
        where: 'voucherSerialNumber = ?',
        whereArgs: [voucherSerialNumber],
      );

      print(
          'Payment with voucherSerialNumber $voucherSerialNumber has been cancelled with these details : ${cancelReason}:${formattedCancelDateTime}');
    } catch (e) {
      print('Error cancelling payment: $e');
      throw Exception('Failed to cancel payment');
    }
    print("cancelPayment method, database.dart finished");
  }

  static Future<List<Map<String, dynamic>>> getPaymentsWithDateFilter(
      DateTime? fromDate,
      DateTime? toDate,
      List<String>? statuses,
      List<String>? cancellationStatuses,
      String userId) async {
    Database db = await database;

    // Start with the base query
    String query = 'SELECT * FROM payments WHERE userId = "$userId"';

    // Add date filters if they are provided
    if (fromDate != null && fromDate.toString().isNotEmpty) {
      query += ' AND transactionDate >= "${fromDate.toIso8601String()}"';
    }
    if (toDate != null && toDate.toString().isNotEmpty) {
      DateTime endOfDay =
          DateTime(toDate.year, toDate.month, toDate.day, 23, 59, 59);
      query += ' AND transactionDate <= "${endOfDay.toIso8601String()}"';
    }

    // Add status filters if they are provided
    if (statuses != null && statuses.isNotEmpty) {
      // Escape single quotes in statuses
      statuses =
          statuses.map((status) => status.replaceAll("'", "''")).toList();
      String statusList = statuses.map((status) => "'$status'").join(', ');
      query += ' AND status IN ($statusList)';
    }

    if (cancellationStatuses != null && cancellationStatuses.isNotEmpty) {
      cancellationStatuses =
          cancellationStatuses.map((s) => s.replaceAll("'", "''")).toList();
      String cancelList = cancellationStatuses.map((s) => "'$s'").join(', ');
      query += ' AND cancellationStatus IN ($cancelList)';
    }

    // Execute the query
    List<Map<String, dynamic>> result = await db.rawQuery(query);
    return result;
  }

  // CRUD operations for the currencies table
  // Insert a currency record
  static Future<void> insertCurrency(Map<String, dynamic> currencyData) async {
    Database db = await database;
    await db.insert('currencies', currencyData,
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  // Retrieve all currency records
  static Future<List<Map<String, dynamic>>> getAllCurrencies() async {
    Database db = await database;
    List<Map<String, dynamic>> currencies = await db.query('currencies');
    return currencies;
  }

  // Retrieve a specific currency by ID
  static Future<Map<String, dynamic>?> getCurrencyById(String id) async {
    Database db = await database;
    List<Map<String, dynamic>> result = await db.query(
      'currencies',
      where: 'id = ?',
      whereArgs: [id],
    );
    return result.isNotEmpty ? result.first : null;
  }

  // Update a currency record
  static Future<void> updateCurrency(
      String id, Map<String, dynamic> updatedData) async {
    Database db = await database;
    await db.update(
      'currencies',
      updatedData,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  static Future<void> clearAllCurrencies() async {
    final db = await database;
    await db.delete(
        'currencies'); // Replace 'currencies' with your actual table name
  }

  // Delete a currency record by ID
  static Future<void> deleteCurrency(String id) async {
    print("deleteCurrency method in database.dart started");
    Database db = await database;
    await db.delete('currencies', where: 'id = ?', whereArgs: [id]);
    print("deleteCurrency method in database.dart finished");
  }

  // Clear the currencies table
  static Future<void> clearCurrencies() async {
    print("clearCurrencies method in database.dart started");
    Database db = await database;
    await db.delete('currencies');
    print('Currencies table cleared');
    print("clearCurrencies method in database.dart finished");
  }

  //crud operations for bank
  static Future<void> insertBank(Map<String, dynamic> bankData) async {
    Database db = await database;
    await db.insert('banks', bankData,
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<List<Map<String, dynamic>>> getAllBanks() async {
    Database db = await database;
    return await db.query('banks');
  }

  static Future<Map<String, dynamic>?> getBankById(String id) async {
    Database db = await database;
    List<Map<String, dynamic>> result = await db.query(
      'banks',
      where: 'id = ?',
      whereArgs: [id],
    );
    return result.isNotEmpty ? result.first : null;
  }

  static Future<void> updateBank(
      String id, Map<String, dynamic> updatedData) async {
    Database db = await database;
    await db.update(
      'banks',
      updatedData,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  static Future<void> deleteBank(String id) async {
    Database db = await database;
    await db.delete('banks', where: 'id = ?', whereArgs: [id]);
  }

  static Future<void> clearAllBanks() async {
    Database db = await database;
    await db.delete('banks');
  }

  // Check images helpers
  static Future<int> insertCheckImage(Map<String, dynamic> imageData) async {
    Database db = await database;
    return await db.insert('check_images', imageData,
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<List<Map<String, dynamic>>> getCheckImagesByPaymentId(
      int paymentId) async {
    Database db = await database;
    return await db
        .query('check_images', where: 'paymentId = ?', whereArgs: [paymentId]);
  }

  static Future<void> deleteCheckImage(int id) async {
    Database db = await database;
    await db.delete('check_images', where: 'id = ?', whereArgs: [id]);
  }

  // Insert multiple check images in a transaction. Returns list of inserted row ids.
  static Future<List<int>> insertCheckImages(List<CheckImage> images) async {
    final db = await database;
    List<int> ids = [];
    await db.transaction((txn) async {
      for (var img in images) {
        final map = img.toMap();
        int id = await txn.insert('check_images', map,
            conflictAlgorithm: ConflictAlgorithm.replace);
        ids.add(id);
      }
    });
    return ids;
  }
}
