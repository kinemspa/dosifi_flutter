import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../presentation/providers/supply_provider.dart';
import '../../data/models/supply.dart';

class SupplyInventoryScreen extends ConsumerStatefulWidget {
  const SupplyInventoryScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<SupplyInventoryScreen> createState() => _SupplyInventoryScreenState();
}

class _SupplyInventoryScreenState extends ConsumerState<SupplyInventoryScreen> {
  String _searchQuery = '';
  SupplyCategory? _selectedCategory;

  @override
  Widget build(BuildContext context) {
    final suppliesAsync = ref.watch(supplyListProvider);
    final stats = ref.watch(supplyStatsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Supply Inventory'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => _showSearchDialog(),
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showFilterDialog(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Statistics Cards
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Total Items',
                    stats['total'].toString(),
                    Icons.inventory,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildStatCard(
                    'Low Stock',
                    stats['lowStock'].toString(),
                    Icons.warning,
                    Colors.orange,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildStatCard(
                    'Expired',
                    stats['expired'].toString(),
                    Icons.error,
                    Colors.red,
                  ),
                ),
              ],
            ),
          ),
          // Supply List
          Expanded(
            child: suppliesAsync.when(
              data: (supplies) {
                final filteredSupplies = _filterSupplies(supplies);
                if (filteredSupplies.isEmpty) {
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
                          supplies.isEmpty ? 'No supplies available' : 'No supplies match your filters',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          supplies.isEmpty ? 'Add your first supply to get started' : 'Try adjusting your search or filters',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: filteredSupplies.length,
                  itemBuilder: (context, index) {
                    final supply = filteredSupplies[index];
                    return _buildSupplyCard(supply);
                  },
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
                      color: Colors.red[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Error loading supplies',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      error.toString(),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => ref.refresh(supplyListProvider),
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
        onPressed: () => _showAddSupplyDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              value,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSupplyCard(Supply supply) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getCategoryColor(supply.category),
          child: Icon(
            _getCategoryIcon(supply.category),
            color: Colors.white,
          ),
        ),
        title: Text(
          supply.displayName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${supply.quantity} ${supply.unit ?? 'pieces'}'),
            if (supply.brand != null) Text('Brand: ${supply.brand}'),
            if (supply.isLowStock || supply.isExpired || supply.isExpiringSoon)
              Wrap(
                spacing: 4,
                children: [
                  if (supply.isExpired)
                    Chip(
                      label: const Text('Expired', style: TextStyle(fontSize: 10)),
                      backgroundColor: Colors.red[100],
                      labelStyle: TextStyle(color: Colors.red[800]),
                    ),
                  if (supply.isExpiringSoon)
                    Chip(
                      label: const Text('Expiring Soon', style: TextStyle(fontSize: 10)),
                      backgroundColor: Colors.orange[100],
                      labelStyle: TextStyle(color: Colors.orange[800]),
                    ),
                  if (supply.isLowStock)
                    Chip(
                      label: const Text('Low Stock', style: TextStyle(fontSize: 10)),
                      backgroundColor: Colors.yellow[100],
                      labelStyle: TextStyle(color: Colors.yellow[800]),
                    ),
                ],
              ),
          ],
        ),
        trailing: PopupMenuButton(
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit, size: 16),
                  SizedBox(width: 8),
                  Text('Edit'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'adjust',
              child: Row(
                children: [
                  Icon(Icons.add_circle_outline, size: 16),
                  SizedBox(width: 8),
                  Text('Adjust Quantity'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, size: 16, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Delete', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
          onSelected: (value) => _handleSupplyAction(supply, value.toString()),
        ),
        onTap: () => _showSupplyDetails(supply),
      ),
    );
  }

  List<Supply> _filterSupplies(List<Supply> supplies) {
    var filtered = supplies;

    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((supply) {
        return supply.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
               (supply.brand?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false) ||
               supply.category.displayName.toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList();
    }

    if (_selectedCategory != null) {
      filtered = filtered.where((supply) => supply.category == _selectedCategory).toList();
    }

    return filtered;
  }

  Color _getCategoryColor(SupplyCategory category) {
    switch (category) {
      case SupplyCategory.syringe:
        return Colors.blue;
      case SupplyCategory.needle:
        return Colors.green;
      case SupplyCategory.swab:
        return Colors.orange;
      case SupplyCategory.bandage:
        return Colors.red;
      case SupplyCategory.gauze:
        return Colors.purple;
      case SupplyCategory.tape:
        return Colors.teal;
      case SupplyCategory.gloves:
        return Colors.indigo;
      case SupplyCategory.wipe:
        return Colors.cyan;
      case SupplyCategory.container:
        return Colors.brown;
      case SupplyCategory.other:
        return Colors.grey;
    }
  }

  IconData _getCategoryIcon(SupplyCategory category) {
    switch (category) {
      case SupplyCategory.syringe:
        return Icons.vaccines;
      case SupplyCategory.needle:
        return Icons.colorize;
      case SupplyCategory.swab:
        return Icons.cleaning_services;
      case SupplyCategory.bandage:
        return Icons.healing;
      case SupplyCategory.gauze:
        return Icons.medical_services;
      case SupplyCategory.tape:
        return Icons.sticky_note_2;
      case SupplyCategory.gloves:
        return Icons.back_hand;
      case SupplyCategory.wipe:
        return Icons.clean_hands;
      case SupplyCategory.container:
        return Icons.inventory_2;
      case SupplyCategory.other:
        return Icons.more_horiz;
    }
  }

  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Search Supplies'),
        content: TextField(
          decoration: const InputDecoration(
            hintText: 'Enter supply name, brand, or category...',
            prefixIcon: Icon(Icons.search),
          ),
          onChanged: (value) => setState(() => _searchQuery = value),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() => _searchQuery = '');
              Navigator.pop(context);
            },
            child: const Text('Clear'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter by Category'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<SupplyCategory?>(
              title: const Text('All Categories'),
              value: null,
              groupValue: _selectedCategory,
              onChanged: (value) => setState(() => _selectedCategory = value),
            ),
            ...SupplyCategory.values.map((category) => RadioListTile<SupplyCategory?>(
              title: Text(category.displayName),
              value: category,
              groupValue: _selectedCategory,
              onChanged: (value) => setState(() => _selectedCategory = value),
            )),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  void _showAddSupplyDialog() {
    final nameController = TextEditingController();
    final brandController = TextEditingController();
    final sizeController = TextEditingController();
    final quantityController = TextEditingController();
    final reorderLevelController = TextEditingController();
    final unitController = TextEditingController(text: 'pieces');
    final lotController = TextEditingController();
    final locationController = TextEditingController();
    final notesController = TextEditingController();
    SupplyCategory selectedCategory = SupplyCategory.other;
    DateTime? expirationDate;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add New Supply'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Supply Name *',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<SupplyCategory>(
                  value: selectedCategory,
                  decoration: const InputDecoration(
                    labelText: 'Category *',
                    border: OutlineInputBorder(),
                  ),
                  items: SupplyCategory.values.map((category) => DropdownMenuItem(
                    value: category,
                    child: Text(category.displayName),
                  )).toList(),
                  onChanged: (value) => setDialogState(() => selectedCategory = value!),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: brandController,
                  decoration: const InputDecoration(
                    labelText: 'Brand/Manufacturer',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: quantityController,
                        decoration: const InputDecoration(
                          labelText: 'Quantity *',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: unitController,
                        decoration: const InputDecoration(
                          labelText: 'Unit',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: sizeController,
                  decoration: const InputDecoration(
                    labelText: 'Size (e.g., 1ml, 25G)',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.isNotEmpty && quantityController.text.isNotEmpty) {
                  final supply = Supply.create(
                    name: nameController.text.trim(),
                    category: selectedCategory,
                    brand: brandController.text.trim().isEmpty ? null : brandController.text.trim(),
                    size: sizeController.text.trim().isEmpty ? null : sizeController.text.trim(),
                    quantity: int.tryParse(quantityController.text) ?? 0,
                    reorderLevel: int.tryParse(reorderLevelController.text),
                    unit: unitController.text.trim().isEmpty ? 'pieces' : unitController.text.trim(),
                    lotNumber: lotController.text.trim().isEmpty ? null : lotController.text.trim(),
                    expirationDate: expirationDate,
                    location: locationController.text.trim().isEmpty ? null : locationController.text.trim(),
                    notes: notesController.text.trim().isEmpty ? null : notesController.text.trim(),
                  );
                  
                  await ref.read(supplyListProvider.notifier).addSupply(supply);
                  Navigator.pop(context);
                }
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  void _showSupplyDetails(Supply supply) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(supply.displayName),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('Category', supply.category.displayName),
            if (supply.brand != null) _buildDetailRow('Brand', supply.brand!),
            _buildDetailRow('Quantity', '${supply.quantity} ${supply.unit ?? 'pieces'}'),
            if (supply.reorderLevel != null) _buildDetailRow('Reorder Level', supply.reorderLevel.toString()),
            if (supply.lotNumber != null) _buildDetailRow('Lot Number', supply.lotNumber!),
            if (supply.expirationDate != null) 
              _buildDetailRow('Expiration', supply.expirationDate!.toString().split(' ')[0]),
            if (supply.location != null) _buildDetailRow('Location', supply.location!),
            if (supply.notes != null) _buildDetailRow('Notes', supply.notes!),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  void _handleSupplyAction(Supply supply, String action) {
    switch (action) {
      case 'edit':
        _showEditSupplyDialog(supply);
        break;
      case 'adjust':
        _showAdjustQuantityDialog(supply);
        break;
      case 'delete':
        _showDeleteConfirmation(supply);
        break;
    }
  }

  void _showEditSupplyDialog(Supply supply) {
    // Implementation for editing supply
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Edit functionality coming soon!')),
    );
  }

  void _showAdjustQuantityDialog(Supply supply) {
    final controller = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Adjust Quantity - ${supply.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Current Quantity: ${supply.quantity} ${supply.unit ?? 'pieces'}'),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Adjustment (+/-)',
                hintText: 'e.g., +10 or -5',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.numberWithOptions(signed: true),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final adjustment = int.tryParse(controller.text.replaceAll('+', ''));
              if (adjustment != null && supply.id != null) {
                await ref.read(supplyListProvider.notifier).adjustQuantity(supply.id!, adjustment);
                Navigator.pop(context);
              }
            },
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(Supply supply) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Supply'),
        content: Text('Are you sure you want to delete "${supply.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (supply.id != null) {
                await ref.read(supplyListProvider.notifier).deleteSupply(supply.id!);
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

