import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../data/models/medication.dart';
import '../../core/utils/medication_utils.dart';
import '../providers/medication_provider.dart';
class AddMedicationScreen extends ConsumerStatefulWidget {
  const AddMedicationScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<AddMedicationScreen> createState() => _AddMedicationScreenState();
}

class _AddMedicationScreenState extends ConsumerState<AddMedicationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _brandController = TextEditingController();
  final _strengthController = TextEditingController();
  final _numberOfUnitsController = TextEditingController();
  final _lotNumberController = TextEditingController();
  final _expirationDateController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _instructionsController = TextEditingController();
  final _notesController = TextEditingController();

  MedicationType? _selectedType;
  StrengthUnit? _selectedStrengthUnit;
  DateTime? _expirationDate;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Medication'),
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTypeDropdown(),
              const SizedBox(height: 16),
              _buildTextField(_nameController, 'Medication Name', 'Required'),
              const SizedBox(height: 16),
              _buildTextField(_brandController, 'Brand/Manufacturer'),
              const SizedBox(height: 16),
              if (_selectedType != null) ..[
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: _buildTextField(
                        _strengthController, 
                        MedicationUtils.getStrengthLabel(_selectedType!), 
                        'Required', 
                        true
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildStrengthUnitDropdown(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  _numberOfUnitsController, 
                  MedicationUtils.getInventoryLabel(_selectedType!), 
                  'Required', 
                  true
                ),
                const SizedBox(height: 16),
                if (MedicationUtils.requiresReconstitution(_selectedType!)) ..[
                  Card(
                    color: Theme.of(context).colorScheme.secondaryContainer,
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Theme.of(context).colorScheme.onSecondaryContainer,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'This medication may require reconstitution. Use the Reconstitution Calculator for dosage calculations.',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.onSecondaryContainer,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              const SizedBox(height: 16),
              _buildTextField(_lotNumberController, 'Lot No, Batch No'),
              const SizedBox(height: 16),
              _buildExpirationDateField(),
              const SizedBox(height: 16),
              _buildTextField(_descriptionController, 'Description'),
              const SizedBox(height: 16),
              _buildTextField(_instructionsController, 'Instructions'),
              const SizedBox(height: 16),
              _buildTextField(_notesController, 'Notes'),
              const SizedBox(height: 24),
              _buildSaveButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeDropdown() {
    final categories = MedicationUtils.getMedicationCategories();
    
    return DropdownButtonFormField<MedicationType>(
      decoration: const InputDecoration(
        labelText: 'Medication Type',
        border: OutlineInputBorder(),
        helperText: 'Select the form of your medication',
      ),
      value: _selectedType,
      items: _buildCategorizedDropdownItems(categories),
      onChanged: (value) {
        setState(() {
          _selectedType = value;
          // Reset strength unit when type changes
          if (value != null) {
            _selectedStrengthUnit = MedicationUtils.getDefaultStrengthUnit(value);
          }
        });
      },
      validator: (value) => value == null ? 'Please select a medication type' : null,
    );
  }

  List<DropdownMenuItem<MedicationType>> _buildCategorizedDropdownItems(
    Map<String, List<MedicationType>> categories,
  ) {
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

  Widget _buildStrengthUnitDropdown() {
    final availableUnits = _selectedType != null
        ? MedicationUtils.getAvailableStrengthUnits(_selectedType!)
        : StrengthUnit.values;
        
    return DropdownButtonFormField<StrengthUnit>(
      decoration: const InputDecoration(
        labelText: 'Unit',
        border: OutlineInputBorder(),
      ),
      value: _selectedStrengthUnit,
      items: availableUnits.map((unit) {
        return DropdownMenuItem(
          value: unit,
          child: Text(unit.displayName),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          _selectedStrengthUnit = value;
        });
      },
      validator: (value) => value == null ? 'Required' : null,
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, [String? errorText, bool isNumber = false]) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(),
      ),
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      validator: (value) {
        if ((value == null || value.isEmpty) && errorText != null) {
          return errorText;
        }
        return null;
      },
    );
  }

  Widget _buildExpirationDateField() {
    return InkWell(
      onTap: _selectExpirationDate,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: 'Expiration Date',
          border: OutlineInputBorder(),
        ),
        child: Text(
          _expirationDate != null
              ? DateFormat('MMM dd, yyyy').format(_expirationDate!)
              : 'Select date',
          style: TextStyle(
            color: _expirationDate != null
                ? Colors.black
                : Theme.of(context).hintColor,
          ),
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _saveMedication,
        child: _isLoading
            ? const CircularProgressIndicator()
            : const Text('Save Medication'),
      ),
    );
  }

  Future<void> _selectExpirationDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 1825)),
    );
    if (picked != null && picked != _expirationDate) {
      setState(() {
        _expirationDate = picked;
      });
    }
  }

  Future<void> _saveMedication() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final medication = Medication.create(
        name: _nameController.text,
        type: _selectedType!,
        brandManufacturer: _brandController.text,
        strengthPerUnit: double.parse(_strengthController.text),
        strengthUnit: _selectedStrengthUnit!,
        numberOfUnits: int.parse(_numberOfUnitsController.text),
        lotBatchNumber: _lotNumberController.text,
        expirationDate: _expirationDate,
        description: _descriptionController.text,
        instructions: _instructionsController.text,
        notes: _notesController.text,
      );

      await ref.read(medicationListProvider.notifier).addMedication(medication);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Medication added successfully')),
      );
      context.pop();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _brandController.dispose();
    _strengthController.dispose();
    _numberOfUnitsController.dispose();
    _lotNumberController.dispose();
    _expirationDateController.dispose();
    _descriptionController.dispose();
    _instructionsController.dispose();
    _notesController.dispose();
    super.dispose();
  }
}
