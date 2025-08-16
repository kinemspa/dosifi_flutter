import 'package:flutter/material.dart';
import 'package:dosifi_flutter/data/models/medication.dart';
import 'package:dosifi_flutter/presentation/screens/medication_form/utils/medication_type_utils.dart';
import 'package:dosifi_flutter/presentation/screens/medication_form/controllers/medication_form_controller.dart';
import 'package:dosifi_flutter/core/widgets/compact_card.dart';
import 'package:dosifi_flutter/core/widgets/info_sheet.dart';

class StrengthSection extends StatelessWidget {
  final MedicationFormController controller;

  const StrengthSection({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    // Dynamic label based on medication type for better clarity
    String strengthLabel = 'Strength Per Unit *';
    switch (controller.selectedType) {
      case MedicationType.tablet:
        strengthLabel = 'Strength per Tablet *';
        break;
      case MedicationType.capsule:
        strengthLabel = 'Strength per Capsule *';
        break;
      case MedicationType.liquid:
      case MedicationType.drops:
        strengthLabel = 'Concentration *';
        break;
      case MedicationType.preFilledSyringe:
        strengthLabel = 'Strength per Syringe *';
        break;
      case MedicationType.readyMadeVial:
      case MedicationType.lyophilizedVial:
        strengthLabel = 'Strength per Vial *';
        break;
      default:
        strengthLabel = 'Strength Per Unit *';
    }

    return CompactCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(Icons.scale, color: Colors.grey[800], size: 18),
              ),
              const SizedBox(width: 10),
              Text(
                'Strength Information',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.info_outline, size: 18),
                tooltip: 'How strength works',
                onPressed: () {
                  InfoSheet.show(
                    context,
                    title: 'Strength',
                    message:
                        'Enter how strong each unit is. For tablets/capsules use mg or mcg per unit. For liquids/drops use concentration (e.g., mg per mL). For vials/syringes, specify per vial/syringe.\n\nExamples:\n• Tablet: 500 mg per tablet\n• Liquid: 100 mg/mL\n• Vial: 10 mg per vial',
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: TextFormField(
                  controller: controller.strengthController,
                  decoration: InputDecoration(
                    labelText: strengthLabel,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                    prefixIcon: const Icon(Icons.straighten),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Enter strength';
                    }
                    if (double.tryParse(value) == null) {
                      return 'Enter valid number';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: DropdownButtonFormField<StrengthUnit>(
                  value: controller.selectedStrengthUnit,
                  decoration: InputDecoration(
                    labelText: 'Unit *',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                  ),
                  items:
                      MedicationTypeUtils.getAvailableStrengthUnits(
                        controller.selectedType,
                      ).map((unit) {
                        return DropdownMenuItem(
                          value: unit,
                          child: Text(unit.displayName),
                        );
                      }).toList(),
                  onChanged: (value) {
                    controller.setSelectedStrengthUnit(value);
                  },
                  validator: (value) {
                    if (value == null) {
                      return 'Select unit';
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (controller.selectedType == MedicationType.preFilledSyringe &&
              controller.selectedStrengthUnit == StrengthUnit.percent)
            TextFormField(
              controller: controller.volumeController,
              decoration: InputDecoration(
                labelText: 'Syringe volume (mL) *',
                hintText: 'e.g., 1.0',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[50],
                prefixIcon: const Icon(Icons.local_hospital),
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              validator: (value) {
                if (!(controller.selectedType ==
                        MedicationType.preFilledSyringe &&
                    controller.selectedStrengthUnit == StrengthUnit.percent)) {
                  return null;
                }
                if (value == null || value.trim().isEmpty)
                  return 'Enter syringe volume';
                final v = double.tryParse(value);
                if (v == null || v <= 0) return 'Enter a valid volume';
                return null;
              },
            ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}
