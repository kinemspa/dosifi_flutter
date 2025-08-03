import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/medication.dart';
import '../providers/medication_provider.dart';
import '../../config/app_router.dart';

class MedicationListScreen extends ConsumerWidget {
  const MedicationListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final medications = ref.watch(filteredMedicationsProvider);
    final searchQuery = ref.watch(medicationSearchQueryProvider);
    final typeFilter = ref.watch(medicationTypeFilterProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Medications'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Container(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search medications...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          ref.read(medicationSearchQueryProvider.notifier).state = '';
                        },
                      )
                    : null,
              ),
              onChanged: (value) {
                ref.read(medicationSearchQueryProvider.notifier).state = value;
              },
            ),
          ),
        ),
        actions: [
          PopupMenuButton<String?>(
            icon: Icon(
              Icons.filter_list,
              color: typeFilter != null ? Theme.of(context).colorScheme.primary : null,
            ),
            onSelected: (String? type) {
              ref.read(medicationTypeFilterProvider.notifier).state = type;
            },
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem<String?>(
                value: null,
                child: Text('All Types'),
              ),
              ...MedicationType.values.map((type) => PopupMenuItem<String>(
                value: type.displayName,
                child: Text(type.displayName),
              )),
            ],
          ),
        ],
      ),
      body: medications.when(
        data: (medicationList) {
          if (medicationList.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.medication_outlined,
                    size: 64,
                    color: Theme.of(context).disabledColor,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    searchQuery.isNotEmpty || typeFilter != null
                        ? 'No medications found'
                        : 'No medications added yet',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    searchQuery.isNotEmpty || typeFilter != null
                        ? 'Try adjusting your search or filters'
                        : 'Tap the + button to add your first medication',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: medicationList.length,
            padding: const EdgeInsets.all(8),
            itemBuilder: (context, index) {
              final medication = medicationList[index];
              return _MedicationCard(medication: medication);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error: ${error.toString()}'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  ref.read(medicationListProvider.notifier).loadMedications();
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.navigateToAddMedication(),
        label: const Text('Add Medication'),
        icon: const Icon(Icons.add),
      ),
    );
  }
}

class _MedicationCard extends ConsumerWidget {
  final Medication medication;

  const _MedicationCard({required this.medication});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isExpired = medication.expirationDate != null &&
        medication.expirationDate!.isBefore(DateTime.now());

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isExpired ? Colors.red : theme.colorScheme.primary,
          child: Icon(
            _getIconForType(medication.type.displayName),
            color: Colors.white,
          ),
        ),
        title: Text(
          medication.name,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${medication.displayStrength} - ${medication.type.displayName}',
              style: theme.textTheme.bodyMedium,
            ),
            if (medication.instructions != null && medication.instructions!.isNotEmpty)
              Text(
                medication.instructions!,
                style: theme.textTheme.bodySmall,
              ),
            if (isExpired)
              Text(
                'EXPIRED',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
          ],
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => context.navigateToMedicationDetails(medication.id.toString()),
        onLongPress: () => _showOptions(context, ref, medication),
      ),
    );
  }

  IconData _getIconForType(String type) {
    switch (type.toLowerCase()) {
      case 'tablet':
        return Icons.medication;
      case 'capsule':
        return Icons.medication;
      case 'liquid':
        return Icons.water_drop;
      case 'injection':
        return Icons.vaccines;
      case 'peptide':
        return Icons.science;
      case 'powder':
        return Icons.scatter_plot;
      case 'cream':
        return Icons.soap;
      case 'patch':
        return Icons.healing;
      case 'inhaler':
        return Icons.air;
      case 'drops':
        return Icons.water_drop_outlined;
      default:
        return Icons.medication_liquid;
    }
  }

  void _showOptions(BuildContext context, WidgetRef ref, Medication medication) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.edit),
            title: const Text('Edit'),
            onTap: () {
              Navigator.pop(context);
              context.navigateToEditMedication(medication.id.toString());
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete, color: Colors.red),
            title: const Text('Delete', style: TextStyle(color: Colors.red)),
            onTap: () async {
              Navigator.pop(context);
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Delete Medication'),
                  content: Text('Are you sure you want to delete ${medication.name}?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Delete', style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              );
              if (confirm == true) {
                await ref.read(medicationListProvider.notifier).deleteMedication(medication.id!);
              }
            },
          ),
        ],
      ),
    );
  }
}
