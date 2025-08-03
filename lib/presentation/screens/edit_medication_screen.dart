import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/medication.dart';
import '../../core/utils/medication_utils.dart';
import '../providers/medication_provider.dart';

class EditMedicationScreen extends ConsumerStatefulWidget {
  final String medicationId;
  
  const EditMedicationScreen({
    super.key,
    required this.medicationId,
  });

  @override
  ConsumerState<EditMedicationScreen> createState() => _EditMedicationScreenState();
}

class _EditMedicationScreenState extends ConsumerState<EditMedicationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _brandController = TextEditingController();
  final _strengthController = TextEditingController();
  final _numberOfUnitsController = TextEditingController();
  final _instructionsController = TextEditingController();
  final _notesController = TextEditingController();
  final _batchNumberController = TextEditingController();
  
  MedicationType? _selectedType;
  StrengthUnit? _selectedStrengthUnit;
  
  DateTime? _expirationDate;
  bool _isLoading = true;
  Medication? _medication;

  @override
  void initState() {
    super.initState();
    _loadMedication();
  }

  Future<void> _loadMedication() async {
    final medication = await ref.read(
      medicationByIdProvider(int.parse(widget.medicationId)).future
    );
    
    if (medication != null && mounted) {
      setState(() {
        _medication = medication;
        _nameController.text = medication.name;
        _brandController.text = medication.brandManufacturer ?? '';
        _selectedType = medication.type;
        _strengthController.text = medication.strengthPerUnit.toString();
        _selectedStrengthUnit = medication.strengthUnit;
        _numberOfUnitsController.text = medication.stockQuantity.toString();
        _instructionsController.text = medication.instructions ?? '';
        _notesController.text = medication.notes ?? '';
        _batchNumberController.text = medication.lotBatchNumber ?? '';
        _expirationDate = medication.expirationDate;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Edit Medication')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_medication == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Edit Medication')),
        body: const Center(child: Text('Medication not found')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Medication'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _showDeleteConfirmation,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: <Widget>[
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Medication Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _brandController,
                decoration: const InputDecoration(
                  labelText: 'Brand/Manufacturer',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<MedicationType>(
                value: _selectedType,
                decoration: const InputDecoration(
                  labelText: 'Medication Type',
                  border: OutlineInputBorder(),
                ),
                items: _buildCategorizedDropdownItems(),
                onChanged: (value) {
                  setState(() {
                    _selectedType = value;
                    // Update strength unit when type changes
                    if (value != null) {
                      final defaultUnit = MedicationUtils.getDefaultStrengthUnit(value);
                      final availableUnits = MedicationUtils.getAvailableStrengthUnits(value);
                      if (!availableUnits.contains(_selectedStrengthUnit)) {
                        _selectedStrengthUnit = defaultUnit;
                      }
                    }
                  });
                },
                validator: (value) {
                  if (value == null) {
                    return 'Please select a type';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _strengthController,
                      decoration: InputDecoration(
                        labelText: _selectedType != null 
                            ? MedicationUtils.getStrengthLabel(_selectedType!) 
                            : 'Strength per Unit',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter amount';
                        }
                        if (double.tryParse(value) == null) {
                          return 'Please enter a valid number';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: DropdownButtonFormField<StrengthUnit>(
                      value: _selectedStrengthUnit,
                      decoration: const InputDecoration(
                        labelText: 'Unit',
                        border: OutlineInputBorder(),
                      ),
                      items: (_selectedType != null 
                          ? MedicationUtils.getAvailableStrengthUnits(_selectedType!)
                          : StrengthUnit.values)
                          .map((unit) => DropdownMenuItem(
                                value: unit,
                                child: Text(unit.displayName),
                              ))
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedStrengthUnit = value;
                        });
                      },
                      validator: (value) => value == null ? 'Required' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _numberOfUnitsController,
                decoration: InputDecoration(
                  labelText: _selectedType != null 
                      ? MedicationUtils.getInventoryLabel(_selectedType!) 
                      : 'Number of Units',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter number of units';
                  }
                  if (int.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _instructionsController,
                decoration: const InputDecoration(
                  labelText: 'Instructions',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _batchNumberController,
                decoration: const InputDecoration(
                  labelText: 'Batch Number',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                title: const Text('Expiration Date'),
                subtitle: Text(
                  _expirationDate != null
                      ? '${_expirationDate!.day}/${_expirationDate!.month}/${_expirationDate!.year}'
                      : 'Not set',
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.calendar_today),
                  onPressed: _selectExpirationDate,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(color: Theme.of(context).dividerColor),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Notes',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _saveMedication,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                ),
                child: const Text('Save Changes', style: TextStyle(fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _selectExpirationDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _expirationDate ?? DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );
    if (picked != null && picked != _expirationDate) {
      setState(() {
        _expirationDate = picked;
      });
    }
  }

  void _saveMedication() {
    if (_formKey.currentState!.validate()) {
      final updatedMedication = _medication!.copyWith(
        name: _nameController.text,
        brandManufacturer: _brandController.text.isEmpty ? null : _brandController.text,
        type: _selectedType,
        strengthPerUnit: double.parse(_strengthController.text),
        strengthUnit: _selectedStrengthUnit,
        stockQuantity: double.parse(_numberOfUnitsController.text),
        instructions: _instructionsController.text.isEmpty ? null : _instructionsController.text,
        lotBatchNumber: _batchNumberController.text.isEmpty ? null : _batchNumberController.text,
        expirationDate: _expirationDate,
        notes: _notesController.text.isEmpty ? null : _notesController.text,
      );

      ref.read(medicationListProvider.notifier).updateMedication(updatedMedication);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Medication updated successfully')),
      );
      
      Navigator.pop(context);
    }
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Medication'),
          content: Text('Are you sure you want to delete ${_medication!.name}?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _deleteMedication();
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  void _deleteMedication() {
    ref.read(medicationListProvider.notifier).deleteMedication(_medication!.id!);
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Medication deleted')),
    );
    
    Navigator.pop(context);
  }

  List<DropdownMenuItem<MedicationType>> _buildCategorizedDropdownItems() {
    final categories = MedicationUtils.getMedicationCategories();
    List<DropdownMenuItem<MedicationType>> items = [];
    
    for (final entry in categories.entries) {
      // Add category header (disabled item)
      items.add(DropdownMenuItem<MedicationType>(
        enabled: false,
        value: null,
        child: Padding(
          padding: const EdgeInsets.only(left: 8.0),
          child: Text(
            entry.key,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
        ),
      ));
      
      // Add category items
      for (final type in entry.value) {
        items.add(DropdownMenuItem<MedicationType>(
          value: type,
          child: Padding(
            padding: const EdgeInsets.only(left: 16.0),
            child: Text(type.displayName),
          ),
        ));
      }
    }
    
    return items;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _brandController.dispose();
    _strengthController.dispose();
    _numberOfUnitsController.dispose();
    _instructionsController.dispose();
    _notesController.dispose();
    _batchNumberController.dispose();
    super.dispose();
  }
}
