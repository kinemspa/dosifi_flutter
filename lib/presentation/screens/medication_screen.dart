import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/models/medication.dart';
import '../../data/models/supply.dart';
import '../providers/medication_provider.dart';
import '../providers/supply_provider.dart';
import '../widgets/medication_card.dart';
import '../screens/supply_inventory_screen.dart';

class MedicationScreen extends ConsumerStatefulWidget {
  const MedicationScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<MedicationScreen> createState() => _MedicationScreenState();
}

class _MedicationScreenState extends ConsumerState<MedicationScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';
  MedicationType? _filterType;
  bool _showExpired = true;
  bool _showExpiringSoon = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final medicationsAsync = ref.watch(medicationListProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Medications'),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Medications', icon: Icon(Icons.medication)),
            Tab(text: 'Supplies', icon: Icon(Icons.inventory_2)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: _showSearchDialog,
          ),
          PopupMenuButton<String>(
            onSelected: _handleMenuSelection,
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem(
                value: 'filter',
                child: ListTile(
                  leading: Icon(Icons.filter_list),
                  title: Text('Filter'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'sort',
                child: ListTile(
                  leading: Icon(Icons.sort),
                  title: Text('Sort'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'export',
                child: ListTile(
                  leading: Icon(Icons.download),
                  title: Text('Export'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildMedicationsTab(medicationsAsync),
          _buildSuppliesTab(),
        ],
      ),
      floatingActionButton: _buildFAB(),
    );
  }

  Widget _buildMedicationsTab(AsyncValue<List<Medication>> medicationsAsync) {
    return medicationsAsync.when(
      data: (medications) {
        final filteredMedications = _filterMedications(medications);
        
        if (filteredMedications.isEmpty) {
          return _buildEmptyState();
        }

        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(medicationListProvider);
          },
          child: Column(
            children: [
              if (_searchQuery.isNotEmpty || _filterType != null)
                _buildActiveFiltersBar(filteredMedications.length),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: filteredMedications.length,
                  itemBuilder: (context, index) {
                    final medication = filteredMedications[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: MedicationCard(
                        medication: medication,
                        onTap: () => _navigateToMedicationDetails(medication),
                        onEdit: () => _navigateToEditMedication(medication),
                        onDelete: () => _showDeleteConfirmation(medication),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Error loading medications',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => ref.invalidate(medicationListProvider),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuppliesTab() {
    final suppliesAsync = ref.watch(supplyListProvider);
    
    return suppliesAsync.when(
      data: (supplies) {
        if (supplies.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.inventory_2_outlined,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'No Supplies Added',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Tap the + button to add your first supply',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(supplyListProvider);
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: supplies.length,
            itemBuilder: (context, index) {
              final supply = supplies[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12.0),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    child: Icon(
                      Icons.inventory_2,
                      color: Theme.of(context).colorScheme.onPrimary,
                    ),
                  ),
                  title: Text(
                    supply.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Category: ${supply.category}'),
                      Text('Current Stock: ${supply.currentStock} ${supply.unit}'),
                      if (supply.expirationDate != null)
                        Text('Expires: ${supply.expirationDate!.toLocal().toString().split(' ')[0]}'),
                    ],
                  ),
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) {
                      switch (value) {
                        case 'edit':
                          // Navigate to edit supply
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Edit supply functionality coming soon')),
                          );
                          break;
                        case 'delete':
                          _showDeleteSupplyConfirmation(supply);
                          break;
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: ListTile(
                          leading: Icon(Icons.edit),
                          title: Text('Edit'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: ListTile(
                          leading: Icon(Icons.delete),
                          title: Text('Delete'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ],
                  ),
                  onTap: () {
                    // Navigate to supply details
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Supply details functionality coming soon')),
                    );
                  },
                ),
              );
            },
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Error loading supplies',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => ref.invalidate(supplyListProvider),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.medication_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No Medications Added',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap the + button to add your first medication',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveFiltersBar(int resultCount) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Wrap(
              spacing: 8,
              children: [
                if (_searchQuery.isNotEmpty)
                  Chip(
                    label: Text('Search: $_searchQuery'),
                    onDeleted: () => setState(() => _searchQuery = ''),
                    deleteIcon: const Icon(Icons.close, size: 18),
                  ),
                if (_filterType != null)
                  Chip(
                    label: Text('Type: ${_filterType!.displayName}'),
                    onDeleted: () => setState(() => _filterType = null),
                    deleteIcon: const Icon(Icons.close, size: 18),
                  ),
              ],
            ),
          ),
          Text(
            '$resultCount result${resultCount != 1 ? 's' : ''}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  Widget _buildFAB() {
    return FloatingActionButton.extended(
      onPressed: () => _showAddMenuBottomSheet(),
      icon: const Icon(Icons.add),
      label: const Text('Add'),
      tooltip: 'Add Medications and Supplies',
    );
  }

  void _showAddMenuBottomSheet() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.medication),
                title: const Text('Add Medication'),
                subtitle: const Text('Add a new medication to your inventory'),
                onTap: () {
                  Navigator.pop(context);
                  context.push('/add-medication-comprehensive');
                },
              ),
              ListTile(
                leading: const Icon(Icons.inventory_2),
                title: const Text('Add Supply'),
                subtitle: const Text('Add medical supplies and consumables'),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Add Supply functionality coming soon')),
                  );
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.qr_code_scanner),
                title: const Text('Scan Barcode'),
                subtitle: const Text('Scan medication barcode to auto-fill details'),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Barcode scanning functionality coming soon')),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        String tempSearchQuery = _searchQuery;
        return AlertDialog(
          title: const Text('Search Medications'),
          content: TextField(
            autofocus: true,
            decoration: const InputDecoration(
              hintText: 'Enter medication name...',
              prefixIcon: Icon(Icons.search),
            ),
            onChanged: (value) => tempSearchQuery = value,
            controller: TextEditingController(text: _searchQuery),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() => _searchQuery = tempSearchQuery);
                Navigator.pop(context);
              },
              child: const Text('Search'),
            ),
          ],
        );
      },
    );
  }

  void _handleMenuSelection(String value) {
    switch (value) {
      case 'filter':
        _showFilterDialog();
        break;
      case 'sort':
        _showSortDialog();
        break;
      case 'export':
        _exportMedications();
        break;
    }
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Filter Medications'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Medication Type:'),
              const SizedBox(height: 8),
              DropdownButtonFormField<MedicationType>(
                value: _filterType,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'All types',
                ),
                items: [
                  const DropdownMenuItem(
                    value: null,
                    child: Text('All types'),
                  ),
                  ...MedicationType.values.map((type) => DropdownMenuItem(
                    value: type,
                    child: Text(type.displayName),
                  )),
                ],
                onChanged: (value) => _filterType = value,
              ),
              const SizedBox(height: 16),
              CheckboxListTile(
                title: const Text('Show Expired'),
                value: _showExpired,
                onChanged: (value) => setState(() => _showExpired = value!),
                contentPadding: EdgeInsets.zero,
              ),
              CheckboxListTile(
                title: const Text('Show Expiring Soon'),
                value: _showExpiringSoon,
                onChanged: (value) => setState(() => _showExpiringSoon = value!),
                contentPadding: EdgeInsets.zero,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {});
                Navigator.pop(context);
              },
              child: const Text('Apply'),
            ),
          ],
        );
      },
    );
  }

  void _showSortDialog() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Sort functionality coming soon')),
    );
  }

  void _exportMedications() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Export functionality coming soon')),
    );
  }

  List<Medication> _filterMedications(List<Medication> medications) {
    return medications.where((medication) {
      // Search filter
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final matchesName = medication.name.toLowerCase().contains(query);
        final matchesBrand = medication.brandManufacturer?.toLowerCase().contains(query) ?? false;
        if (!matchesName && !matchesBrand) return false;
      }

      // Type filter
      if (_filterType != null && medication.type != _filterType) {
        return false;
      }

      // Expiration filters
      if (!_showExpired && medication.isExpired) {
        return false;
      }

      if (!_showExpiringSoon && medication.isExpiringSoon && !medication.isExpired) {
        return false;
      }

      return true;
    }).toList();
  }

  void _navigateToMedicationDetails(Medication medication) {
    context.push('/medication-details/${medication.id}');
  }

  void _navigateToEditMedication(Medication medication) {
    context.push('/edit-medication/${medication.id}');
  }

  void _showDeleteConfirmation(Medication medication) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Medication'),
          content: Text(
            'Are you sure you want to delete "${medication.name}"? This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                try {
                  await ref.read(medicationListProvider.notifier).deleteMedication(medication.id!);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Medication deleted successfully')),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error deleting medication: $e')),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
                foregroundColor: Theme.of(context).colorScheme.onError,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteSupplyConfirmation(Supply supply) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Supply'),
          content: Text(
            'Are you sure you want to delete "${supply.name}"? This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                try {
                  await ref.read(supplyListProvider.notifier).deleteSupply(supply.id!);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Supply deleted successfully')),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error deleting supply: $e')),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
                foregroundColor: Theme.of(context).colorScheme.onError,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }
}
