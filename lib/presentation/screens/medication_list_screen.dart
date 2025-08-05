import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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
    final isLowStock = medication.stockQuantity < 5; // Assume low stock threshold

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: Card(
        elevation: 1,
        margin: EdgeInsets.zero,
        child: InkWell(
          onTap: () => context.navigateToMedicationDetails(medication.id.toString()),
          onLongPress: () => _showOptions(context, ref, medication),
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                // Compact icon
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: isExpired 
                        ? Colors.red.withOpacity(0.1)
                        : theme.colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: isExpired ? Colors.red : theme.colorScheme.primary,
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    _getIconForType(medication.type.displayName),
                    color: isExpired ? Colors.red : theme.colorScheme.primary,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                // Medication info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Name and type in one line
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              medication.name,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            medication.type.displayName,
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontSize: 10,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      // Strength and stock in one line
                      Row(
                        children: [
                          Text(
                            medication.displayStrength,
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontSize: 11,
                              color: Colors.grey[700],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '•',
                            style: TextStyle(color: Colors.grey[500], fontSize: 10),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${medication.stockQuantity.toInt()} left',
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontSize: 11,
                              color: isLowStock ? Colors.orange[700] : Colors.grey[700],
                              fontWeight: isLowStock ? FontWeight.w600 : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Status indicators
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isExpired)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(
                          color: Colors.red[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'EXP',
                          style: TextStyle(
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                            color: Colors.red[800],
                          ),
                        ),
                      ),
                    if (isLowStock && !isExpired)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(
                          color: Colors.orange[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'LOW',
                          style: TextStyle(
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange[800],
                          ),
                        ),
                      ),
                    const SizedBox(height: 4),
                    Icon(
                      Icons.chevron_right,
                      size: 14,
                      color: Colors.grey[400],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
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
              context.pop();
              context.navigateToEditMedication(medication.id.toString());
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete, color: Colors.red),
            title: const Text('Delete', style: TextStyle(color: Colors.red)),
            onTap: () async {
              context.pop();
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Delete Medication'),
                  content: Text('Are you sure you want to delete ${medication.name}?'),
                  actions: [
                    TextButton(
                      onPressed: () => context.pop(false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => context.pop(true),
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
