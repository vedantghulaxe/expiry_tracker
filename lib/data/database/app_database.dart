import 'dart:io';

import 'dart:async';

import 'package:drift/drift.dart';

import 'package:drift/native.dart';

import 'package:path_provider/path_provider.dart';

import 'package:path/path.dart' as p;



import 'tables/products_table.dart';

import 'tables/inventory_table.dart';

import 'tables/medicines_table.dart';

import '../../models/product_info.dart';



part 'app_database.g.dart';



@DriftDatabase(

  tables: [

    Products,

    Inventory,

    Medicines,

  ],

)

class AppDatabase extends _$AppDatabase {

  AppDatabase() : super(_openConnection());



  @override

  int get schemaVersion => 3;



  @override

  MigrationStrategy get migration {

    return MigrationStrategy(

      onCreate: (m) async {

        await m.createAll();

      },

      onUpgrade: (m, from, to) async {

        if (from < 2) {

          await m.createTable(medicines);

        }

        if (from < 3) {

          // Add new columns to Medicines table

          // Note: Drift migration uses GeneratedColumn for addColumn. 

          // If the build runner hasn't run, these might show errors, but will be fixed after generation.

          await m.addColumn(medicines, medicines.brand);

          await m.addColumn(medicines, medicines.mrp);

          await m.addColumn(medicines, medicines.batch);

          await m.addColumn(medicines, medicines.manufacturer);

          await m.addColumn(medicines, medicines.extraData);

          await m.addColumn(medicines, medicines.createdAt);

          await m.addColumn(medicines, medicines.updatedAt);

        }

      },

    );

  }



  // Add methods for accessing all items

  Future<List<ProductInfo>> getAllItems() async {

    final productsData = await (select(products)..get()).get();

    final medicinesData = await (select(medicines)..get()).get();

    

    final List<ProductInfo> allItems = [];

    

    for (final product in productsData) {

      allItems.add(ProductInfo(

        name: product.name,

        brand: product.brand,

        category: product.category,

        quantity: product.quantity,

        ingredients: product.ingredients,

        expiryDate: product.expiryDate,

        mfgDate: product.manufacturingDate,

        createdAt: product.createdAt,

        source: 'database',

      ));

    }

    

    for (final medicine in medicinesData) {

      allItems.add(ProductInfo(

        name: medicine.name,

        brand: medicine.brand,

        category: 'medicine',

        dosage: medicine.dosage,

        expiryDate: medicine.expiryDate,

        createdAt: medicine.createdAt,

        source: 'database',

      ));

    }

    

    return allItems;

  }



  Stream<List<ProductInfo>> get allItemsStream {

    return Stream.periodic(Duration(seconds: 1)).asyncMap((_) async {

      return await getAllItems();

    });

  }

}



LazyDatabase _openConnection() {

  return LazyDatabase(() async {

    final dbFolder = await getApplicationDocumentsDirectory();

    final file = File(p.join(dbFolder.path, 'expiry_tracker.db'));

    return NativeDatabase(file);

  });

}

