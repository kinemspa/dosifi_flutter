import 'package:flutter/material.dart';
import 'package:dosifi_flutter/presentation/screens/medication_form/controllers/medication_form_controller.dart';
import 'package:dosifi_flutter/core/widgets/compact_card.dart';

class BasicInformationSection extends StatelessWidget {
  final MedicationFormController controller;

  const BasicInformationSection({super.key, required this.controller});

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
                decoration: BoxDecoration(color: Colors.green[100], borderRadius: BorderRadius.circular(6)),
                child: Icon(Icons.info, color: Colors.green[700], size: 18),
              ),
              const SizedBox(width: 10),
              Text(
                'Basic Information',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              IconButton(
                icon: Icon(Icons.info_outline, size: 18, color: Colors.green[700]),
                tooltip: 'About basic information',
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    showDragHandle: true,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                    ),
                    builder: (ctx) => Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Row(children: [Icon(Icons.info_outline), SizedBox(width: 8), Text('Basic info help')]),
                          SizedBox(height: 12),
                          Text('Enter the medication name and optional brand/manufacturer.'),
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
            controller: controller.nameController,
            decoration: InputDecoration(
              labelText: 'Medication Name *',
              hintText: 'Enter the medication name',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: Colors.grey[50],
              prefixIcon: const Icon(Icons.medication),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter medication name';
              }
              return null;
            },
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: controller.brandController,
            decoration: InputDecoration(
              labelText: 'Brand / Manufacturer',
              hintText: 'Optional brand or manufacturer',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: Colors.grey[50],
              prefixIcon: const Icon(Icons.business),
            ),
          ),
        ],
      ),
    );
  }
}
