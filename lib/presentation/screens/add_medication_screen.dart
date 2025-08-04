import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../data/models/medication.dart';
import '../../core/utils/medication_utils.dart';
import '../providers/medication_provider.dart';
import '../widgets/embedded_reconstitution_calculator.dart';
class AddMedicationScreen extends ConsumerStatefulWidget {
  const AddMedicationScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<AddMedicationScreen> createState() => _AddMedicationScreenState();
}

class _AddMedicationScreenState extends ConsumerState<AddMedicationScreen> {
  final _formKey = GlobalKey<FormState>();
  
  void _logCurrentState() {
    debugPrint('Selected Type: $_selectedType');
    debugPrint('Selected Strength Unit: $_selectedStrengthUnit');
    debugPrint('Name: ${_nameController.text}');
  }
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
  
  // Reconstitution fields
  bool _reconstitutionEnabled = false;
  double? _reconstitutionVolume;
  double? _finalConcentration;
  String? _reconstitutionNotes;
  
  @override
  void initState() {
    super.initState();
    // Add listeners to update reconstitution calculator when strength changes
    _strengthController.addListener(() {
      if (mounted && _selectedType != null && MedicationUtils.requiresReconstitution(_selectedType!)) {
        setState(() {}); // Trigger rebuild to update calculator
      }
    });
  }

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
              if (_selectedType != null) ...[
                _buildTextField(_nameController, 'Medication Name', 'Required'),
                const SizedBox(height: 16),
                _buildTextField(_brandController, 'Brand/Manufacturer'),
                const SizedBox(height: 16),
                Row(
                  key: ValueKey('strength_row_${_selectedType?.name}'),
                  children: [
                    Expanded(
                      flex: 2,
                      child: _buildTextField(
                        _strengthController, 
                        MedicationUtils.getStrengthLabel(_selectedType!), 
                        'Required', 
                        true,
                        ValueKey('strength_field_${_selectedType?.name}')
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildStrengthUnitDropdown(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (MedicationUtils.requiresReconstitution(_selectedType!)) ...[
                  ..._buildReconstitutionSection(),
                ] else ...[
                  _buildTextField(
                    _numberOfUnitsController, 
                    MedicationUtils.getInventoryLabel(_selectedType!), 
                    'Required', 
                    true,
                    ValueKey('inventory_field_${_selectedType?.name}')
                  ),
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
            ],
          ),
        ),
      ),
    );
  }

List<Widget> _buildReconstitutionSection() {
    return [
      SwitchListTile(
        title: const Text('Enable Reconstitution Calculator'),
        subtitle: const Text('Calculate vial volume after reconstitution'),
        value: _reconstitutionEnabled,
        onChanged: (enabled) {
          setState(() {
            _reconstitutionEnabled = enabled;
            if (!enabled) {
              _reconstitutionVolume = null;
              _finalConcentration = null;
              _reconstitutionNotes = null;
            }
          });
        },
      ),
      if (!_reconstitutionEnabled) ...[
        const SizedBox(height: 16),
        _buildTextField(
          _numberOfUnitsController,
          'Vial Volume (mL, CC, IU)',
          'Required',
          true,
        ),
      ],
      if (_reconstitutionEnabled) ...[
        const SizedBox(height: 16),
        Card(
          color: Theme.of(context).colorScheme.primaryContainer,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: EmbeddedReconstitutionCalculator(
              initialStrength: double.tryParse(_strengthController.text),
              initialStrengthUnit: _selectedStrengthUnit?.displayName,
              onCalculationResult: (volume, concentration, notes) {
                setState(() {
                  _reconstitutionVolume = volume;
                  _finalConcentration = concentration;
                  _reconstitutionNotes = notes;
                  // Set the calculated volume as stock quantity
                  _numberOfUnitsController.text = volume.toStringAsFixed(2);
                });
              },
            ),
          ),
        ),
        const SizedBox(height: 16),
        if (_reconstitutionVolume != null && _finalConcentration != null) ...[
          Card(
            color: Colors.green.shade50,
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Selected Reconstitution:',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text('Volume: ${_reconstitutionVolume!.toStringAsFixed(1)} mL'),
                  Text('Concentration: ${_finalConcentration!.toStringAsFixed(1)} units/mL'),
                  if (_reconstitutionNotes != null)
                    Text('Notes: $_reconstitutionNotes'),
                ],
              ),
            ),
          ),
        ],
      ],
    ];
  }

  Widget _buildTypeDropdown() {
    _logCurrentState();
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
        debugPrint('Medication type changed to: $value');
        setState(() {
          _selectedType = value;
          // Reset strength unit when type changes
          if (value != null) {
            _selectedStrengthUnit = MedicationUtils.getDefaultStrengthUnit(value);
            debugPrint('Set default strength unit to: $_selectedStrengthUnit');
            debugPrint('Available units for this type: ${MedicationUtils.getAvailableStrengthUnits(value)}');
          } else {
            _selectedStrengthUnit = null;
          }
        });
        debugPrint('State updated - Type: $_selectedType, Unit: $_selectedStrengthUnit');
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

  Widget _buildTextField(TextEditingController controller, String label, [String? errorText, bool isNumber = false, Key? key]) {
    return TextFormField(
      key: key,
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
        onPressed: _isLoading ? null : () {
          _logCurrentState();
          _saveMedication();
        },
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
        stockQuantity: double.parse(_numberOfUnitsController.text),
        lotBatchNumber: _lotNumberController.text,
        expirationDate: _expirationDate,
        reconstitutionVolume: _reconstitutionVolume,
        finalConcentration: _finalConcentration,
        reconstitutionNotes: _reconstitutionNotes,
        description: _descriptionController.text,
        instructions: _instructionsController.text,
        notes: _notesController.text,
      );

      await ref.read(medicationListProvider.notifier).addMedication(medication);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Medication added successfully')),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
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
