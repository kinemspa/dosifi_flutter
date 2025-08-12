import 'package:flutter/material.dart';
import 'package:dosifi_flutter/presentation/screens/medication_form/controllers/medication_form_controller.dart';
import 'package:dosifi_flutter/core/widgets/compact_card.dart';

class StorageSection extends StatelessWidget {
  final MedicationFormController controller;

  const StorageSection({super.key, required this.controller});

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
                decoration: BoxDecoration(color: Colors.teal[100], borderRadius: BorderRadius.circular(6)),
                child: Icon(Icons.storage, color: Colors.teal[700], size: 18),
              ),
              const SizedBox(width: 10),
              Text(
                'Storage Information',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              IconButton(
                icon: Icon(Icons.info_outline, size: 18, color: Colors.teal[700]),
                tooltip: 'Storage help',
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
                          Row(children: [Icon(Icons.thermostat), SizedBox(width: 8), Text('Storage help')]),
                          SizedBox(height: 12),
                          Text('Provide storage instructions and temperature. Toggle refrigeration if required.'),
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
            controller: controller.storageInstructionsController,
            decoration: InputDecoration(
              labelText: 'Storage Instructions',
              hintText: 'e.g., Store in cool, dry place',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: Colors.grey[50],
              prefixIcon: const Icon(Icons.info_outline),
            ),
            maxLines: 2,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: controller.storageTemperatureController,
            enabled: !controller.requiresRefrigeration,
            decoration: InputDecoration(
              labelText: 'Storage Temperature',
              hintText: controller.requiresRefrigeration ? '2–8 °C (auto-set when refrigerated)' : 'e.g., Room temperature',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: Colors.grey[50],
              prefixIcon: const Icon(Icons.thermostat),
            ),
          ),
          const SizedBox(height: 12),
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
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }
}
