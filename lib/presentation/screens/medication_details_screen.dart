import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/medication.dart';
import '../providers/medication_provider.dart';
import '../../config/app_router.dart';

class MedicationDetailsScreen extends ConsumerWidget {
  final String medicationId;
  
  const MedicationDetailsScreen({
    super.key,
    required this.medicationId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final medicationAsync = ref.watch(medicationByIdProvider(int.parse(medicationId)));
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Medication Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => context.navigateToEditMedication(medicationId),
          ),
        ],
      ),
      body: medicationAsync.when(
        data: (medication) {
          if (medication == null) {
            return const Center(child: Text('Medication not found'));
          }
          
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context, medication),
                const SizedBox(height: 24),
                _buildInfoCard(context, 'Dosage Information', [
                  _buildInfoRow('Strength', medication.displayStrength),
                  if (medication.numberOfUnits > 0)
                    _buildInfoRow('Stock', medication.stockDisplay),
                  if (medication.instructions != null)
                    _buildInfoRow('Instructions', medication.instructions!),
                ]),
                const SizedBox(height: 16),
                if (medication.instructions != null) ...[
                  _buildInfoCard(context, 'Instructions', [
                    Text(medication.instructions!),
                  ]),
                  const SizedBox(height: 16),
                ],
                _buildInfoCard(context, 'Additional Information', [
                  if (medication.brandManufacturer != null)
                    _buildInfoRow('Brand/Manufacturer', medication.brandManufacturer!),
                  if (medication.lotBatchNumber != null)
                    _buildInfoRow('Batch Number', medication.lotBatchNumber!),
                  if (medication.expirationDate != null)
                    _buildInfoRow(
                      'Expiration Date', 
                      '${medication.expirationDate!.day}/${medication.expirationDate!.month}/${medication.expirationDate!.year}'
                    ),
                  _buildInfoRow(
                    'Added On', 
                    '${medication.createdAt.day}/${medication.createdAt.month}/${medication.createdAt.year}'
                  ),
                ]),
                if (medication.notes != null) ...[
                  const SizedBox(height: 16),
                  _buildInfoCard(context, 'Notes', [
                    Text(medication.notes!),
                  ]),
                ],
                const SizedBox(height: 24),
                _buildActionButtons(context, medication),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, Medication medication) {
    final isExpired = medication.isExpired;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getIconForType(medication.type.displayName),
                    size: 32,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        medication.name,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Chip(
                            label: Text(medication.type.displayName),
                            backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                          ),
                          if (isExpired) ...[
                            const SizedBox(width: 8),
                            const Chip(
                              label: Text('Expired'),
                              backgroundColor: Colors.red,
                              labelStyle: TextStyle(color: Colors.white),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context, String title, List<Widget> children) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
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
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, Medication medication) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () {
              // TODO: Navigate to schedule screen with this medication
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Schedule feature coming soon')),
              );
            },
            icon: const Icon(Icons.schedule),
            label: const Text('Set Schedule'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () {
              // TODO: Navigate to inventory screen with this medication
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Inventory feature coming soon')),
              );
            },
            icon: const Icon(Icons.inventory),
            label: const Text('Track Inventory'),
          ),
        ),
      ],
    );
  }

  IconData _getIconForType(String type) {
    switch (type.toLowerCase()) {
      case 'tablet':
        return Icons.medication;
      case 'capsule':
        return Icons.medication_outlined;
      case 'liquid':
        return Icons.water_drop;
      case 'injection':
        return Icons.vaccines;
      case 'cream':
      case 'ointment':
        return Icons.healing;
      case 'inhaler':
        return Icons.air;
      case 'drops':
        return Icons.water_drop_outlined;
      default:
        return Icons.medical_services;
    }
  }
}
