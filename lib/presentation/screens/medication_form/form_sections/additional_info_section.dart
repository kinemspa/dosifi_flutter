import 'package:flutter/material.dart';
import 'package:dosifi_flutter/presentation/screens/medication_form/controllers/medication_form_controller.dart';
import 'package:dosifi_flutter/core/widgets/compact_card.dart';
import 'package:dosifi_flutter/core/widgets/helper_block.dart';

class AdditionalInfoSection extends StatelessWidget {
  final MedicationFormController controller;

  const AdditionalInfoSection({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return CompactCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(color: Colors.indigo[100], borderRadius: BorderRadius.circular(6)),
                child: Icon(Icons.description, color: Colors.indigo[700], size: 18),
              ),
              const SizedBox(width: 10),
              Text(
                'Additional Information',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              IconButton(
                icon: Icon(Icons.info_outline, size: 18, color: Colors.indigo[700]),
                tooltip: 'More fields help',
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    showDragHandle: true,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                    ),
                    builder: (ctx) => const Padding(
                      padding: EdgeInsets.fromLTRB(16, 8, 16, 24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [Icon(Icons.info_outline), SizedBox(width: 8), Text('Additional information help')]),
                          SizedBox(height: 12),
                          Text('Description, instructions, notes, and barcode are optional but useful for context.'),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: controller.descriptionController,
            decoration: InputDecoration(
              labelText: 'Description',
              hintText: 'Brief description of the medication',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: Colors.grey[50],
              prefixIcon: const Icon(Icons.description),
            ),
            maxLines: 2,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: controller.instructionsController,
            decoration: InputDecoration(
              labelText: 'Instructions',
              hintText: 'Dosage instructions or usage guidelines',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: Colors.grey[50],
              prefixIcon: const Icon(Icons.list_alt),
            ),
            maxLines: 3,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: controller.notesController,
            decoration: InputDecoration(
              labelText: 'Notes',
              hintText: 'Additional notes or comments',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: Colors.grey[50],
              prefixIcon: const Icon(Icons.note),
            ),
            maxLines: 3,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: controller.barcodeController,
            decoration: InputDecoration(
              labelText: 'Barcode',
              hintText: 'Product barcode or identifier',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: Colors.grey[50],
              prefixIcon: const Icon(Icons.qr_code_2),
              suffixIcon: IconButton(
                tooltip: 'Scan barcode (coming soon)',
                icon: const Icon(Icons.camera_alt_outlined),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Barcode scanner coming soon')),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 8),
          const HelperBlock.info('You can enter a barcode now and scan later once available', icon: Icons.help_outline),
          const SizedBox(height: 12),
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
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }
}
