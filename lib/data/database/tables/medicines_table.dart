import 'package:drift/drift.dart';

class Medicines extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get symptoms => text().nullable()();
  TextColumn get dosage => text().nullable()();
  TextColumn get doctorName => text().nullable()();
  TextColumn get prescriptionImage => text().nullable()();
  DateTimeColumn get expiryDate => dateTime().nullable()();
  TextColumn get brand => text().nullable()();
  TextColumn get mrp => text().nullable()();
  TextColumn get batch => text().nullable()();
  TextColumn get manufacturer => text().nullable()();
  
  // ✅ DYNAMIC DATA COLUMN: Stores any other fields extracted by AI as JSON
  TextColumn get extraData => text().nullable()();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}
