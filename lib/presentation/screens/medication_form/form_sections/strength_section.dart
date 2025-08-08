import 'package:flutter/material.dart';
import 'package:dosifi_flutter/data/models/medication.dart';
import 'package:dosifi_flutter/presentation/screens/medication_form/utils/medication_type_utils.dart';
import 'package:dosifi_flutter/presentation/screens/medication_form/controllers/medication_form_controller.dart';

class StrengthSection extends StatelessWidget {
  final MedicationFormController controller;

  const StrengthSection({
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
                    color: Colors.orange[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.scale, color: Colors.orange[700]),
                ),
                const SizedBox(width: 12),
                Text(
                  'Strength Information',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: controller.strengthController,
                    decoration: InputDecoration(
                      labelText: 'Strength Per Unit *',
                      hintText: '0.0',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                      prefixIcon: const Icon(Icons.straighten),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
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
                const SizedBox(width: 12),
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
                    items: MedicationTypeUtils.getAvailableStrengthUnits(controller.selectedType).map((unit) {
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
          ],
        ),
      ),
    );
  }
}
