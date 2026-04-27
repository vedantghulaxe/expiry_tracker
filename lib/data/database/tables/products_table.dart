import 'package:drift/drift.dart';

class Products extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get brand => text().nullable()();
  TextColumn get category => text().nullable()();
  TextColumn get quantity => text().nullable()();
  TextColumn get ingredients => text().nullable()();
  TextColumn get notes => text().nullable()();
  TextColumn get imagePath => text().nullable()();
  DateTimeColumn get expiryDate => dateTime().nullable()();
  DateTimeColumn get manufacturingDate => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}