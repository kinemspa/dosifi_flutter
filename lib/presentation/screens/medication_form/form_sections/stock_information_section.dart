import 'package:flutter/material.dart';
import 'package:dosifi_flutter/presentation/screens/medication_form/utils/medication_type_utils.dart';
import 'package:dosifi_flutter/presentation/screens/medication_form/controllers/medication_form_controller.dart';
import 'package:dosifi_flutter/core/widgets/compact_card.dart';
import 'package:dosifi_flutter/core/widgets/helper_block.dart';

class StockInformationSection extends StatelessWidget {
  final MedicationFormController controller;

  const StockInformationSection({super.key, required this.controller});

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
                decoration: BoxDecoration(color: Colors.purple[100], borderRadius: BorderRadius.circular(6)),
                child: Icon(Icons.inventory, color: Colors.purple[700], size: 18),
              ),
              const SizedBox(width: 10),
              Text(
                'Stock Information',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Spacer(),
              IconButton(
                icon: Icon(Icons.info_outline, size: 18, color: Colors.purple[700]),
                tooltip: 'Stock field help',
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
                          Row(children: [Icon(Icons.inventory), SizedBox(width: 8), Text('Stock help')]),
                          SizedBox(height: 12),
                          Text('Enter how many units you currently have. Choose the correct unit if applicable.'),
                        ],
                      ),
                    ),
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
                    labelText: '${MedicationTypeUtils.getStockLabel(controller.selectedType)} *',
                    hintText: MedicationTypeUtils.getStockHintShort(controller.selectedType),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Colors.grey[50],
                    prefixIcon: const Icon(Icons.inventory_2),
                  ),
                  keyboardType: MedicationTypeUtils.isStockInteger(controller.selectedType)
                      ? TextInputType.number
                      : const TextInputType.numberWithOptions(decimal: true),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Enter quantity';
                    }
                    if (MedicationTypeUtils.isStockInteger(controller.selectedType)) {
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
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: controller.selectedStockUnit,
                  decoration: InputDecoration(
                    labelText: 'Stock Unit',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Colors.grey[50],
                  ),
                  items: MedicationTypeUtils.getStockUnitOptions(
                    controller.selectedType,
                  ).map((u) => DropdownMenuItem(value: u, child: Text(u))).toList(),
                  onChanged: (value) => controller.setSelectedStockUnit(value),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          HelperBlock.info(
            MedicationTypeUtils.getStockHelperText(controller.selectedType),
            icon: Icons.help_outline,
          ),
        ],
      ),
    );
  }
}
