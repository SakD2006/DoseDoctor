import 'package:flutter/material.dart';

class PrescriptionFormScreen extends StatefulWidget {
  final String patientName;
  final int age;
  final String gender;
  final double height;
  final double weight;

  const PrescriptionFormScreen({
    Key? key,
    required this.patientName,
    required this.age,
    required this.gender,
    required this.height,
    required this.weight,
  }) : super(key: key);

  @override
  _PrescriptionFormScreenState createState() => _PrescriptionFormScreenState();
}

class _PrescriptionFormScreenState extends State<PrescriptionFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _diagnosisController = TextEditingController();
  final TextEditingController _extraNoteController = TextEditingController();

  // List to hold dynamic medicine fields.
  List<MedicineItemData> medicineItems = [MedicineItemData()];

  @override
  void dispose() {
    _diagnosisController.dispose();
    _extraNoteController.dispose();
    for (var item in medicineItems) {
      item.dispose();
    }
    super.dispose();
  }

  void _addMedicineItem() {
    setState(() {
      medicineItems.add(MedicineItemData());
    });
  }

  // Save prescription: gather all form data and push to Firestore
  void _savePrescription() {
    if (_formKey.currentState?.validate() ?? false) {
      // Gather diagnosis and extra note.
      final diagnosis = _diagnosisController.text.trim();
      final extraNote = _extraNoteController.text.trim();

      // Gather each medicine item data into a list of maps.
      final medicines = medicineItems.map((item) {
        return {
          'medicineName': item.medicineNameController.text.trim(),
          'dosage': item.dosageController.text.trim(),
          'frequency': item.selectedFrequencies,
          'beforeAfterMeal': item.beforeAfterController.text.trim(),
          'startDate': item.startDate.toIso8601String(),
          'durationDays': int.tryParse(item.durationController.text.trim()) ?? 0,
        };
      }).toList();

      // TODO: Push these details to the patient's database in Firestore.
      // For example:
      // FirebaseFirestore.instance.collection('patients').doc(patientId).update({
      //   'diagnosis': diagnosis,
      //   'extraNote': extraNote,
      //   'prescriptions': FieldValue.arrayUnion(medicines),
      // });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Prescription saved successfully!")),
      );
    }
  }

  // Print prescription: trigger printing functionality.
  void _printPrescription() {
    // TODO: Use a package like 'printing' to generate a PDF and print.
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Print functionality not implemented.")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Prescription Form"),
        actions: [
          IconButton(
            onPressed: _printPrescription,
            icon: const Icon(Icons.print),
            tooltip: "Print Prescription",
          ),
          IconButton(
            onPressed: _savePrescription,
            icon: const Icon(Icons.save),
            tooltip: "Save Prescription",
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Patient details section.
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(widget.patientName,
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold)),
                Text("Height: ${widget.height}",
                    style: const TextStyle(fontSize: 16)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Age: ${widget.age}, Gender: ${widget.gender}",
                    style: const TextStyle(fontSize: 16)),
                Text("Weight: ${widget.weight}",
                    style: const TextStyle(fontSize: 16)),
              ],
            ),
            const SizedBox(height: 16),
            // Diagnosis field
            const Text("Diagnosis",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextFormField(
              controller: _diagnosisController,
              maxLines: 4,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: "Enter diagnosis here...",
              ),
            ),
            const SizedBox(height: 16),
            // Medicine Details Header
            const Text("Medicine Details",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            // Generate a list of medicine items.
            ...medicineItems.map((item) => MedicineItemWidget(data: item)),
            const SizedBox(height: 16),
            // Extra Note field
            const Text("Extra Note:",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextFormField(
              controller: _extraNoteController,
              maxLines: 2,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: "Enter extra notes...",
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addMedicineItem,
        child: const Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}

// Data class to hold medicine fields.
class MedicineItemData {
  final TextEditingController medicineNameController = TextEditingController();
  final TextEditingController dosageController = TextEditingController();
  // Store frequency selections in a list.
  List<String> selectedFrequencies = [];
  final TextEditingController beforeAfterController = TextEditingController();
  DateTime startDate = DateTime.now();
  final TextEditingController durationController = TextEditingController();

  void dispose() {
    medicineNameController.dispose();
    dosageController.dispose();
    beforeAfterController.dispose();
    durationController.dispose();
  }
}

// Widget to display one set of medicine fields.
class MedicineItemWidget extends StatefulWidget {
  final MedicineItemData data;
  const MedicineItemWidget({Key? key, required this.data}) : super(key: key);

  @override
  _MedicineItemWidgetState createState() => _MedicineItemWidgetState();
}

class _MedicineItemWidgetState extends State<MedicineItemWidget> {
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          children: [
            // First row: Medicine Name, Dosage, Frequency.
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: TextFormField(
                    controller: widget.data.medicineNameController,
                    decoration: const InputDecoration(
                      labelText: "Medicine Name",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: widget.data.dosageController,
                    decoration: const InputDecoration(
                      labelText: "Dosage",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 3,
                  child: FrequencyMultiSelect(
                    selectedFrequencies: widget.data.selectedFrequencies,
                    onSelectionChanged: (List<String> selections) {
                      setState(() {
                        widget.data.selectedFrequencies = selections;
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Second row: Before/After Meal, Start Date, Duration.
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: TextFormField(
                    controller: widget.data.beforeAfterController,
                    decoration: const InputDecoration(
                      labelText: "Before/After Meal",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 3,
                  child: GestureDetector(
                    onTap: () async {
                      DateTime? picked = await showDatePicker(
                        context: context,
                        initialDate: widget.data.startDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) {
                        setState(() {
                          widget.data.startDate = picked;
                        });
                      }
                    },
                    child: AbsorbPointer(
                      child: TextFormField(
                        decoration: const InputDecoration(
                          labelText: "Start Date",
                          border: OutlineInputBorder(),
                        ),
                        controller: TextEditingController(
                          text: "${widget.data.startDate.toLocal()}".split(' ')[0],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: widget.data.durationController,
                    decoration: const InputDecoration(
                      labelText: "Duration (days)",
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Widget for multi-select frequency using FilterChips.
class FrequencyMultiSelect extends StatefulWidget {
  final List<String> selectedFrequencies;
  final Function(List<String>) onSelectionChanged;

  const FrequencyMultiSelect({
    Key? key,
    required this.selectedFrequencies,
    required this.onSelectionChanged,
  }) : super(key: key);

  @override
  _FrequencyMultiSelectState createState() => _FrequencyMultiSelectState();
}

class _FrequencyMultiSelectState extends State<FrequencyMultiSelect> {
  final List<String> options = ["Morning", "Afternoon", "Evening"];
  late List<String> _selected;

  @override
  void initState() {
    super.initState();
    _selected = List.from(widget.selectedFrequencies);
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      children: options.map((option) {
        return FilterChip(
          label: Text(option),
          selected: _selected.contains(option),
          onSelected: (bool selected) {
            setState(() {
              if (selected) {
                _selected.add(option);
              } else {
                _selected.remove(option);
              }
              widget.onSelectionChanged(_selected);
            });
          },
        );
      }).toList(),
    );
  }
}
