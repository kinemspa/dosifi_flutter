import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dosifi_flutter/data/models/medication.dart';
import 'package:dosifi_flutter/presentation/providers/medication_provider.dart';

class MedicationsListScreen extends ConsumerStatefulWidget {
  const MedicationsListScreen({super.key});

  @override
  ConsumerState<MedicationsListScreen> createState() => _MedicationsListScreenState();
}

class _MedicationsListScreenState extends ConsumerState<MedicationsListScreen> {
  String _searchQuery = '';
  MedicationType? _selectedType;
  bool _showLowStockOnly = false;
  bool _showExpiringSoon = false;
  bool _showSearchField = false;

  @override
  Widget build(BuildContext context) {
    final medicationsAsync = ref.watch(medicationListProvider);

    return Scaffold(
      body: Column(
        children: [
          // Action Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                // Search Button
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _showSearchField = !_showSearchField;
                        if (!_showSearchField) {
                          _searchQuery = '';
                        }
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.grey.shade50,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.search,
                            color: Colors.grey.shade600,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _searchQuery.isEmpty ? 'Search medications...' : _searchQuery,
                            style: TextStyle(
                              color: _searchQuery.isEmpty ? Colors.grey.shade600 : Colors.black87,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Filter Button
                IconButton(
                  icon: const Icon(Icons.filter_list),
                  onPressed: _showFilterDialog,
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.grey.shade100,
                    padding: const EdgeInsets.all(12),
                  ),
                ),
              ],
            ),
          ),
          // Search Field (when expanded)
          if (_showSearchField)
            Padding(
              padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 16.0),
              child: TextField(
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Type to search medications...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      setState(() {
                        _showSearchField = false;
                        _searchQuery = '';
                      });
                    },
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
              ),
            ),
          
          // Filter Chips
          if (_selectedType != null || _showLowStockOnly || _showExpiringSoon)
            Container(
              height: 50,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  if (_selectedType != null)
                    FilterChip(
                      label: Text(_selectedType!.displayName),
                      selected: true,
                      onSelected: (selected) {},
                      onDeleted: () {
                        setState(() {
                          _selectedType = null;
                        });
                      },
                    ),
                  if (_showLowStockOnly) ...[
                    const SizedBox(width: 8),
                    FilterChip(
                      label: const Text('Low Stock'),
                      selected: true,
                      onSelected: (selected) {},
                      onDeleted: () {
                        setState(() {
                          _showLowStockOnly = false;
                        });
                      },
                    ),
                  ],
                  if (_showExpiringSoon) ...[
                    const SizedBox(width: 8),
                    FilterChip(
                      label: const Text('Expiring Soon'),
                      selected: true,
                      onSelected: (selected) {},
                      onDeleted: () {
                        setState(() {
                          _showExpiringSoon = false;
                        });
                      },
                    ),
                  ],
                ],
              ),
            ),

          // Medications List
          Expanded(
            child: medicationsAsync.when(
              data: (medications) {
                final filteredMedications = _filterMedications(medications);
                
                if (filteredMedications.isEmpty) {
                  return _buildEmptyState();
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredMedications.length,
                  itemBuilder: (context, index) {
                    final medication = filteredMedications[index];
                    return _buildMedicationCard(medication);
                  },
                );
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
                      onPressed: () => ref.refresh(medicationListProvider),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/medications/add'),
        child: const Icon(Icons.add),
      ),
    );
  }

  List<Medication> _filterMedications(List<Medication> medications) {
    return medications.where((medication) {
      // Search filter
      final matchesSearch = _searchQuery.isEmpty ||
          medication.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (medication.brandManufacturer?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);

      // Type filter
      final matchesType = _selectedType == null || medication.type == _selectedType;

      // Low stock filter
      final matchesLowStock = !_showLowStockOnly || medication.isLowStock;

      // Expiring soon filter
      final matchesExpiring = !_showExpiringSoon || medication.isExpiringSoon;

      return matchesSearch && matchesType && matchesLowStock && matchesExpiring;
    }).toList();
  }

  Widget _buildMedicationCard(Medication medication) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => context.push('/medications/${medication.id}'),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Medication Icon
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _getMedicationTypeColor(medication.type),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _getMedicationTypeIcon(medication.type),
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  
                  // Name and Brand
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          medication.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        if (medication.brandManufacturer != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            medication.brandManufacturer!,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  
                  // Status Indicators
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (medication.isLowStock)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.1),
                            border: Border.all(color: Colors.orange),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'Low Stock',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange,
                            ),
                          ),
                        ),
                      if (medication.isExpired)
                        Container(
                          margin: const EdgeInsets.only(top: 4),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.1),
                            border: Border.all(color: Colors.red),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'Expired',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.red,
                            ),
                          ),
                        )
                      else if (medication.isExpiringSoon)
                        Container(
                          margin: const EdgeInsets.only(top: 4),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.yellow.withOpacity(0.1),
                            border: Border.all(color: Colors.orange),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'Expires Soon',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              // Details
              Row(
                children: [
                  Expanded(
                    child: _buildDetailItem(
                      'Strength',
                      medication.displayStrength,
                      Icons.medication,
                    ),
                  ),
                  Expanded(
                    child: _buildDetailItem(
                      'Stock',
                      medication.stockDisplay,
                      Icons.inventory,
                    ),
                  ),
                  Expanded(
                    child: _buildDetailItem(
                      'Type',
                      medication.type.displayName,
                      Icons.category,
                    ),
                  ),
                ],
              ),
              
              if (medication.expirationDate != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.schedule,
                      size: 16,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Expires: ${_formatDate(medication.expirationDate!)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailItem(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(
          icon,
          size: 14,
          color: Colors.grey[600],
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.medication_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No medications found',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add your first medication to get started',
            style: TextStyle(
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => context.push('/medications/add'),
            icon: const Icon(Icons.add),
            label: const Text('Add Medication'),
          ),
        ],
      ),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Filter Medications'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Type',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<MedicationType?>(
                value: _selectedType,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                items: [
                  const DropdownMenuItem<MedicationType?>(
                    value: null,
                    child: Text('All Types'),
                  ),
                  ...MedicationType.values.map((type) => DropdownMenuItem(
                    value: type,
                    child: Text(type.displayName),
                  )),
                ],
                onChanged: (value) {
                  setDialogState(() {
                    _selectedType = value;
                  });
                },
              ),
              const SizedBox(height: 16),
              
              CheckboxListTile(
                title: const Text('Show Low Stock Only'),
                value: _showLowStockOnly,
                onChanged: (value) {
                  setDialogState(() {
                    _showLowStockOnly = value ?? false;
                  });
                },
                contentPadding: EdgeInsets.zero,
              ),
              
              CheckboxListTile(
                title: const Text('Show Expiring Soon Only'),
                value: _showExpiringSoon,
                onChanged: (value) {
                  setDialogState(() {
                    _showExpiringSoon = value ?? false;
                  });
                },
                contentPadding: EdgeInsets.zero,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                setDialogState(() {
                  _selectedType = null;
                  _showLowStockOnly = false;
                  _showExpiringSoon = false;
                });
              },
              child: const Text('Clear'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  // Filters are already set in dialog state
                });
                Navigator.of(context).pop();
              },
              child: const Text('Apply'),
            ),
          ],
        ),
      ),
    );
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

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = date.difference(now).inDays;
    
    if (difference < 0) {
      return '${(-difference)} days ago';
    } else if (difference == 0) {
      return 'Today';
    } else if (difference == 1) {
      return 'Tomorrow';
    } else if (difference < 30) {
      return 'In $difference days';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
