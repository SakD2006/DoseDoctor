import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class MedicationHistoryScreen extends StatefulWidget {
  final String patientId;

  const MedicationHistoryScreen({Key? key, required this.patientId})
    : super(key: key);

  @override
  State<MedicationHistoryScreen> createState() =>
      _MedicationHistoryScreenState();
}

class _MedicationHistoryScreenState extends State<MedicationHistoryScreen> {
  late Stream<QuerySnapshot> _medicationIntakesStream;

  @override
  void initState() {
    super.initState();
    // Set up the stream to listen for medication intakes
    _medicationIntakesStream =
        FirebaseFirestore.instance
            .collection('patients')
            .doc(widget.patientId)
            .collection('medicineIntakes')
            .orderBy('timestamp', descending: true)
            .snapshots();
  }

  String _formatDate(String date) {
    try {
      // Parse the date string if it's in the format "YYYY-MM-DD"
      final DateTime dateTime = DateTime.parse(date);
      final DateFormat formatter = DateFormat('MMM d, yyyy');
      return formatter.format(dateTime);
    } catch (e) {
      return date; // Return original if can't parse
    }
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return 'Unknown date';

    try {
      if (timestamp is Timestamp) {
        final DateTime dateTime = timestamp.toDate();
        final DateFormat formatter = DateFormat('MMM d, yyyy - h:mm a');
        return formatter.format(dateTime);
      } else if (timestamp is String) {
        // Try to parse the string into a DateTime
        return timestamp;
      }
    } catch (e) {
      // If parsing fails, return the original string
    }

    return timestamp.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Medication History'), elevation: 1),
      body: StreamBuilder<QuerySnapshot>(
        stream: _medicationIntakesStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading medication history...'),
                ],
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error loading medication history: ${snapshot.error}',
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                'No medication history found',
                style: TextStyle(fontSize: 16),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final doc = snapshot.data!.docs[index];
              final data = doc.data() as Map<String, dynamic>;

              final medicineName = data['medicineName'] ?? 'Unknown Medicine';
              final taken = data['taken'] ?? false;
              final timestamp = data['timestamp'];
              final date = data['date'] as String?;
              final dosage = data['dosage'] as String?;
              final mealTime = data['mealTime'] as String?;

              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        medicineName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Text(
                            'Status: ',
                            style: TextStyle(fontSize: 16),
                          ),
                          Text(
                            taken == true ? 'Taken' : 'Not Taken',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: taken == true ? Colors.green : Colors.red,
                            ),
                          ),
                        ],
                      ),
                      if (dosage != null) ...[
                        const SizedBox(height: 6),
                        Text(
                          'Dosage: $dosage',
                          style: const TextStyle(fontSize: 14),
                        ),
                      ],
                      if (mealTime != null) ...[
                        const SizedBox(height: 6),
                        Text(
                          'Meal: $mealTime',
                          style: const TextStyle(fontSize: 14),
                        ),
                      ],
                      const SizedBox(height: 6),
                      Text(
                        'Date: ${date != null ? _formatDate(date) : _formatTimestamp(timestamp)}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
