import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../prescription/prescription_form_screen.dart';
import 'medication_history_screen.dart';

class PatientDetailsScreen extends StatelessWidget {
  final String patientId;
  final Map<String, dynamic> patientData;
  final String doctorName;

  const PatientDetailsScreen({
    super.key,
    required this.patientId,
    required this.patientData,
    required this.doctorName,
  });

  String formatTimestampToTime(dynamic value) {
    if (value is Timestamp) {
      DateTime dateTime = value.toDate();
      return DateFormat('h:mm a').format(dateTime);
    }
    return 'N/A';
  }

  @override
  Widget build(BuildContext context) {
    // Extract patient details from the provided data.
    final String firstName = patientData['First Name'] ?? 'Unknown';
    final String lastName = patientData['Last Name'] ?? 'Unknown';
    final String name = "$firstName $lastName";
    final int age = patientData['Age'] ?? 0;
    final String gender = patientData['Gender'] ?? 'N/A';
    final String weight = patientData['Weight'] ?? 'N/A';
    final String height = patientData['Height'] ?? 'N/A';
    final Map<String, dynamic> mealTiming = patientData['Meal-timing'] ?? {};
    final Timestamp breakfast = mealTiming['Breakfast'];
    final Timestamp lunch = mealTiming['Lunch'];
    final Timestamp dinner = mealTiming['Dinner'];

    return Scaffold(
      appBar: AppBar(
        title: const Text("Patient Details"),
        backgroundColor: Colors.blue.shade700,
        elevation: 0,
      ),
      body: Container(
        color: Colors.blue.shade50,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Patient ID and Name Card
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16.0),
                ),
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 30,
                            backgroundColor: Colors.blue.shade100,
                            child: Text(
                              name.isNotEmpty ? name[0].toUpperCase() : "?",
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue.shade700,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  name,
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "Patient ID: $patientId",
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Basic Information Card
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16.0),
                ),
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Personal Information",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          _buildInfoItem(Icons.cake, "Age", "$age years"),
                          _buildInfoItem(
                            gender == "Male" ? Icons.male : Icons.female,
                            "Gender",
                            gender,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          _buildInfoItem(Icons.height, "Height", "$height cm"),
                          _buildInfoItem(
                            Icons.fitness_center,
                            "Weight",
                            "$weight kg",
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Meal Timing Card
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16.0),
                ),
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Meal Timing Schedule",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildMealTimingItem(
                        Icons.wb_sunny,
                        "Breakfast",
                        formatTimestampToTime(breakfast),
                      ),
                      const Divider(),
                      _buildMealTimingItem(
                        Icons.wb_twighlight,
                        "Lunch",
                        formatTimestampToTime(lunch),
                      ),
                      const Divider(),
                      _buildMealTimingItem(
                        Icons.nightlight_round,
                        "Dinner",
                        formatTimestampToTime(dinner),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (context) => PrescriptionFormScreen(
                    patientId: patientId,
                    patientName: name,
                    patientData: patientData,
                    doctorName: doctorName,
                  ),
            ),
          );
        },
        label: const Text(
          "Add Prescription",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        icon: const Icon(Icons.add, color: Colors.white),
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30.0),
        ),
        backgroundColor: Colors.blue.shade700,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: BottomAppBar(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: const Icon(Icons.history),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) =>
                            MedicationHistoryScreen(patientId: patientId),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String label, String value) {
    return Expanded(
      child: Row(
        children: [
          Icon(icon, color: Colors.blue.shade700),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMealTimingItem(IconData icon, String mealName, String time) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.blue.shade700, size: 28),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  mealName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Text(
            time,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
