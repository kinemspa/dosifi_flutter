import 'package:flutter/material.dart';
import 'package:dosifi_flutter/presentation/screens/medication_form/utils/medication_type_utils.dart';
import 'package:dosifi_flutter/data/models/medication.dart';
import 'package:dosifi_flutter/presentation/screens/medication_form/controllers/medication_form_controller.dart';
import 'package:dosifi_flutter/core/widgets/compact_card.dart';
import 'package:dosifi_flutter/core/widgets/helper_block.dart';
import 'package:dosifi_flutter/core/widgets/info_sheet.dart';
import 'package:dosifi_flutter/presentation/widgets/embedded_reconstitution_calculator.dart';

class StockInformationSection extends StatefulWidget {
  final MedicationFormController controller;

  const StockInformationSection({super.key, required this.controller});

  @override
  State<StockInformationSection> createState() => _StockInformationSectionState();
}

class _StockInformationSectionState extends State<StockInformationSection> {
  bool _useReconstitutionCalculator = false;

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final type = controller.selectedType;

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
                child: Icon(Icons.inventory, color: Colors.grey[800], size: 18),
              ),
              const SizedBox(width: 10),
              Text(
                'Stock Information',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.info_outline, size: 18),
                tooltip: 'Stock field help',
                onPressed: () {
                  InfoSheet.show(
                    context,
                    title: 'Stock Information',
                    message:
                        'Enter how many units you currently have. Choose the correct unit if applicable. You can set alerts for low stock and specify a threshold.',
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: TextFormField(
                  controller: controller.stockController,
                  decoration: InputDecoration(
                    labelText:
                        '${MedicationTypeUtils.getStockLabel(type)} *',
                    hintText: MedicationTypeUtils.getStockHintShort(type),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                    prefixIcon: const Icon(Icons.inventory_2),
                  ),
                  keyboardType:
                      MedicationTypeUtils.isStockInteger(type)
                          ? TextInputType.number
                          : const TextInputType.numberWithOptions(decimal: true),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Enter quantity';
                    }
                    if (MedicationTypeUtils.isStockInteger(type)) {
                      if (int.tryParse(value) == null) {
                        return 'Enter whole number';
                      }
                    } else {
                      if (double.tryParse(value) == null) {
                        return 'Enter valid number';
                      }
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 10),
              // Unit handling: show dropdown only when user can choose units (injectables, creams)
              if (type == MedicationType.preFilledSyringe ||
                  type == MedicationType.readyMadeVial ||
                  type == MedicationType.lyophilizedVial ||
                  type == MedicationType.cream ||
                  type == MedicationType.ointment ||
                  type == MedicationType.gel)
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: controller.selectedStockUnit,
                    decoration: InputDecoration(
                      labelText: 'Stock Unit',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                    ),
                    items: MedicationTypeUtils
                        .getStockUnitOptions(type)
                        .map((u) => DropdownMenuItem(value: u, child: Text(u)))
                        .toList(),
                    onChanged: (value) => controller.setSelectedStockUnit(value),
                  ),
                )
              else
                Expanded(
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'Stock Unit',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                    ),
                    child: Text(
                      MedicationTypeUtils.getStockUnit(type!),
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Notify when low on stock'),
                  value: controller.alertOnLowStock,
                  onChanged: (v) => controller.setAlertOnLowStock(v),
                ),
              ),
              const SizedBox(width: 10),
              if (controller.alertOnLowStock)
                SizedBox(
                  width: 200,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextFormField(
                        controller: controller.lowStockThresholdController,
                        decoration: InputDecoration(
                          labelText: 'Threshold',
                          hintText: MedicationTypeUtils.isStockInteger(type)
                              ? 'e.g., 3'
                              : 'e.g., 30.0',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.grey[50],
                        ),
                        keyboardType: MedicationTypeUtils.isStockInteger(type)
                            ? TextInputType.number
                            : const TextInputType.numberWithOptions(decimal: true),
                        validator: (value) {
                          if (!controller.alertOnLowStock) return null;
                          if (value == null || value.trim().isEmpty) {
                            return 'Enter threshold';
                          }
                          return double.tryParse(value) != null
                              ? null
                              : 'Enter a number';
                        },
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Unit: ${MedicationTypeUtils.getStockUnit(type!)}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          // Lyophilized flow: optionally use the embedded reconstitution calculator
          if (type == MedicationType.lyophilizedVial) ...[
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Use Reconstitution Calculator'),
              value: _useReconstitutionCalculator,
              onChanged: (v) {
                setState(() => _useReconstitutionCalculator = v);
              },
            ),
            if (_useReconstitutionCalculator) ...[
              const SizedBox(height: 8),
              EmbeddedReconstitutionCalculator(
                initialStrength: double.tryParse(controller.strengthController.text),
                initialStrengthUnit: controller.selectedStrengthUnit?.displayName,
                onCalculationResult: (volume, concentration, notes) {
                  // Persist results into form fields
                  controller.reconstitutionVolumeController.text =
                      volume.toStringAsFixed(1);
                  controller.finalConcentrationController.text =
                      concentration.toStringAsFixed(2);
                  controller.setSelectedStockUnit('mL');
                  controller.stockController.text =
                      volume.toStringAsFixed(1);
                  controller.reconstitutionNotesController.text = notes;
                  setState(() {});
                },
              ),
            ],
          ],
          const SizedBox(height: 8),
          HelperBlock.info(
            MedicationTypeUtils.getStockHelperText(type),
            icon: Icons.help_outline,
          ),
        ],
      ),
    );
  }
}
