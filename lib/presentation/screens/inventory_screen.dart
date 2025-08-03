import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/inventory.dart';
import '../../data/models/medication.dart';
import '../../core/utils/medication_utils.dart';
import '../providers/inventory_provider.dart';
import '../providers/medication_provider.dart';

class InventoryScreen extends ConsumerStatefulWidget {
  const InventoryScreen({super.key});

  @override
  ConsumerState<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends ConsumerState<InventoryScreen> {
  String _sortBy = 'name';
  bool _showLowStock = false;

  @override
  Widget build(BuildContext context) {
    final inventoryAsync = ref.watch(inventoryListProvider);
    final medications = ref.watch(medicationListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventory Management'),
        actions: [
          IconButton(
            icon: Icon(_showLowStock ? Icons.warning : Icons.warning_amber_outlined),
            onPressed: () {
              setState(() {
                _showLowStock = !_showLowStock;
              });
            },
            tooltip: 'Show low stock only',
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort),
            onSelected: (value) {
              setState(() {
                _sortBy = value;
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'name', child: Text('Sort by Name')),
              const PopupMenuItem(value: 'quantity', child: Text('Sort by Quantity')),
              const PopupMenuItem(value: 'expiry', child: Text('Sort by Expiry')),
            ],
          ),
        ],
      ),
      body: inventoryAsync.when(
        data: (inventoryList) {
          if (inventoryList.isEmpty) {
            return _buildEmptyState();
          }

          var filteredList = _showLowStock
              ? inventoryList.where((inv) => 
                  inv.reorderLevel != null && inv.quantity <= inv.reorderLevel!).toList()
              : inventoryList;

          // Sort the list
          filteredList.sort((a, b) {
            switch (_sortBy) {
              case 'quantity':
                return a.quantity.compareTo(b.quantity);
              case 'expiry':
                if (a.expiryDate == null && b.expiryDate == null) return 0;
                if (a.expiryDate == null) return 1;
                if (b.expiryDate == null) return -1;
                return a.expiryDate!.compareTo(b.expiryDate!);
              default:
                // Sort by medication name (need to fetch medication details)
                return 0;
            }
          });

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: filteredList.length,
            itemBuilder: (context, index) {
              final inventory = filteredList[index];
              return _buildInventoryCard(inventory);
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
                  ref.refresh(inventoryListProvider);
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddInventoryDialog,
        label: const Text('Add Stock'),
        icon: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: 64,
            color: Theme.of(context).disabledColor,
          ),
          const SizedBox(height: 16),
          Text(
            'No inventory items yet',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Add stock for your medications',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _showAddInventoryDialog,
            icon: const Icon(Icons.add),
            label: const Text('Add First Stock'),
          ),
        ],
      ),
    );
  }

  Widget _buildInventoryCard(Inventory inventory) {
    final medicationAsync = ref.watch(medicationByIdProvider(inventory.medicationId));
    
    return medicationAsync.when(
      data: (medication) {
        if (medication == null) return const SizedBox.shrink();
        
        final isLowStock = inventory.reorderLevel != null && 
                          inventory.quantity <= inventory.reorderLevel!;
        final isExpired = inventory.expiryDate != null && 
                         inventory.expiryDate!.isBefore(DateTime.now());
        final isExpiringSoon = inventory.expiryDate != null && 
                              inventory.expiryDate!.isBefore(
                                DateTime.now().add(const Duration(days: 30))
                              );

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          color: isExpired ? Colors.red.shade50 : null,
          child: InkWell(
            onTap: () => _showEditInventoryDialog(inventory, medication),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              medication.name,
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              medication.displayStrength,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${inventory.quantity}',
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: isLowStock ? Colors.orange : null,
                            ),
                          ),
                          Text(
                            inventory.unit,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (inventory.batchNumber != null) ...[
                    _buildInfoRow('Batch', inventory.batchNumber!),
                    const SizedBox(height: 4),
                  ],
                  if (inventory.location != null) ...[
                    _buildInfoRow('Location', inventory.location!),
                    const SizedBox(height: 4),
                  ],
                  if (inventory.expiryDate != null) ...[
                    _buildInfoRow(
                      'Expiry',
                      '${inventory.expiryDate!.day}/${inventory.expiryDate!.month}/${inventory.expiryDate!.year}',
                      isExpired ? Colors.red : isExpiringSoon ? Colors.orange : null,
                    ),
                    const SizedBox(height: 4),
                  ],
                  if (inventory.reorderLevel != null) ...[
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: inventory.quantity / (inventory.reorderLevel! * 2),
                      backgroundColor: Colors.grey.shade300,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        isLowStock ? Colors.orange : Theme.of(context).primaryColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Reorder at: ${inventory.reorderLevel} ${inventory.unit}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                  if (isExpired || isLowStock) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        if (isExpired)
                          Chip(
                            label: const Text('Expired'),
                            backgroundColor: Colors.red,
                            labelStyle: const TextStyle(color: Colors.white),
                            visualDensity: VisualDensity.compact,
                          ),
                        if (isLowStock)
                          Chip(
                            label: const Text('Low Stock'),
                            backgroundColor: Colors.orange,
                            labelStyle: const TextStyle(color: Colors.white),
                            visualDensity: VisualDensity.compact,
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
      loading: () => const Card(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: CircularProgressIndicator(),
          ),
        ),
      ),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildInfoRow(String label, String value, [Color? valueColor]) {
    return Row(
      children: [
        Text(
          '$label: ',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: valueColor,
          ),
        ),
      ],
    );
  }

  void _showAddInventoryDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => const AddInventorySheet(),
    );
  }

  void _showEditInventoryDialog(Inventory inventory, Medication medication) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => EditInventorySheet(
        inventory: inventory,
        medication: medication,
      ),
    );
  }
}

class AddInventorySheet extends ConsumerStatefulWidget {
  const AddInventorySheet({super.key});

  @override
  ConsumerState<AddInventorySheet> createState() => _AddInventorySheetState();
}

class _AddInventorySheetState extends ConsumerState<AddInventorySheet> {
  final _formKey = GlobalKey<FormState>();
  final _quantityController = TextEditingController();
  final _unitController = TextEditingController();
  final _reorderLevelController = TextEditingController();
  final _batchNumberController = TextEditingController();
  final _locationController = TextEditingController();
  final _notesController = TextEditingController();
  
  int? _selectedMedicationId;
  DateTime? _expiryDate;

  @override
  Widget build(BuildContext context) {
    final medications = ref.watch(medicationListProvider);

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Add Inventory',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                medications.when(
                  data: (medicationList) => DropdownButtonFormField<int>(
                    value: _selectedMedicationId,
                    decoration: const InputDecoration(
                      labelText: 'Select Medication',
                      border: OutlineInputBorder(),
                    ),
                    items: medicationList.map((med) => DropdownMenuItem(
                      value: med.id,
                      child: Text('${med.name} - ${med.displayStrength} - ${MedicationUtils.getInventoryLabel(med.type)}'),
                    )).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedMedicationId = value;

                        // Update default unit based on selected medication type
                        if (value != null) {
                          final medication = medicationList.firstWhere((med) => med.id == value);
                          _unitController.text = MedicationUtils.getInventoryLabel(medication.type).split(' ')[2];
                        }
                      });
                    },
                    validator: (value) {
                      if (value == null) {
                        return 'Please select a medication';
                      }
                      return null;
                    },
                  ),
                  loading: () => const CircularProgressIndicator(),
                  error: (_, __) => const Text('Error loading medications'),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        controller: _quantityController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Quantity',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Required';
                          }
                          if (double.tryParse(value) == null) {
                            return 'Invalid number';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        controller: _unitController,
                        decoration: const InputDecoration(
                          labelText: 'Unit',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Required';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _reorderLevelController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Reorder Level (Optional)',
                    border: OutlineInputBorder(),
                    helperText: 'Get notified when stock is low',
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _batchNumberController,
                  decoration: const InputDecoration(
                    labelText: 'Batch Number (Optional)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  title: const Text('Expiry Date'),
                  subtitle: Text(
                    _expiryDate != null
                        ? '${_expiryDate!.day}/${_expiryDate!.month}/${_expiryDate!.year}'
                        : 'Not set',
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.calendar_today),
                    onPressed: _selectExpiryDate,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(color: Theme.of(context).dividerColor),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _locationController,
                  decoration: const InputDecoration(
                    labelText: 'Storage Location (Optional)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _notesController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Notes (Optional)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _saveInventory,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.all(16),
                  ),
                  child: const Text('Add to Inventory'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _selectExpiryDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 90)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );
    if (picked != null && picked != _expiryDate) {
      setState(() {
        _expiryDate = picked;
      });
    }
  }

  void _saveInventory() {
    if (_formKey.currentState!.validate()) {
      final inventory = Inventory.create(
        medicationId: _selectedMedicationId!,
        quantity: double.parse(_quantityController.text),
        unit: _unitController.text,
        reorderLevel: _reorderLevelController.text.isNotEmpty
            ? double.parse(_reorderLevelController.text)
            : null,
        batchNumber: _batchNumberController.text.isNotEmpty
            ? _batchNumberController.text
            : null,
        expiryDate: _expiryDate,
        location: _locationController.text.isNotEmpty
            ? _locationController.text
            : null,
        notes: _notesController.text.isNotEmpty
            ? _notesController.text
            : null,
      );

      ref.read(inventoryListProvider.notifier).addInventory(inventory);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Inventory added successfully')),
      );
      
      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _unitController.dispose();
    _reorderLevelController.dispose();
    _batchNumberController.dispose();
    _locationController.dispose();
    _notesController.dispose();
    super.dispose();
  }
}

class EditInventorySheet extends ConsumerStatefulWidget {
  final Inventory inventory;
  final Medication medication;

  const EditInventorySheet({
    super.key,
    required this.inventory,
    required this.medication,
  });

  @override
  ConsumerState<EditInventorySheet> createState() => _EditInventorySheetState();
}

class _EditInventorySheetState extends ConsumerState<EditInventorySheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _quantityController;
  late final TextEditingController _unitController;
  late final TextEditingController _reorderLevelController;
  late final TextEditingController _batchNumberController;
  late final TextEditingController _locationController;
  late final TextEditingController _notesController;
  
  DateTime? _expiryDate;

  @override
  void initState() {
    super.initState();
    _quantityController = TextEditingController(text: widget.inventory.quantity.toString());
    _unitController = TextEditingController(text: widget.inventory.unit);
    _reorderLevelController = TextEditingController(
      text: widget.inventory.reorderLevel?.toString() ?? ''
    );
    _batchNumberController = TextEditingController(text: widget.inventory.batchNumber ?? '');
    _locationController = TextEditingController(text: widget.inventory.location ?? '');
    _notesController = TextEditingController(text: widget.inventory.notes ?? '');
    _expiryDate = widget.inventory.expiryDate;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Edit Inventory',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  '${widget.medication.name} - ${widget.medication.displayStrength}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        controller: _quantityController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Quantity',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Required';
                          }
                          if (double.tryParse(value) == null) {
                            return 'Invalid number';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        controller: _unitController,
                        decoration: const InputDecoration(
                          labelText: 'Unit',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Required';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _reorderLevelController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Reorder Level (Optional)',
                    border: OutlineInputBorder(),
                    helperText: 'Get notified when stock is low',
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _batchNumberController,
                  decoration: const InputDecoration(
                    labelText: 'Batch Number (Optional)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  title: const Text('Expiry Date'),
                  subtitle: Text(
                    _expiryDate != null
                        ? '${_expiryDate!.day}/${_expiryDate!.month}/${_expiryDate!.year}'
                        : 'Not set',
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.calendar_today),
                    onPressed: _selectExpiryDate,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(color: Theme.of(context).dividerColor),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _locationController,
                  decoration: const InputDecoration(
                    labelText: 'Storage Location (Optional)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _notesController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Notes (Optional)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _deleteInventory,
                        icon: const Icon(Icons.delete, color: Colors.red),
                        label: const Text('Delete', style: TextStyle(color: Colors.red)),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.all(16),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _updateInventory,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.all(16),
                        ),
                        child: const Text('Update'),
                      ),
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

  Future<void> _selectExpiryDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _expiryDate ?? DateTime.now().add(const Duration(days: 90)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );
    if (picked != null && picked != _expiryDate) {
      setState(() {
        _expiryDate = picked;
      });
    }
  }

  void _updateInventory() {
    if (_formKey.currentState!.validate()) {
      final updatedInventory = widget.inventory.copyWith(
        quantity: double.parse(_quantityController.text),
        unit: _unitController.text,
        reorderLevel: _reorderLevelController.text.isNotEmpty
            ? double.parse(_reorderLevelController.text)
            : null,
        batchNumber: _batchNumberController.text.isNotEmpty
            ? _batchNumberController.text
            : null,
        expiryDate: _expiryDate,
        location: _locationController.text.isNotEmpty
            ? _locationController.text
            : null,
        notes: _notesController.text.isNotEmpty
            ? _notesController.text
            : null,
      );

      ref.read(inventoryListProvider.notifier).updateInventory(updatedInventory);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Inventory updated successfully')),
      );
      
      Navigator.pop(context);
    }
  }

  void _deleteInventory() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Inventory Item'),
        content: const Text('Are you sure you want to delete this inventory item?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(inventoryListProvider.notifier).deleteInventory(widget.inventory.id!);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Inventory item deleted')),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _unitController.dispose();
    _reorderLevelController.dispose();
    _batchNumberController.dispose();
    _locationController.dispose();
    _notesController.dispose();
    super.dispose();
  }
}
