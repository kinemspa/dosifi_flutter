import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dosifi_flutter/data/models/medication.dart';
import 'package:dosifi_flutter/presentation/providers/medication_provider.dart';
import 'package:dosifi_flutter/core/services/medication_calculation_service.dart';
import 'package:dosifi_flutter/config/app_router.dart';
import 'package:dosifi_flutter/core/widgets/compact_card.dart';
import 'package:dosifi_flutter/core/widgets/label_chip.dart';
import 'package:dosifi_flutter/core/services/stock_management_service.dart';

class MedicationViewScreen extends ConsumerWidget {
  final String medicationId;

  const MedicationViewScreen({super.key, required this.medicationId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final medicationAsync = ref.watch(medicationByIdProvider(int.parse(medicationId)));

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        } else {
          context.go('/medications');
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Medication Details'),
          leading: BackButton(
            onPressed: () {
              if (Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              } else {
                context.go('/medications');
              }
            },
          ),
          actions: [
            IconButton(icon: const Icon(Icons.edit), onPressed: () => context.push('/medications/edit/$medicationId')),
          ],
        ),
        body: medicationAsync.when(
          data: (medication) {
            if (medication == null) {
              return const Center(child: Text('Medication not found'));
            }
            return _buildMedicationDetails(context, ref, medication);
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text('Error: $error'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => ref.refresh(medicationByIdProvider(int.parse(medicationId))),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMedicationDetails(BuildContext context, WidgetRef ref, Medication medication) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Card
          _buildHeaderCard(context, medication),
          const SizedBox(height: 16),

          // Status Indicators
          _buildStatusSection(context, medication),
          const SizedBox(height: 16),

          // Basic Information
          _buildInfoSection(context, 'Basic Information', [
            _InfoItem('Name', medication.name),
            if (medication.brandManufacturer != null) _InfoItem('Brand/Manufacturer', medication.brandManufacturer!),
            _InfoItem('Type', medication.type.displayName),
            _InfoItem('Strength', medication.displayStrength),
          ]),
          const SizedBox(height: 16),

          // Stock Information
          _buildStockSection(context, medication),
          const SizedBox(height: 16),

          // Expiration Information
          if (medication.expirationDate != null) ...[
            _buildExpirationSection(context, medication),
            const SizedBox(height: 16),
          ],

          // Storage Information - Always show
          _buildStorageSection(context, medication),
          const SizedBox(height: 16),

          // Reconstitution Information (for lyophilized vials)
          if (medication.type == MedicationType.lyophilizedVial) ...[
            _buildReconstitutionSection(context, medication),
            const SizedBox(height: 16),
          ],

          // Calculations
          _buildCalculationsSection(context, medication),
          const SizedBox(height: 16),

          // Notes
          if (medication.notes != null || medication.instructions != null || medication.description != null) ...[
            _buildNotesSection(context, medication),
            const SizedBox(height: 16),
          ],

          // Action Buttons
          _buildActionButtons(context, ref, medication),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildHeaderCard(BuildContext context, Medication medication) {
    return Card(
      elevation: 4,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [
              _getMedicationTypeColor(medication.type),
              _getMedicationTypeColor(medication.type).withValues(alpha: 0.8),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(_getMedicationTypeIcon(medication.type), color: Colors.white, size: 32),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        medication.name,
                        style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      if (medication.brandManufacturer != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          medication.brandManufacturer!,
                          style: const TextStyle(color: Colors.white70, fontSize: 16),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildHeaderStat('Strength', medication.displayStrength),
                _buildHeaderStat('Stock', medication.stockDisplay),
                _buildHeaderStat('Type', medication.type.displayName),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderStat(String label, String value) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500),
          ),
          Text(
            value,
            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusSection(BuildContext context, Medication medication) {
    final statusItems = <Widget>[];

    if (medication.isLowStock) {
      statusItems.add(const LabelChip(label: 'Low Stock', icon: Icons.inventory, color: Colors.orange));
    }

    if (medication.isExpired) {
      statusItems.add(const LabelChip(label: 'Expired', icon: Icons.warning, color: Colors.red));
    } else if (medication.isExpiringSoon) {
      statusItems.add(const LabelChip(label: 'Expires Soon', icon: Icons.schedule, color: Colors.amber));
    }

    if (medication.isActive) {
      statusItems.add(const LabelChip(label: 'Active', icon: Icons.check_circle, color: Colors.green));
    } else {
      statusItems.add(const LabelChip(label: 'Inactive', icon: Icons.pause_circle, color: Colors.grey));
    }

    if (statusItems.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Status', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Wrap(spacing: 8, runSpacing: 8, children: statusItems),
      ],
    );
  }

  Widget _buildInfoSection(BuildContext context, String title, List<_InfoItem> items) {
    return CompactCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ...items.map((item) => _buildInfoRow(item.label, item.value)),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.grey),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _buildStockSection(BuildContext context, Medication medication) {
    return CompactCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Stock Information',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          _buildInfoRow('Current Stock', medication.stockDisplay),
          if (medication.stockProgressLabel != null)
            _buildInfoRow('Current/Total', medication.stockProgressLabel!),
          if (medication.stockUnit != null) _buildInfoRow('Stock Unit', medication.stockUnit!.displayName),
          if (medication.lowStockThreshold != null)
            _buildInfoRow('Low Stock Threshold', '${medication.lowStockThreshold}'),
          if (medication.lotBatchNumber != null) _buildInfoRow('Lot/Batch Number', medication.lotBatchNumber!),

          // Stock level indicator
          const SizedBox(height: 12),
          Text('Stock Level', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          _buildStockIndicator(medication),
        ],
      ),
    );
  }

  Widget _buildStockIndicator(Medication medication) {
    final threshold = medication.lowStockThreshold ?? _getDefaultLowStockThreshold(medication);
    final currentStock = medication.stockQuantity;
    final percentage = (currentStock / (threshold * 2)).clamp(0.0, 1.0);

    Color indicatorColor;
    String statusText;

    if (currentStock <= threshold * 0.25) {
      indicatorColor = Colors.red;
      statusText = 'Critical';
    } else if (currentStock <= threshold) {
      indicatorColor = Colors.orange;
      statusText = 'Low';
    } else if (currentStock <= threshold * 1.5) {
      indicatorColor = Colors.yellow;
      statusText = 'Moderate';
    } else {
      indicatorColor = Colors.green;
      statusText = 'Good';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              statusText,
              style: TextStyle(color: indicatorColor, fontWeight: FontWeight.bold),
            ),
            Text(
              '${(percentage * 100).round()}%',
              style: TextStyle(color: indicatorColor, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: percentage,
          backgroundColor: indicatorColor.withValues(alpha: 0.3),
          valueColor: AlwaysStoppedAnimation<Color>(indicatorColor),
        ),
      ],
    );
  }

  Widget _buildExpirationSection(BuildContext context, Medication medication) {
    final expirationDate = medication.expirationDate!;
    final daysUntilExpiration = medication.daysUntilExpiration ?? 0;

    return CompactCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Expiration Information',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          _buildInfoRow('Expiration Date', _formatFullDate(expirationDate)),
          _buildInfoRow(
            'Days Until Expiration',
            daysUntilExpiration > 0
                ? '$daysUntilExpiration days'
                : daysUntilExpiration == 0
                ? 'Expires today'
                : 'Expired ${-daysUntilExpiration} days ago',
          ),

          const SizedBox(height: 12),
          _buildExpirationIndicator(daysUntilExpiration),
        ],
      ),
    );
  }

  Widget _buildExpirationIndicator(int daysUntilExpiration) {
    Color indicatorColor;
    String statusText;
    double percentage;

    if (daysUntilExpiration < 0) {
      indicatorColor = Colors.red;
      statusText = 'Expired';
      percentage = 0.0;
    } else if (daysUntilExpiration <= 30) {
      indicatorColor = Colors.orange;
      statusText = 'Expires Soon';
      percentage = daysUntilExpiration / 30.0;
    } else if (daysUntilExpiration <= 90) {
      indicatorColor = Colors.yellow;
      statusText = 'Monitor';
      percentage = daysUntilExpiration / 90.0;
    } else {
      indicatorColor = Colors.green;
      statusText = 'Fresh';
      percentage = 1.0;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Status: $statusText',
              style: TextStyle(color: indicatorColor, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: percentage,
          backgroundColor: indicatorColor.withValues(alpha: 0.3),
          valueColor: AlwaysStoppedAnimation<Color>(indicatorColor),
        ),
      ],
    );
  }

  Widget _buildStorageSection(BuildContext context, Medication medication) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.store, color: Theme.of(context).colorScheme.primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Storage Information',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Storage Instructions
            _buildStorageInfoRow(
              'Instructions',
              medication.storageInstructions ?? 'No specific instructions',
              Icons.description,
            ),
            const SizedBox(height: 8),

            // Refrigeration Requirements
            _buildStorageInfoRow(
              'Refrigeration',
              medication.requiresRefrigeration ? 'Required' : 'Not required',
              medication.requiresRefrigeration ? Icons.ac_unit : Icons.thermostat_outlined,
              color: medication.requiresRefrigeration ? Colors.blue : Colors.green,
            ),
            const SizedBox(height: 8),

            // Storage Temperature
            _buildStorageInfoRow('Temperature', medication.storageTemperature ?? 'Room temperature', Icons.thermostat),
            const SizedBox(height: 8),

            // Additional Info
            if (medication.barcode != null) ...[
              _buildStorageInfoRow('Barcode', medication.barcode!, Icons.qr_code),
              const SizedBox(height: 8),
            ],

            // Storage Tips
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.lightbulb, color: Colors.blue, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Storage Tips',
                          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue.shade700, fontSize: 12),
                        ),
                        const SizedBox(height: 4),
                        Text(_getStorageTips(medication), style: TextStyle(color: Colors.blue.shade600, fontSize: 11)),
                      ],
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

  Widget _buildStorageInfoRow(String label, String value, IconData icon, {Color? color}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: color ?? Colors.grey.shade600),
        const SizedBox(width: 8),
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: TextStyle(fontWeight: FontWeight.w500, color: Colors.grey.shade600, fontSize: 13),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        ),
      ],
    );
  }

  String _getStorageTips(Medication medication) {
    if (medication.requiresRefrigeration) {
      return 'Keep refrigerated at 2-8°C. Do not freeze. Allow to reach room temperature before use.';
    }

    switch (medication.type) {
      case MedicationType.liquid:
      case MedicationType.drops:
        return 'Store in original container. Shake well before use if required.';
      case MedicationType.tablet:
      case MedicationType.capsule:
        return 'Keep in original container with desiccant. Protect from moisture.';
      case MedicationType.cream:
      case MedicationType.ointment:
        return 'Keep container tightly closed. Avoid extreme temperatures.';
      case MedicationType.inhaler:
        return 'Store at room temperature. Do not puncture or expose to heat.';
      default:
        return 'Store in original packaging away from direct light and moisture.';
    }
  }

  Widget _buildAdvancedSection(BuildContext context, Medication medication) {
    final items = <_InfoItem>[];

    if (medication.storageInstructions != null) {
      items.add(_InfoItem('Storage Instructions', medication.storageInstructions!));
    }

    if (medication.requiresRefrigeration) {
      items.add(_InfoItem('Refrigeration', 'Required'));
    }

    if (medication.storageTemperature != null) {
      items.add(_InfoItem('Storage Temperature', medication.storageTemperature!));
    }

    if (medication.barcode != null) {
      items.add(_InfoItem('Barcode', medication.barcode!));
    }

    if (items.isEmpty) return const SizedBox.shrink();

    return _buildInfoSection(context, 'Storage & Additional Info', items);
  }

  Widget _buildReconstitutionSection(BuildContext context, Medication medication) {
    final items = <_InfoItem>[];

    if (medication.reconstitutionVolume != null) {
      items.add(_InfoItem('Reconstitution Volume', '${medication.reconstitutionVolume} mL'));
    }

    if (medication.finalConcentration != null) {
      items.add(_InfoItem('Final Concentration', '${medication.finalConcentration}'));
    }

    if (medication.reconstitutionNotes != null) {
      items.add(_InfoItem('Notes', medication.reconstitutionNotes!));
    }

    if (medication.reconstitutionFluid != null) {
      items.add(_InfoItem('Reconstitution Fluid', medication.reconstitutionFluid!));
    }

    return CompactCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Reconstitution Information',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          if (items.isEmpty)
            const Text('No reconstitution details provided')
          else
            ...items.map((item) => _buildInfoRow(item.label, item.value)),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: ElevatedButton.icon(
              onPressed: () async {
                // Guard: ensure we have dry vials available
                final vials = medication.vialsInStock ?? 0;
                if (vials <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('No dry vials remaining to reconstitute.'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }
                try {
                  final result = await StockManagementService.recordReconstitution(
                    medication: medication,
                    diluentVolume: medication.reconstitutionVolume ?? 0,
                    diluentType: medication.reconstitutionFluid,
                    notes: 'Reconstituted from medication details screen',
                  );
                  if (!context.mounted) return;
                  if (result.ok) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Vial reconstituted and stock updated.'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(result.message ?? 'Unable to reconstitute.'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text('Error reconstituting: $e'), backgroundColor: Colors.red));
                  }
                }
              },
              icon: const Icon(Icons.science),
              label: const Text('Reconstitute one vial'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalculationsSection(BuildContext context, Medication medication) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Calculations', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _buildInfoRow('Dose Precision', '${medication.dosePrecision}'),
            _buildInfoRow(
              'Total Active Ingredient',
              '${MedicationCalculationService.calculateTotalActiveIngredient(medication).toStringAsFixed(2)} ${medication.strengthUnit.displayName}',
            ),
            _buildInfoRow('Allowed Dose Units', medication.allowedDoseUnits.join(', ')),
          ],
        ),
      ),
    );
  }

  Widget _buildNotesSection(BuildContext context, Medication medication) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Notes & Instructions',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            if (medication.description != null) ...[
              _buildNoteItem('Description', medication.description!),
              const SizedBox(height: 8),
            ],
            if (medication.instructions != null) ...[
              _buildNoteItem('Instructions', medication.instructions!),
              const SizedBox(height: 8),
            ],
            if (medication.notes != null) ...[_buildNoteItem('Notes', medication.notes!)],
          ],
        ),
      ),
    );
  }

  Widget _buildNoteItem(String label, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
        ),
        const SizedBox(height: 4),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(8)),
          child: Text(content),
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context, WidgetRef ref, Medication medication) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => context.push('/medications/edit/${medication.id}'),
            icon: const Icon(Icons.edit),
            label: const Text('Edit'),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _showDeleteDialog(context, ref, medication),
            icon: const Icon(Icons.delete),
            label: const Text('Delete'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
          ),
        ),
      ],
    );
  }

  void _showDeleteDialog(BuildContext context, WidgetRef ref, Medication medication) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Medication'),
        content: Text('Are you sure you want to delete "${medication.name}"? This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await ref.read(medicationListProvider.notifier).deleteMedication(medication.id!);
              if (context.mounted) {
                context.pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${medication.name} deleted successfully'), backgroundColor: Colors.red),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  bool _hasAdvancedInfo(Medication medication) {
    return medication.storageInstructions != null ||
        medication.requiresRefrigeration ||
        medication.storageTemperature != null ||
        medication.barcode != null;
  }

  Color _getMedicationTypeColor(MedicationType type) {
    switch (type) {
      case MedicationType.tablet:
        return Colors.blue;
      case MedicationType.capsule:
        return Colors.green;
      case MedicationType.liquid:
        return Colors.cyan;
      case MedicationType.preFilledSyringe:
      case MedicationType.readyMadeVial:
        return Colors.purple;
      case MedicationType.lyophilizedVial:
        return Colors.indigo;
      case MedicationType.cream:
      case MedicationType.ointment:
        return Colors.orange;
      case MedicationType.drops:
        return Colors.lightBlue;
      case MedicationType.inhaler:
        return Colors.teal;
      case MedicationType.patch:
        return Colors.amber;
      case MedicationType.suppository:
        return Colors.pink;
      case MedicationType.singleUsePen:
      case MedicationType.multiUsePen:
        return Colors.deepPurple;
      case MedicationType.spray:
        return Colors.lime;
      case MedicationType.gel:
        return Colors.lightGreen;
      case MedicationType.other:
        return Colors.grey;
    }
  }

  IconData _getMedicationTypeIcon(MedicationType type) {
    switch (type) {
      case MedicationType.tablet:
      case MedicationType.capsule:
        return Icons.medication;
      case MedicationType.liquid:
      case MedicationType.drops:
        return Icons.water_drop;
      case MedicationType.preFilledSyringe:
      case MedicationType.readyMadeVial:
      case MedicationType.lyophilizedVial:
        return Icons.vaccines;
      case MedicationType.cream:
      case MedicationType.ointment:
      case MedicationType.gel:
        return Icons.healing;
      case MedicationType.inhaler:
        return Icons.air;
      case MedicationType.patch:
        return Icons.medical_services;
      case MedicationType.suppository:
        return Icons.medication_liquid;
      case MedicationType.singleUsePen:
      case MedicationType.multiUsePen:
        return Icons.colorize;
      case MedicationType.spray:
        return Icons.water_damage;
      case MedicationType.other:
        return Icons.medical_information;
    }
  }

  String _formatFullDate(DateTime date) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  double _getDefaultLowStockThreshold(Medication medication) {
    switch (medication.type) {
      case MedicationType.tablet:
      case MedicationType.capsule:
        return 7.0; // 7 tablets/capsules (week supply)
      case MedicationType.liquid:
      case MedicationType.drops:
        return 30.0; // 30 mL
      case MedicationType.preFilledSyringe:
        return 3.0; // 3 syringes
      case MedicationType.readyMadeVial:
        return 5.0; // 5 mL
      case MedicationType.lyophilizedVial:
        return 1.0; // 1 vial
      case MedicationType.cream:
      case MedicationType.ointment:
      case MedicationType.gel:
        return 15.0; // 15 grams
      case MedicationType.patch:
        return 3.0; // 3 patches
      case MedicationType.inhaler:
        return 20.0; // 20 doses remaining
      case MedicationType.suppository:
        return 3.0; // 3 suppositories
      case MedicationType.singleUsePen:
        return 2.0; // 2 single-use pens
      case MedicationType.multiUsePen:
        return 1.0; // 1 multi-use pen
      case MedicationType.spray:
        return 10.0; // 10 sprays remaining
      case MedicationType.other:
        return 5.0; // 5 units
    }
  }
}

class _InfoItem {
  final String label;
  final String value;

  _InfoItem(this.label, this.value);
}
