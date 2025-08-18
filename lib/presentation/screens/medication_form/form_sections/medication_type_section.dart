import 'package:flutter/material.dart';
import 'package:dosifi_flutter/data/models/medication.dart';
import 'package:dosifi_flutter/presentation/screens/medication_form/utils/medication_type_utils.dart';
import 'package:dosifi_flutter/presentation/screens/medication_form/controllers/medication_form_controller.dart';
import 'package:dosifi_flutter/core/widgets/compact_card.dart';

class MedicationTypeSection extends StatelessWidget {
  final MedicationFormController controller;

  const MedicationTypeSection({super.key, required this.controller});

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
                decoration: BoxDecoration(
                  color: Colors.blue[100],
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(Icons.category, color: Colors.blue[700], size: 18),
              ),
              const SizedBox(width: 10),
              Text(
                'Medication Type',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              const Text(' *', style: TextStyle(color: Colors.red)),
            ],
          ),
          const SizedBox(height: 12),
          Semantics(
            label: 'Medication Type',
            button: true,
            child: DropdownButtonFormField<MedicationType>(
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
              items: MedicationType.values
                  .where(
                    (t) =>
                        t != MedicationType.cream &&
                        t != MedicationType.ointment &&
                        t != MedicationType.spray &&
                        t != MedicationType.gel,
                  )
                  .map((type) {
                    return DropdownMenuItem(
                      value: type,
                      child: Semantics(
                        label: type.displayName,
                        button: true,
                        child: Row(
                          children: [
                            Icon(
                              MedicationTypeUtils.getMedicationTypeIcon(type),
                              size: 18,
                              color: MedicationTypeUtils.getMedicationTypeColor(
                                type,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(type.displayName),
                          ],
                        ),
                      ),
                    );
                  })
                  .toList(),
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
          ),
        ],
      ),
    );
  }
}
