import 'package:flutter/material.dart';
import 'package:dosifi_flutter/presentation/screens/medication_form/controllers/medication_form_controller.dart';

class StorageSection extends StatelessWidget {
  final MedicationFormController controller;

  const StorageSection({
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
                    color: Colors.teal[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.storage, color: Colors.teal[700]),
                ),
                const SizedBox(width: 12),
                Text(
                  'Storage Information',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: controller.storageInstructionsController,
              decoration: InputDecoration(
                labelText: 'Storage Instructions',
                hintText: 'e.g., Store in cool, dry place',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[50],
                prefixIcon: const Icon(Icons.info_outline),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: controller.storageTemperatureController,
              decoration: InputDecoration(
                labelText: 'Storage Temperature',
                hintText: 'e.g., 2-8°C, Room temperature',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[50],
                prefixIcon: const Icon(Icons.thermostat),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(12),
                color: Colors.grey[50],
              ),
              child: SwitchListTile(
                title: const Text('Requires Refrigeration'),
                subtitle: const Text('Medication must be stored in refrigerator'),
                value: controller.requiresRefrigeration,
                onChanged: controller.setRequiresRefrigeration,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
