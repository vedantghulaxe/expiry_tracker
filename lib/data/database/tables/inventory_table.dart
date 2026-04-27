import 'package:drift/drift.dart';
import 'products_table.dart';

class Inventory extends Table {

  IntColumn get id => integer().autoIncrement()();

  IntColumn get productId =>
      integer().references(Products, #id)();

  IntColumn get quantity => integer().withDefault(const Constant(1))();

  DateTimeColumn get expiryDate => dateTime()();

  DateTimeColumn get addedDate =>
      dateTime().withDefault(currentDateAndTime)();

}