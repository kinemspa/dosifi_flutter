import 'package:flutter/material.dart';
import 'package:dosifi_flutter/presentation/screens/medication_form/controllers/medication_form_controller.dart';

class AdditionalInfoSection extends StatelessWidget {
  final MedicationFormController controller;

  const AdditionalInfoSection({
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
                    color: Colors.indigo[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.description, color: Colors.indigo[700]),
                ),
                const SizedBox(width: 12),
                Text(
                  'Additional Information',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: controller.descriptionController,
              decoration: InputDecoration(
                labelText: 'Description',
                hintText: 'Brief description of the medication',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[50],
                prefixIcon: const Icon(Icons.description),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: controller.instructionsController,
              decoration: InputDecoration(
                labelText: 'Instructions',
                hintText: 'Dosage instructions or usage guidelines',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[50],
                prefixIcon: const Icon(Icons.list_alt),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: controller.notesController,
              decoration: InputDecoration(
                labelText: 'Notes',
                hintText: 'Additional notes or comments',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[50],
                prefixIcon: const Icon(Icons.note),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: controller.barcodeController,
              decoration: InputDecoration(
                labelText: 'Barcode',
                hintText: 'Product barcode or identifier',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[50],
                prefixIcon: const Icon(Icons.qr_code_2),
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
                title: const Text('Active'),
                subtitle: const Text('Medication is currently being used'),
                value: controller.isActive,
                onChanged: controller.setIsActive,
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
