import 'package:flutter/material.dart';
import 'package:dosifi_flutter/presentation/screens/medication_form/utils/medication_type_utils.dart';
import 'package:dosifi_flutter/presentation/screens/medication_form/controllers/medication_form_controller.dart';

class StockInformationSection extends StatelessWidget {
  final MedicationFormController controller;

  const StockInformationSection({
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
                    color: Colors.purple[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.inventory, color: Colors.purple[700]),
                ),
                const SizedBox(width: 12),
                Text(
                  'Stock Information',
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
                    controller: controller.stockController,
                    decoration: InputDecoration(
                      labelText: '${MedicationTypeUtils.getStockLabel(controller.selectedType)} *',
                      hintText: MedicationTypeUtils.getStockHint(controller.selectedType),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
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
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.grey[100],
                    ),
                    child: Text(
                      controller.selectedStockUnit ?? '',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.help_outline, color: Colors.blue[700], size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      MedicationTypeUtils.getStockHelperText(controller.selectedType),
                      style: TextStyle(
                        color: Colors.blue[700],
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
