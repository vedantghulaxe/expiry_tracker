import 'package:flutter/material.dart';

import '../../core/services/database_service.dart';
import '../../data/repositories/medicine_repository.dart';

class MedicineSearchScreen extends StatefulWidget {
  const MedicineSearchScreen({super.key});

  @override
  State<MedicineSearchScreen> createState() => _MedicineSearchScreenState();
}

class _MedicineSearchScreenState extends State<MedicineSearchScreen> {

  final searchController = TextEditingController();

  late MedicineRepository repository;

  List medicines = [];

  @override
  void initState() {
    super.initState();
    repository = MedicineRepository(DatabaseService().db);
  }

  Future<void> search() async {

    final result =
    await repository.searchMedicines(searchController.text);

    setState(() {
      medicines = result;
    });
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      appBar: AppBar(
        title: const Text("Search Medicine by Symptoms"),
      ),

      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(

          children: [

            TextField(
              controller: searchController,
              decoration: const InputDecoration(
                labelText: "Enter symptom (fever, headache)",
              ),
            ),

            const SizedBox(height: 10),

            ElevatedButton(
              onPressed: search,
              child: const Text("Search"),
            ),

            const SizedBox(height: 20),

            Expanded(
              child: ListView.builder(

                itemCount: medicines.length,

                itemBuilder: (context, index) {

                  final med = medicines[index];

                  return Card(
                    child: ListTile(
                      title: Text(med.name),
                      subtitle: Text(
                        "Dosage: ${med.dosage ?? ""}\nDoctor: ${med.doctorName ?? ""}",
                      ),
                    ),
                  );
                },
              ),
            )
          ],
        ),
      ),
    );
  }
}