import 'package:flutter/material.dart';
import 'package:dosifi_flutter/data/models/medication.dart';
import 'package:dosifi_flutter/presentation/screens/medication_form/utils/medication_type_utils.dart';
import 'package:dosifi_flutter/presentation/screens/medication_form/controllers/medication_form_controller.dart';

class MedicationTypeSection extends StatelessWidget {
  final MedicationFormController controller;

  const MedicationTypeSection({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.category, color: Colors.blue[700]),
                ),
                const SizedBox(width: 12),
                Text(
                  'Medication Type',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Text(' *', style: TextStyle(color: Colors.red)),
              ],
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<MedicationType>(
              value: controller.selectedType,
              decoration: InputDecoration(
                hintText: 'Select medication type...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[50],
                prefixIcon: const Icon(Icons.medical_services),
              ),
              items: MedicationType.values.map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Row(
                    children: [
                      Icon(
                        MedicationTypeUtils.getMedicationTypeIcon(type),
                        size: 20,
                        color: MedicationTypeUtils.getMedicationTypeColor(type),
                      ),
                      const SizedBox(width: 12),
                      Text(type.displayName),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (value) {
                controller.setSelectedType(value);
                controller.clearFormFields();
              },
              validator: (value) {
                if (value == null) {
                  return 'Please select medication type';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }
}
