import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class PrescriptionFormScreen extends StatefulWidget {
  final String patientId;
  final String patientName;
  final Map<String, dynamic> patientData;
  final String doctorName;

  const PrescriptionFormScreen({
    super.key,
    required this.patientId,
    required this.patientName,
    required this.patientData,
    required this.doctorName,
  });

  @override
  State<PrescriptionFormScreen> createState() => _PrescriptionFormScreenState();
}

class _PrescriptionFormScreenState extends State<PrescriptionFormScreen> {
  final _diagnosisController = TextEditingController();
  final List<MedicationField> _medicationFields = [];
  bool _isSaving = false;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    // Add the first medication field
    _addMedicationField();
  }

  @override
  void dispose() {
    _diagnosisController.dispose();
    for (var field in _medicationFields) {
      field.dispose();
    }
    super.dispose();
  }

  void _addMedicationField() {
    setState(() {
      _medicationFields.add(MedicationField());
    });
  }

  void _removeMedicationField(int index) {
    if (_medicationFields.length > 1) {
      setState(() {
        _medicationFields[index].dispose();
        _medicationFields.removeAt(index);
      });
    }
  }

  Future<void> _savePrescription() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isSaving = true;
      });

      try {
        final batch = FirebaseFirestore.instance.batch();
        final medicationsCollection = FirebaseFirestore.instance
            .collection('patients')
            .doc(widget.patientId)
            .collection('medications');

        final now = DateTime.now();
        final String prescriptionId = DateFormat('yyyyMMdd_HHmmss').format(now);

        // Save each medication as a separate document in the 'medications' subcollection
        for (var medicationField in _medicationFields) {
          final medicationDoc = medicationsCollection.doc();

          // Convert frequency checkboxes to '1-0-1' format
          final String frequency =
              '${medicationField.morning ? '1' : '0'}-'
              '${medicationField.afternoon ? '1' : '0'}-'
              '${medicationField.evening ? '1' : '0'}';

          batch.set(medicationDoc, {
            'prescriptionId': prescriptionId,
            'diagnosis': _diagnosisController.text,
            'medicineName': medicationField.nameController.text,
            'dosage': medicationField.dosageController.text,
            'frequency': frequency,
            'beforeAfterMeal': medicationField.isBefore ? 'Before' : 'After',
            'durationDays': int.parse(
              medicationField.coursePeriodController.text.trim(),
            ),
            'startDate': now,
          });
        }

        await batch.commit();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Prescription saved successfully')),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error saving prescription: $e')),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isSaving = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Extract patient details from the provided data
    final int age = widget.patientData['Age'] ?? 0;
    final String gender = widget.patientData['Gender'] ?? 'N/A';
    final String weight = widget.patientData['Weight'] ?? 'N/A';
    final String height = widget.patientData['Height'] ?? 'N/A';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Prescription'),
        leading: IconButton(
          icon: const Icon(Icons.save),
          onPressed: _isSaving ? null : _savePrescription,
          tooltip: 'Save Prescription',
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
            tooltip: 'Cancel',
          ),
        ],
      ),
      body:
          _isSaving
              ? const Center(child: CircularProgressIndicator())
              : Form(
                key: _formKey,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Patient Details Card
                      _buildPatientDetailsCard(
                        widget.patientName,
                        age,
                        gender,
                        weight,
                        height,
                        widget.doctorName,
                      ),
                      const SizedBox(height: 16),

                      // Diagnosis Field
                      Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Diagnosis',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _diagnosisController,
                                decoration: const InputDecoration(
                                  hintText: 'Enter diagnosis',
                                  border: OutlineInputBorder(),
                                ),
                                maxLines: 3,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter diagnosis';
                                  }
                                  return null;
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Medications
                      const Text(
                        'Medications Prescribed',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Medication Fields
                      ..._medicationFields.asMap().entries.map((entry) {
                        final index = entry.key;
                        final medicationField = entry.value;
                        return _buildMedicationCard(medicationField, index);
                      }).toList(),

                      // Add Medication Button
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16.0),
                          child: ElevatedButton.icon(
                            onPressed: _addMedicationField,
                            icon: const Icon(Icons.add),
                            label: const Text('Add Medication'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
    );
  }

  Widget _buildPatientDetailsCard(
    String name,
    int age,
    String gender,
    String weight,
    String height,
    String doctorName,
  ) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: Colors.blue.shade100,
                  child: Text(
                    name.isNotEmpty ? name[0].toUpperCase() : "?",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade700,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  "Patient Name:",
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildPatientInfoItem('Age', '$age years'),
                _buildPatientInfoItem('Gender', gender),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildPatientInfoItem('Weight', "$weight kg"),
                _buildPatientInfoItem('Height', "$height cm"),
              ],
            ),
            const SizedBox(height: 8),
            Row(children: [_buildPatientInfoItem('Doctor Name', doctorName)]),
          ],
        ),
      ),
    );
  }

  Widget _buildPatientInfoItem(String label, String value) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0),
        child: Row(
          children: [
            Text(
              '$label: ',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
            ),
            Text(
              value,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMedicationCard(MedicationField medicationField, int index) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Medication ${index + 1}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (_medicationFields.length > 1)
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _removeMedicationField(index),
                    tooltip: 'Remove',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
              ],
            ),
            const SizedBox(height: 12),

            // Medicine Name
            TextFormField(
              controller: medicationField.nameController,
              decoration: const InputDecoration(
                labelText: 'Medicine Name',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter medicine name';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),

            // Dosage
            TextFormField(
              controller: medicationField.dosageController,
              decoration: const InputDecoration(
                labelText: 'Dosage',
                border: OutlineInputBorder(),
                hintText: 'e.g., 500mg, 5ml, etc.',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter dosage';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Frequency
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Frequency:',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildCheckbox('Morning', medicationField.morning, (value) {
                      setState(() {
                        medicationField.morning = value ?? false;
                      });
                    }),
                    _buildCheckbox('Afternoon', medicationField.afternoon, (
                      value,
                    ) {
                      setState(() {
                        medicationField.afternoon = value ?? false;
                      });
                    }),
                    _buildCheckbox('Evening', medicationField.evening, (value) {
                      setState(() {
                        medicationField.evening = value ?? false;
                      });
                    }),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Before/After meal
            Row(
              children: [
                const Text(
                  'Timing:',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
                const SizedBox(width: 12),
                _buildRadio('Before meal', true, medicationField.isBefore, (
                  value,
                ) {
                  setState(() {
                    medicationField.isBefore = value!;
                  });
                }),
                _buildRadio('After meal', false, medicationField.isBefore, (
                  value,
                ) {
                  setState(() {
                    medicationField.isBefore = value!;
                  });
                }),
              ],
            ),
            const SizedBox(height: 12),

            // Course Period
            TextFormField(
              controller: medicationField.coursePeriodController,
              decoration: const InputDecoration(
                labelText: 'Course Period',
                border: OutlineInputBorder(),
                hintText: 'e.g., 7 days, (days only!)',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter course period';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCheckbox(String label, bool value, Function(bool?) onChanged) {
    return Expanded(
      child: Row(
        children: [
          Checkbox(value: value, onChanged: onChanged),
          Text(label, style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildRadio(
    String label,
    bool value,
    bool groupValue,
    Function(bool?) onChanged,
  ) {
    return Row(
      children: [
        Radio<bool>(value: value, groupValue: groupValue, onChanged: onChanged),
        Text(label, style: const TextStyle(fontSize: 14)),
      ],
    );
  }
}

class MedicationField {
  final nameController = TextEditingController();
  final dosageController = TextEditingController();
  final coursePeriodController = TextEditingController();
  bool morning = false;
  bool afternoon = false;
  bool evening = false;
  bool isBefore = true;

  void dispose() {
    nameController.dispose();
    dosageController.dispose();
    coursePeriodController.dispose();
  }
}
