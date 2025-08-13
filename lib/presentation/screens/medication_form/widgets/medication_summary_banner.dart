import 'package:flutter/material.dart';
import 'package:dosifi_flutter/presentation/screens/medication_form/controllers/medication_form_controller.dart';
import 'package:dosifi_flutter/data/models/medication.dart';
import 'package:dosifi_flutter/core/widgets/compact_card.dart';
import 'package:dosifi_flutter/core/widgets/label_chip.dart';

class MedicationSummaryBanner extends StatelessWidget {
  final MedicationFormController controller;

  const MedicationSummaryBanner({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final name = controller.nameController.text.trim();
    final type = controller.selectedType?.displayName ?? '—';
    final strength = controller.strengthController.text.trim();
    final strengthUnit = controller.selectedStrengthUnit?.displayName ?? '';
    final syringeVolume = controller.volumeController.text.trim();
    final stockQty = controller.stockController.text.trim();
    final stockUnit = controller.selectedStockUnit ?? '';
    final refrigerated = controller.requiresRefrigeration;
    final expiry = controller.expirationDate;

    String expiryTextStr() {
      if (expiry == null) return 'No expiry set';
      final now = DateTime.now();
      final days = expiry.difference(DateTime(now.year, now.month, now.day)).inDays;
      if (days < 0) return 'Expired';
      if (days == 0) return 'Expires today';
      if (days == 1) return 'Expires tomorrow';
      return 'Expires in $days days';
    }

    return CompactCard(
      outlined: true,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      margin: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.medication, color: theme.colorScheme.primary, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  name.isNotEmpty ? name : 'New medication',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              LabelChip(icon: Icons.category, label: type),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (strength.isNotEmpty || strengthUnit.isNotEmpty)
                LabelChip(icon: Icons.straighten, label: 'Strength: ${strength.isEmpty ? '—' : strength} ${strengthUnit.isEmpty ? '' : strengthUnit}'),
              if (controller.selectedType == MedicationType.preFilledSyringe && controller.selectedStrengthUnit == StrengthUnit.percent && syringeVolume.isNotEmpty)
                LabelChip(
                  icon: Icons.local_hospital,
                  label: 'Approx. ${((double.tryParse(strength) ?? 0) * 10).toStringAsFixed(2)} mg/mL • Vol: ${syringeVolume} mL',
                ),
              if (stockQty.isNotEmpty || stockUnit.isNotEmpty)
                LabelChip(icon: Icons.inventory_2, label: 'Stock: ${stockQty.isEmpty ? '—' : stockQty} ${stockUnit.isEmpty ? '' : stockUnit}'),
              if (refrigerated) LabelChip(icon: Icons.ac_unit, label: 'Refrigerated'),
              if (expiry != null) LabelChip(icon: Icons.event, label: expiryTextStr()),
            ],
          ),
        ],
      ),
    );
  }
}

