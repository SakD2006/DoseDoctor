import 'package:flutter/material.dart';
import '../prescription/prescription_form_screen.dart';

class PatientDetailsScreen extends StatelessWidget {
  final String patientId;
  final Map<String, dynamic> patientData;

  const PatientDetailsScreen({
    Key? key,
    required this.patientId,
    required this.patientData,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Extract patient details from the provided data.
    final String name = patientData['Name'] ?? 'Unknown';
    final int age = patientData['Age'] ?? 0;
    final String gender = patientData['Gender'] ?? 'N/A';
    final String weight = patientData['Weight'] ?? 'N/A';
    final String height = patientData['Height'] ?? 'N/A';
    final Map<String, dynamic> mealTiming = patientData['Meal-timing'] ?? {};
    final String breakfast = mealTiming['Breakfast'] ?? 'N/A';
    final String lunch = mealTiming['Lunch'] ?? 'N/A';
    final String dinner = mealTiming['Dinner'] ?? 'N/A';

    return Scaffold(
      appBar: AppBar(title: const Text("Patient Details")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
          ),
          elevation: 4,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Patient ID: $patientId",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text("Name: $name", style: const TextStyle(fontSize: 16)),
                const SizedBox(height: 8),
                Text("Age: $age", style: const TextStyle(fontSize: 16)),
                const SizedBox(height: 8),
                const Text(
                  "Meal Timing:",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  "Breakfast: $breakfast",
                  style: const TextStyle(fontSize: 16),
                ),
                Text("Lunch: $lunch", style: const TextStyle(fontSize: 16)),
                Text("Dinner: $dinner", style: const TextStyle(fontSize: 16)),
              ],
            ),
          ),
        ),
      ),
      /*floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // TODO: Navigate to the prescription creation screen.
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => PrescriptionFormScreen()),
          );
        },
        label: const Text("Add Prescription"),
        icon: const Icon(Icons.add),
        // Making it pill-shaped with rounded edges:
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30.0),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      */
    );
  }
}
