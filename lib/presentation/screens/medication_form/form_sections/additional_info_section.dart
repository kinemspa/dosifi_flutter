import 'package:flutter/material.dart';
import 'package:dosifi_flutter/presentation/screens/medication_form/controllers/medication_form_controller.dart';
import 'package:dosifi_flutter/core/widgets/compact_card.dart';
import 'package:dosifi_flutter/core/widgets/helper_block.dart';
import 'package:dosifi_flutter/core/widgets/info_sheet.dart';

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
                decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(6)),
                child: Icon(Icons.description, color: Colors.grey[800], size: 18),
              ),
              const SizedBox(width: 10),
              Text(
                'Additional Information',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.info_outline, size: 18),
                tooltip: 'More fields help',
                onPressed: () {
                  InfoSheet.show(
                    context,
                    title: 'Additional Information',
                    message: 'Description and barcode are optional but useful for context.',
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
