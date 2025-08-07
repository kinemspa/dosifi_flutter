import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/models/supply.dart';
import '../providers/supply_provider.dart';
import '../../config/app_router.dart';

class AddSupplyScreen extends ConsumerStatefulWidget {
  final String? supplyId;
  
  const AddSupplyScreen({
    Key? key,
    this.supplyId,
  }) : super(key: key);

  @override
  ConsumerState<AddSupplyScreen> createState() => _AddSupplyScreenState();
}

class _AddSupplyScreenState extends ConsumerState<AddSupplyScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _brandController = TextEditingController();
  final _sizeController = TextEditingController();
  final _quantityController = TextEditingController();
  final _reorderLevelController = TextEditingController();
  final _unitController = TextEditingController();
  final _lotNumberController = TextEditingController();
  final _locationController = TextEditingController();
  final _notesController = TextEditingController();
  
  SupplyType _selectedType = SupplyType.item;
  DateTime? _expirationDate;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _unitController.text = SupplyType.item.defaultUnit; // Default unit
  }

  @override
  void dispose() {
    _nameController.dispose();
    _brandController.dispose();
    _sizeController.dispose();
    _quantityController.dispose();
    _reorderLevelController.dispose();
    _unitController.dispose();
    _lotNumberController.dispose();
    _locationController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.supplyId != null;
    
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Supply' : 'Add Medical Supply'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.navigateBackSmart(),
        ),
        actions: [
          if (isEditing)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _showDeleteDialog,
            ),
        ],
      ),
      body: _isLoading
        ? const Center(child: CircularProgressIndicator())
        : Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // Step indicator
                _buildStepIndicator(),
                const SizedBox(height: 32),
                
                // Basic Information Section
                _buildBasicInformationSection(),
                const SizedBox(height: 32),
                
                // Quantity & Stock Section
                _buildQuantityStockSection(),
                const SizedBox(height: 32),
                
                // Additional Information Section
                _buildAdditionalInfoSection(),
                const SizedBox(height: 40),
                
                // Save button
                _buildSaveButton(),
              ],
            ),
          ),
    );
  }

  Widget _buildStepIndicator() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: Colors.blue,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.inventory_2,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Medical Supply Information',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Fill in the details for your medical supply',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBasicInformationSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('Basic Information'),
            
            // Name field
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Supply Name *',
                hintText: 'e.g., BD Syringe',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.inventory_2),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Supply name is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            
            // Type dropdown
            DropdownButtonFormField<SupplyType>(
              value: _selectedType,
              decoration: const InputDecoration(
                labelText: 'Supply Type *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.category),
                helperText: 'Item: countable • Fluid: volumes • Diluent: reconstitution',
              ),
              items: SupplyType.values.map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Row(
                    children: [
                      Icon(
                        _getTypeIcon(type),
                        size: 20,
                        color: _getTypeColor(type),
                      ),
                      const SizedBox(width: 8),
                      Text(type.displayName),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedType = value;
                    // Update unit when type changes
                    _unitController.text = value.defaultUnit;
                  });
                }
              },
            ),
            const SizedBox(height: 16),
            
            // Brand field
            TextFormField(
              controller: _brandController,
              decoration: const InputDecoration(
                labelText: 'Brand/Manufacturer',
                hintText: 'e.g., BD, Terumo',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.business),
              ),
            ),
            const SizedBox(height: 16),
            
            // Size field
            TextFormField(
              controller: _sizeController,
              decoration: const InputDecoration(
                labelText: 'Size/Specification',
                hintText: 'e.g., 1ml, 25G, 2x2 inches',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.straighten),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuantityStockSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('Quantity & Stock Management'),
            
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: _quantityController,
                    decoration: const InputDecoration(
                      labelText: 'Current Quantity *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.inventory),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Quantity is required';
                      }
                      final quantity = double.tryParse(value.trim());
                      if (quantity == null || quantity < 0) {
                        return 'Enter a valid quantity';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _unitController,
                    decoration: const InputDecoration(
                      labelText: 'Unit',
                      hintText: 'pieces, boxes',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Reorder level
            TextFormField(
              controller: _reorderLevelController,
              decoration: const InputDecoration(
                labelText: 'Reorder Level',
                hintText: 'Alert when stock falls below this number',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.notifications),
                helperText: 'Optional: Set minimum stock level for alerts',
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: (value) {
                if (value != null && value.trim().isNotEmpty) {
                  final level = double.tryParse(value.trim());
                  if (level == null || level < 0) {
                    return 'Enter a valid reorder level';
                  }
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdditionalInfoSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('Additional Information'),
            
            // Lot number
            TextFormField(
              controller: _lotNumberController,
              decoration: const InputDecoration(
                labelText: 'Lot/Batch Number',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.qr_code),
              ),
            ),
            const SizedBox(height: 16),
            
            // Expiration date
            InkWell(
              onTap: _selectExpirationDate,
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Expiration Date',
                  suffixIcon: Icon(Icons.calendar_today),
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.schedule),
                ),
                child: Text(
                  _expirationDate != null
                      ? '${_expirationDate!.day}/${_expirationDate!.month}/${_expirationDate!.year}'
                      : 'Select expiration date',
                  style: TextStyle(
                    color: _expirationDate != null
                        ? Theme.of(context).textTheme.bodyLarge?.color
                        : Theme.of(context).hintColor,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Location
            TextFormField(
              controller: _locationController,
              decoration: const InputDecoration(
                labelText: 'Storage Location',
                hintText: 'e.g., Medicine cabinet, Refrigerator',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.location_on),
              ),
            ),
            const SizedBox(height: 16),
            
            // Notes
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Notes',
                hintText: 'Additional information or special instructions',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.notes),
              ),
              maxLines: 3,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    final isEditing = widget.supplyId != null;
    
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _isLoading ? null : _saveSupply,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
        ),
        icon: _isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Icon(isEditing ? Icons.update : Icons.add),
        label: Text(
          isEditing ? 'Update Supply' : 'Add Supply',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  void _showDeleteDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Supply'),
        content: const Text('Are you sure you want to delete this supply? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Implement delete functionality
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Color _getTypeColor(SupplyType type) {
    switch (type) {
      case SupplyType.item:
        return Colors.blue;
      case SupplyType.fluid:
        return Colors.teal;
      case SupplyType.diluent:
        return Colors.purple;
    }
  }

  IconData _getTypeIcon(SupplyType type) {
    switch (type) {
      case SupplyType.item:
        return Icons.inventory_2;
      case SupplyType.fluid:
        return Icons.water_drop;
      case SupplyType.diluent:
        return Icons.science;
    }
  }

  Future<void> _selectExpirationDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _expirationDate ?? DateTime.now().add(const Duration(days: 365)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 10)),
    );

    if (pickedDate != null) {
      setState(() {
        _expirationDate = pickedDate;
      });
    }
  }

  Future<void> _saveSupply() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final supply = Supply.create(
        name: _nameController.text.trim(),
        type: _selectedType,
        brand: _brandController.text.trim().isEmpty ? null : _brandController.text.trim(),
        size: _sizeController.text.trim().isEmpty ? null : _sizeController.text.trim(),
        quantity: double.parse(_quantityController.text.trim()),
        reorderLevel: _reorderLevelController.text.trim().isEmpty
            ? null
            : double.parse(_reorderLevelController.text.trim()),
        unit: _unitController.text.trim().isEmpty ? _selectedType.defaultUnit : _unitController.text.trim(),
        lotNumber: _lotNumberController.text.trim().isEmpty ? null : _lotNumberController.text.trim(),
        expirationDate: _expirationDate,
        location: _locationController.text.trim().isEmpty ? null : _locationController.text.trim(),
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      );
      
      await ref.read(supplyListProvider.notifier).addSupply(supply);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Supply added successfully!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
        
        // Wait a moment before navigating to ensure the snackbar is shown
        await Future.delayed(const Duration(milliseconds: 500));
        
        if (mounted && Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
      }
    } catch (e) {
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error adding supply: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
