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
            const SnackBar(
              content: Text('Prescription saved successfully'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error saving prescription: $e'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
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
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    // Extract patient details from the provided data
    final int age = widget.patientData['Age'] ?? 0;
    final String gender = widget.patientData['Gender'] ?? 'N/A';
    final String weight = widget.patientData['Weight'] ?? 'N/A';
    final String height = widget.patientData['Height'] ?? 'N/A';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Prescription'),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 2,
        actions: [
          _isSaving
              ? const Padding(
                padding: EdgeInsets.all(16.0),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                ),
              )
              : IconButton(
                icon: const Icon(Icons.save),
                onPressed: _savePrescription,
                tooltip: 'Save Prescription',
              ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
            tooltip: 'Cancel',
          ),
        ],
      ),
      body:
          _isSaving
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: colorScheme.primary),
                    const SizedBox(height: 16),
                    Text(
                      'Saving prescription...',
                      style: TextStyle(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              )
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
                        colorScheme,
                      ),
                      const SizedBox(height: 16),

                      // Diagnosis Field
                      _buildDiagnosisCard(colorScheme),
                      const SizedBox(height: 16),

                      // Medications Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Medications Prescribed',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: colorScheme.primary,
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: _addMedicationField,
                            icon: const Icon(Icons.add),
                            label: const Text('Add'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: colorScheme.secondary,
                              foregroundColor: colorScheme.onSecondary,
                              elevation: 2,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Medication Fields
                      ..._medicationFields.asMap().entries.map((entry) {
                        final index = entry.key;
                        final medicationField = entry.value;
                        return _buildMedicationCard(
                          medicationField,
                          index,
                          colorScheme,
                        );
                      }).toList(),

                      const SizedBox(height: 24),

                      // Save Button
                      Center(
                        child: ElevatedButton.icon(
                          onPressed: _savePrescription,
                          icon: const Icon(Icons.check_circle_outline),
                          label: const Text('Save Prescription'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colorScheme.primary,
                            foregroundColor: colorScheme.onPrimary,
                            elevation: 3,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 32,
                              vertical: 14,
                            ),
                            textStyle: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
    );
  }

  Widget _buildDiagnosisCard(ColorScheme colorScheme) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colorScheme.primary.withOpacity(0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.medical_information, color: colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Diagnosis',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _diagnosisController,
              decoration: InputDecoration(
                hintText: 'Enter diagnosis',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: colorScheme.primary, width: 2),
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
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
    );
  }

  Widget _buildPatientDetailsCard(
    String name,
    int age,
    String gender,
    String weight,
    String height,
    String doctorName,
    ColorScheme colorScheme,
  ) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colorScheme.primary.withOpacity(0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: colorScheme.primary.withOpacity(0.2),
                  child: Text(
                    name.isNotEmpty ? name[0].toUpperCase() : "?",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
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
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Patient",
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              children: [
                _buildPatientInfoItem(
                  'Age',
                  '$age years',
                  Icons.calendar_today,
                  colorScheme,
                ),
                _buildPatientInfoItem(
                  'Gender',
                  gender,
                  Icons.person,
                  colorScheme,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildPatientInfoItem(
                  'Weight',
                  "$weight kg",
                  Icons.line_weight,
                  colorScheme,
                ),
                _buildPatientInfoItem(
                  'Height',
                  "$height cm",
                  Icons.height,
                  colorScheme,
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              children: [
                Icon(
                  Icons.medical_services,
                  size: 18,
                  color: colorScheme.secondary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Doctor: ',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade700,
                  ),
                ),
                Text(
                  doctorName,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.secondary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPatientInfoItem(
    String label,
    String value,
    IconData icon,
    ColorScheme colorScheme,
  ) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0),
        child: Row(
          children: [
            Icon(icon, size: 18, color: colorScheme.primary),
            const SizedBox(width: 8),
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

  Widget _buildMedicationCard(
    MedicationField medicationField,
    int index,
    ColorScheme colorScheme,
  ) {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colorScheme.secondary.withOpacity(0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: colorScheme.secondary.withOpacity(0.2),
                      child: Text(
                        '${index + 1}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.secondary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Medication ${index + 1}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.secondary,
                      ),
                    ),
                  ],
                ),
                if (_medicationFields.length > 1)
                  IconButton(
                    icon: Icon(
                      Icons.delete_outline,
                      color: Colors.red.shade400,
                    ),
                    onPressed: () => _removeMedicationField(index),
                    tooltip: 'Remove',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
              ],
            ),
            const Divider(height: 24),

            // Medicine Name
            TextFormField(
              controller: medicationField.nameController,
              decoration: InputDecoration(
                labelText: 'Medicine Name',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                prefixIcon: const Icon(Icons.medication),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: colorScheme.primary, width: 2),
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter medicine name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Dosage
            TextFormField(
              controller: medicationField.dosageController,
              decoration: InputDecoration(
                labelText: 'Dosage',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                prefixIcon: const Icon(Icons.scale),
                hintText: 'e.g., 500mg, 5ml, etc.',
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: colorScheme.primary, width: 2),
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter dosage';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),

            // Frequency
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Frequency:',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _buildFrequencyChip(
                        'Morning',
                        Icons.wb_sunny,
                        medicationField.morning,
                        (value) {
                          setState(() {
                            medicationField.morning = value ?? false;
                          });
                        },
                        colorScheme,
                      ),
                      const SizedBox(width: 8),
                      _buildFrequencyChip(
                        'Afternoon',
                        Icons.wb_twighlight,
                        medicationField.afternoon,
                        (value) {
                          setState(() {
                            medicationField.afternoon = value ?? false;
                          });
                        },
                        colorScheme,
                      ),
                      const SizedBox(width: 8),
                      _buildFrequencyChip(
                        'Evening',
                        Icons.nightlight_round,
                        medicationField.evening,
                        (value) {
                          setState(() {
                            medicationField.evening = value ?? false;
                          });
                        },
                        colorScheme,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Before/After meal
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Timing:',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _buildTimingOption(
                        'Before meal',
                        true,
                        medicationField.isBefore,
                        (value) {
                          setState(() {
                            medicationField.isBefore = value!;
                          });
                        },
                        colorScheme,
                      ),
                      const SizedBox(width: 16),
                      _buildTimingOption(
                        'After meal',
                        false,
                        medicationField.isBefore,
                        (value) {
                          setState(() {
                            medicationField.isBefore = value!;
                          });
                        },
                        colorScheme,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Course Period
            TextFormField(
              controller: medicationField.coursePeriodController,
              decoration: InputDecoration(
                labelText: 'Course Period (Days)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                prefixIcon: const Icon(Icons.calendar_month),
                hintText: 'Number of days',
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: colorScheme.primary, width: 2),
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
                suffixText: 'days',
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter course period';
                }
                if (int.tryParse(value) == null) {
                  return 'Please enter a valid number';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFrequencyChip(
    String label,
    IconData icon,
    bool isSelected,
    Function(bool?) onChanged,
    ColorScheme colorScheme,
  ) {
    return Expanded(
      child: InkWell(
        onTap: () => onChanged(!isSelected),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
          decoration: BoxDecoration(
            color:
                isSelected
                    ? colorScheme.secondary.withOpacity(0.15)
                    : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color:
                  isSelected
                      ? colorScheme.secondary
                      : Colors.grey.withOpacity(0.3),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color:
                    isSelected ? colorScheme.secondary : Colors.grey.shade600,
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color:
                      isSelected ? colorScheme.secondary : Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimingOption(
    String label,
    bool value,
    bool groupValue,
    Function(bool?) onChanged,
    ColorScheme colorScheme,
  ) {
    final bool isSelected = value == groupValue;

    return Expanded(
      child: InkWell(
        onTap: () => onChanged(value),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
          decoration: BoxDecoration(
            color:
                isSelected
                    ? colorScheme.primary.withOpacity(0.15)
                    : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color:
                  isSelected
                      ? colorScheme.primary
                      : Colors.grey.withOpacity(0.3),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isSelected
                    ? Icons.radio_button_checked
                    : Icons.radio_button_off,
                size: 18,
                color: isSelected ? colorScheme.primary : Colors.grey.shade600,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color:
                      isSelected ? colorScheme.primary : Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ),
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
