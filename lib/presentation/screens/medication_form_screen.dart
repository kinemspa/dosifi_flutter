import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dosifi_flutter/data/models/medication.dart';
import 'package:dosifi_flutter/presentation/providers/medication_provider.dart';
import 'package:dosifi_flutter/config/app_router.dart';

class MedicationFormScreen extends ConsumerStatefulWidget {
  final String? medicationId; // null for add, not null for edit
  
  const MedicationFormScreen({
    super.key,
    this.medicationId,
  });

  @override
  ConsumerState<MedicationFormScreen> createState() => _MedicationFormScreenState();
}

class _MedicationFormScreenState extends ConsumerState<MedicationFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _brandController = TextEditingController();
  final _strengthController = TextEditingController();
  final _stockController = TextEditingController();
  final _volumeController = TextEditingController(); // For liquids and injectables
  final _concentrationController = TextEditingController(); // For solutions
  final _lotBatchController = TextEditingController();
  final _lowStockThresholdController = TextEditingController();
  final _storageInstructionsController = TextEditingController();
  final _storageTemperatureController = TextEditingController();
  final _reconstitutionVolumeController = TextEditingController();
  final _finalConcentrationController = TextEditingController();
  final _reconstitutionNotesController = TextEditingController();
  final _reconstitutionFluidController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _instructionsController = TextEditingController();
  final _notesController = TextEditingController();
  final _barcodeController = TextEditingController();

  MedicationType? _selectedType; // Start with null - user must select
  StrengthUnit? _selectedStrengthUnit;
  String? _selectedStockUnit;
  DateTime? _expirationDate;
  bool _requiresRefrigeration = false;
  bool _isActive = true;
  bool _isLoading = false;

  bool get isEditMode => widget.medicationId != null;

  @override
  void initState() {
    super.initState();
    if (isEditMode) {
      _loadMedicationData();
    }
  }

  void _loadMedicationData() async {
    final medication = await ref.read(medicationByIdProvider(int.parse(widget.medicationId!)).future);
    if (medication != null && mounted) {
      _populateFormWithMedication(medication);
    }
  }

  void _populateFormWithMedication(Medication medication) {
    _nameController.text = medication.name;
    _brandController.text = medication.brandManufacturer ?? '';
    _strengthController.text = medication.strengthPerUnit.toString();
    _stockController.text = medication.stockQuantity.toString();
    _lotBatchController.text = medication.lotBatchNumber ?? '';
    _lowStockThresholdController.text = medication.lowStockThreshold?.toString() ?? '';
    _storageInstructionsController.text = medication.storageInstructions ?? '';
    _storageTemperatureController.text = medication.storageTemperature ?? '';
    _reconstitutionVolumeController.text = medication.reconstitutionVolume?.toString() ?? '';
    _finalConcentrationController.text = medication.finalConcentration?.toString() ?? '';
    _reconstitutionNotesController.text = medication.reconstitutionNotes ?? '';
    _reconstitutionFluidController.text = medication.reconstitutionFluid ?? '';
    _descriptionController.text = medication.description ?? '';
    _instructionsController.text = medication.instructions ?? '';
    _notesController.text = medication.notes ?? '';
    _barcodeController.text = medication.barcode ?? '';

    setState(() {
      _selectedType = medication.type;
      _selectedStrengthUnit = medication.strengthUnit;
      _selectedStockUnit = _getStockUnit(medication.type);
      _expirationDate = medication.expirationDate;
      _requiresRefrigeration = medication.requiresRefrigeration;
      _isActive = medication.isActive;
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _brandController.dispose();
    _strengthController.dispose();
    _stockController.dispose();
    _volumeController.dispose();
    _concentrationController.dispose();
    _lotBatchController.dispose();
    _lowStockThresholdController.dispose();
    _storageInstructionsController.dispose();
    _storageTemperatureController.dispose();
    _reconstitutionVolumeController.dispose();
    _finalConcentrationController.dispose();
    _reconstitutionNotesController.dispose();
    _reconstitutionFluidController.dispose();
    _descriptionController.dispose();
    _instructionsController.dispose();
    _notesController.dispose();
    _barcodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(isEditMode ? 'Edit Medication' : 'Add Medication'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.navigateBackSmart(),
        ),
        actions: [
          if (isEditMode)
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
                
                // Medication Type - First and Required
                _buildMedicationTypeSection(),
                
                // Only show rest of form if type is selected
                if (_selectedType != null) ...[
                  const SizedBox(height: 32),
                  _buildBasicInformationSection(),
                  const SizedBox(height: 32),
                  _buildStrengthSection(),
                  const SizedBox(height: 32),
                  _buildStockInformationSection(),
                  const SizedBox(height: 32),
                  _buildCustomFieldsForType(),
                  if (_selectedType != null) ...[
                    const SizedBox(height: 32),
                    _buildStorageSection(),
                    const SizedBox(height: 32),
                    _buildAdditionalInfoSection(),
                  ],
                  const SizedBox(height: 40),
                  _buildSaveButton(),
                ],
              ],
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

  Widget _buildBasicInfoSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('Basic Information'),
            
            // Name (Required)
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Medication Name *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.medication),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a medication name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Brand/Manufacturer
            TextFormField(
              controller: _brandController,
              decoration: const InputDecoration(
                labelText: 'Brand/Manufacturer',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.business),
              ),
            ),
            const SizedBox(height: 16),

            // Type (Required)
            DropdownButtonFormField<MedicationType>(
              value: _selectedType,
              decoration: const InputDecoration(
                labelText: 'Medication Type *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.category),
              ),
              items: MedicationType.values.map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Row(
                    children: [
                      Icon(
                        _getMedicationTypeIcon(type),
                        size: 20,
                        color: _getMedicationTypeColor(type),
                      ),
                      const SizedBox(width: 8),
                      Text(type.displayName),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedType = value!;
                });
              },
            ),
            const SizedBox(height: 16),

            // Strength and Unit
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: _strengthController,
                    decoration: const InputDecoration(
                      labelText: 'Strength *',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
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
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<StrengthUnit>(
                    value: _selectedStrengthUnit,
                    decoration: const InputDecoration(
                      labelText: 'Unit *',
                      border: OutlineInputBorder(),
                    ),
                    items: StrengthUnit.values.map((unit) {
                      return DropdownMenuItem(
                        value: unit,
                        child: Text(unit.displayName),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedStrengthUnit = value!;
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Active Status
            SwitchListTile(
              title: const Text('Active'),
              subtitle: const Text('Medication is currently being used'),
              value: _isActive,
              onChanged: (value) {
                setState(() {
                  _isActive = value;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStockInfoSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('Stock Information'),
            
            // Current Stock
            TextFormField(
              controller: _stockController,
              decoration: const InputDecoration(
                labelText: 'Current Stock *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.inventory),
                helperText: 'Number of units/tablets or volume in mL',
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter current stock';
                }
                if (double.tryParse(value) == null) {
                  return 'Please enter a valid number';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Low Stock Threshold
            TextFormField(
              controller: _lowStockThresholdController,
              decoration: const InputDecoration(
                labelText: 'Low Stock Threshold',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.warning),
                helperText: 'Alert when stock falls below this amount',
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value != null && value.isNotEmpty) {
                  if (double.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Lot/Batch Number
            TextFormField(
              controller: _lotBatchController,
              decoration: const InputDecoration(
                labelText: 'Lot/Batch Number',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.qr_code),
              ),
            ),
            const SizedBox(height: 16),

            // Expiration Date
            InkWell(
              onTap: _selectExpirationDate,
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Expiration Date',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.calendar_today),
                ),
                child: Text(
                  _expirationDate != null
                      ? _formatDate(_expirationDate!)
                      : 'Select expiration date',
                  style: _expirationDate != null
                      ? null
                      : TextStyle(color: Colors.grey[600]),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStorageSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('Storage Information'),
            
            // Storage Instructions
            TextFormField(
              controller: _storageInstructionsController,
              decoration: const InputDecoration(
                labelText: 'Storage Instructions',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.info),
                helperText: 'e.g., Store in cool, dry place',
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),

            // Refrigeration Required
            SwitchListTile(
              title: const Text('Requires Refrigeration'),
              subtitle: const Text('Medication must be stored in refrigerator'),
              value: _requiresRefrigeration,
              onChanged: (value) {
                setState(() {
                  _requiresRefrigeration = value;
                });
              },
            ),
            const SizedBox(height: 16),

            // Storage Temperature
            TextFormField(
              controller: _storageTemperatureController,
              decoration: const InputDecoration(
                labelText: 'Storage Temperature',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.thermostat),
                helperText: 'e.g., 2-8°C, Room temperature',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReconstitutionSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('Reconstitution Information'),
            
            // Reconstitution Volume
            TextFormField(
              controller: _reconstitutionVolumeController,
              decoration: const InputDecoration(
                labelText: 'Reconstitution Volume (mL)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.water_drop),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value != null && value.isNotEmpty) {
                  if (double.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Final Concentration
            TextFormField(
              controller: _finalConcentrationController,
              decoration: const InputDecoration(
                labelText: 'Final Concentration',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.science),
                helperText: 'Concentration after reconstitution',
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value != null && value.isNotEmpty) {
                  if (double.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Reconstitution Fluid
            TextFormField(
              controller: _reconstitutionFluidController,
              decoration: const InputDecoration(
                labelText: 'Reconstitution Fluid',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.local_drink),
                helperText: 'e.g., Sterile Water, Normal Saline',
              ),
            ),
            const SizedBox(height: 16),

            // Reconstitution Notes
            TextFormField(
              controller: _reconstitutionNotesController,
              decoration: const InputDecoration(
                labelText: 'Reconstitution Notes',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.note),
              ),
              maxLines: 3,
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
            
            // Description
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.description),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),

            // Instructions
            TextFormField(
              controller: _instructionsController,
              decoration: const InputDecoration(
                labelText: 'Instructions',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.list),
                helperText: 'Dosage instructions or usage guidelines',
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),

            // Notes
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Notes',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.note),
                helperText: 'Additional notes or comments',
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),

            // Barcode
            TextFormField(
              controller: _barcodeController,
              decoration: const InputDecoration(
                labelText: 'Barcode',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.qr_code_2),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _selectExpirationDate() async {
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: _expirationDate ?? DateTime.now().add(const Duration(days: 365)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 3650)), // 10 years
    );
    
    if (selectedDate != null) {
      setState(() {
        _expirationDate = selectedDate;
      });
    }
  }

  void _saveMedication() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      if (isEditMode) {
        await _updateMedication();
      } else {
        await _createMedication();
      }

      if (mounted) {
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isEditMode 
              ? 'Medication updated successfully' 
              : 'Medication added successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error ${isEditMode ? 'updating' : 'adding'} medication: $e'),
            backgroundColor: Colors.red,
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

  Future<void> _createMedication() async {
    final medication = Medication.create(
      name: _nameController.text.trim(),
      type: _selectedType!,
      brandManufacturer: _brandController.text.trim().isNotEmpty 
          ? _brandController.text.trim() 
          : null,
      strengthPerUnit: double.parse(_strengthController.text),
      strengthUnit: _selectedStrengthUnit!,
      stockQuantity: double.parse(_stockController.text),
      lotBatchNumber: _lotBatchController.text.trim().isNotEmpty 
          ? _lotBatchController.text.trim() 
          : null,
      expirationDate: _expirationDate,
      storageInstructions: _storageInstructionsController.text.trim().isNotEmpty 
          ? _storageInstructionsController.text.trim() 
          : null,
      requiresRefrigeration: _requiresRefrigeration,
      reconstitutionVolume: _reconstitutionVolumeController.text.trim().isNotEmpty 
          ? double.parse(_reconstitutionVolumeController.text) 
          : null,
      finalConcentration: _finalConcentrationController.text.trim().isNotEmpty 
          ? double.parse(_finalConcentrationController.text) 
          : null,
      reconstitutionNotes: _reconstitutionNotesController.text.trim().isNotEmpty 
          ? _reconstitutionNotesController.text.trim() 
          : null,
      reconstitutionFluid: _reconstitutionFluidController.text.trim().isNotEmpty 
          ? _reconstitutionFluidController.text.trim() 
          : null,
      description: _descriptionController.text.trim().isNotEmpty 
          ? _descriptionController.text.trim() 
          : null,
      instructions: _instructionsController.text.trim().isNotEmpty 
          ? _instructionsController.text.trim() 
          : null,
      notes: _notesController.text.trim().isNotEmpty 
          ? _notesController.text.trim() 
          : null,
      barcode: _barcodeController.text.trim().isNotEmpty 
          ? _barcodeController.text.trim() 
          : null,
    );

    await ref.read(medicationListProvider.notifier).addMedication(medication);
  }

  Future<void> _updateMedication() async {
    final existingMedication = await ref.read(
      medicationByIdProvider(int.parse(widget.medicationId!)).future,
    );
    
    if (existingMedication == null) {
      throw Exception('Medication not found');
    }

    final updatedMedication = existingMedication.copyWith(
      name: _nameController.text.trim(),
      type: _selectedType!,
      brandManufacturer: _brandController.text.trim().isNotEmpty 
          ? _brandController.text.trim() 
          : null,
      strengthPerUnit: double.parse(_strengthController.text),
      strengthUnit: _selectedStrengthUnit!,
      stockQuantity: double.parse(_stockController.text),
      lotBatchNumber: _lotBatchController.text.trim().isNotEmpty 
          ? _lotBatchController.text.trim() 
          : null,
      expirationDate: _expirationDate,
      reconstitutionVolume: _reconstitutionVolumeController.text.trim().isNotEmpty 
          ? double.parse(_reconstitutionVolumeController.text) 
          : null,
      finalConcentration: _finalConcentrationController.text.trim().isNotEmpty 
          ? double.parse(_finalConcentrationController.text) 
          : null,
      reconstitutionNotes: _reconstitutionNotesController.text.trim().isNotEmpty 
          ? _reconstitutionNotesController.text.trim() 
          : null,
      description: _descriptionController.text.trim().isNotEmpty 
          ? _descriptionController.text.trim() 
          : null,
      instructions: _instructionsController.text.trim().isNotEmpty 
          ? _instructionsController.text.trim() 
          : null,
      notes: _notesController.text.trim().isNotEmpty 
          ? _notesController.text.trim() 
          : null,
      barcode: _barcodeController.text.trim().isNotEmpty 
          ? _barcodeController.text.trim() 
          : null,
      isActive: _isActive,
    );

    await ref.read(medicationListProvider.notifier).updateMedication(updatedMedication);
  }

  void _showDeleteDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Medication'),
        content: const Text('Are you sure you want to delete this medication? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              try {
                await ref.read(medicationListProvider.notifier)
                    .deleteMedication(int.parse(widget.medicationId!));
                if (mounted) {
                  context.pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Medication deleted successfully'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error deleting medication: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
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
    return '${date.day}/${date.month}/${date.year}';
  }

  // New methods for the redesigned form
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
          Icon(Icons.info_outline, color: Colors.blue[700]),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _selectedType == null 
                ? 'Step 1: Select medication type to continue'
                : 'Step 2: Fill in the medication details',
              style: TextStyle(
                color: Colors.blue[700],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMedicationTypeSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.category, color: Colors.blue[700]),
                ),
                const SizedBox(width: 12),
                Text(
                  'Medication Type',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Text(' *', style: TextStyle(color: Colors.red)),
              ],
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<MedicationType>(
              value: _selectedType,
              decoration: InputDecoration(
                hintText: 'Select medication type...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[50],
                prefixIcon: const Icon(Icons.medical_services),
              ),
              items: MedicationType.values.map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Row(
                    children: [
                      Icon(
                        _getMedicationTypeIcon(type),
                        size: 20,
                        color: _getMedicationTypeColor(type),
                      ),
                      const SizedBox(width: 12),
                      Text(type.displayName),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedType = value;
                  _selectedStrengthUnit = _getDefaultStrengthUnit(value!);
                  _selectedStockUnit = _getStockUnit(value);
                  // Clear form when type changes (except in edit mode)
                  if (!isEditMode) {
                    _nameController.clear();
                    _brandController.clear();
                    _strengthController.clear();
                    _stockController.clear();
                    _volumeController.clear();
                    _concentrationController.clear();
                  }
                });
              },
              validator: (value) {
                if (value == null) {
                  return 'Please select medication type';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBasicInformationSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.info, color: Colors.green[700]),
                ),
                const SizedBox(width: 12),
                Text(
                  'Basic Information',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Medication Name *',
                hintText: 'Enter the medication name',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[50],
                prefixIcon: const Icon(Icons.medication),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter medication name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _brandController,
              decoration: InputDecoration(
                labelText: 'Brand / Manufacturer',
                hintText: 'Optional brand or manufacturer',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[50],
                prefixIcon: const Icon(Icons.business),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStrengthSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.scale, color: Colors.orange[700]),
                ),
                const SizedBox(width: 12),
                Text(
                  'Strength Information',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: _strengthController,
                    decoration: InputDecoration(
                      labelText: 'Strength Per Unit *',
                      hintText: '0.0',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                      prefixIcon: const Icon(Icons.straighten),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Enter strength';
                      }
                      if (double.tryParse(value) == null) {
                        return 'Enter valid number';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<StrengthUnit>(
                    value: _selectedStrengthUnit,
                    decoration: InputDecoration(
                      labelText: 'Unit *',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                    ),
                    items: _getAvailableStrengthUnits().map((unit) {
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
                    validator: (value) {
                      if (value == null) {
                        return 'Select unit';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStockInformationSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.purple[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.inventory, color: Colors.purple[700]),
                ),
                const SizedBox(width: 12),
                Text(
                  'Stock Information',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: _stockController,
                    decoration: InputDecoration(
                      labelText: '${_getStockLabel()} *',
                      hintText: _getStockHint(),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                      prefixIcon: const Icon(Icons.inventory_2),
                    ),
                    keyboardType: _isStockInteger() 
                      ? TextInputType.number 
                      : const TextInputType.numberWithOptions(decimal: true),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Enter quantity';
                      }
                      if (_isStockInteger()) {
                        if (int.tryParse(value) == null) {
                          return 'Enter whole number';
                        }
                      } else {
                        if (double.tryParse(value) == null) {
                          return 'Enter valid number';
                        }
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.grey[100],
                    ),
                    child: Text(
                      _selectedStockUnit ?? '',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.help_outline, color: Colors.blue[700], size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _getStockHelperText(),
                      style: TextStyle(
                        color: Colors.blue[700],
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomFieldsForType() {
    if (_selectedType == null) return const SizedBox();

    switch (_selectedType!) {
      case MedicationType.liquid:
      case MedicationType.preFilledSyringe:
      case MedicationType.readyMadeVial:
      case MedicationType.lyophilizedVial:
        return _buildInjectableFields();
      case MedicationType.drops:
        return _buildDropsFields();
      case MedicationType.cream:
      case MedicationType.ointment:
        return _buildTopicalFields();
      default:
        return const SizedBox();
    }
  }

  Widget _buildInjectableFields() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.cyan[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.vaccines, color: Colors.cyan[700]),
                ),
                const SizedBox(width: 12),
                Text(
                  'Injectable Details',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _volumeController,
              decoration: InputDecoration(
                labelText: 'Volume per unit (mL)',
                hintText: 'e.g., 1.0, 2.5, 10.0',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[50],
                prefixIcon: const Icon(Icons.water_drop),
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
            if (_selectedType == MedicationType.lyophilizedVial) ...[
              const SizedBox(height: 16),
              TextFormField(
                controller: _concentrationController,
                decoration: InputDecoration(
                  labelText: 'Concentration after reconstitution',
                  hintText: 'e.g., 50 mg/mL',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                  prefixIcon: const Icon(Icons.science),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDropsFields() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.lightBlue[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.water_drop, color: Colors.lightBlue[700]),
                ),
                const SizedBox(width: 12),
                Text(
                  'Drops Information',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _volumeController,
              decoration: InputDecoration(
                labelText: 'Bottle size (mL)',
                hintText: 'e.g., 5, 10, 15',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[50],
                prefixIcon: const Icon(Icons.local_drink),
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopicalFields() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.healing, color: Colors.orange[700]),
                ),
                const SizedBox(width: 12),
                Text(
                  'Topical Information',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _volumeController,
                    decoration: InputDecoration(
                      labelText: 'Tube/Container size',
                      hintText: '30',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                      prefixIcon: const Icon(Icons.straighten),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.grey[100],
                  ),
                  child: const Text('grams'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _saveMedication,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue[600],
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 2,
        ),
        child: _isLoading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(isEditMode ? Icons.update : Icons.add),
                const SizedBox(width: 8),
                Text(
                  isEditMode ? 'Update Medication' : 'Add Medication',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
      ),
    );
  }

  // Helper methods for type-specific logic
  StrengthUnit _getDefaultStrengthUnit(MedicationType type) {
    switch (type) {
      case MedicationType.tablet:
      case MedicationType.capsule:
        return StrengthUnit.mg;
      case MedicationType.liquid:
      case MedicationType.drops:
      case MedicationType.preFilledSyringe:
      case MedicationType.readyMadeVial:
      case MedicationType.lyophilizedVial:
        return StrengthUnit.mg; // Will use concentration per volume
      case MedicationType.cream:
      case MedicationType.ointment:
        return StrengthUnit.percent;
      case MedicationType.inhaler:
        return StrengthUnit.mcg;
      case MedicationType.patch:
        return StrengthUnit.mg;
      default:
        return StrengthUnit.mg;
    }
  }

  List<StrengthUnit> _getAvailableStrengthUnits() {
    if (_selectedType == null) return StrengthUnit.values;
    
    switch (_selectedType!) {
      case MedicationType.tablet:
      case MedicationType.capsule:
        return [StrengthUnit.mg, StrengthUnit.mcg, StrengthUnit.g];
      case MedicationType.liquid:
      case MedicationType.drops:
      case MedicationType.preFilledSyringe:
      case MedicationType.readyMadeVial:
      case MedicationType.lyophilizedVial:
        return [StrengthUnit.mg, StrengthUnit.mcg, StrengthUnit.percent, StrengthUnit.iu];
      case MedicationType.cream:
      case MedicationType.ointment:
        return [StrengthUnit.percent, StrengthUnit.mg];
      case MedicationType.inhaler:
        return [StrengthUnit.mcg, StrengthUnit.mg];
      case MedicationType.patch:
        return [StrengthUnit.mg, StrengthUnit.mcg];
      default:
        return StrengthUnit.values;
    }
  }

  String _getStockUnit(MedicationType type) {
    switch (type) {
      case MedicationType.tablet:
        return 'tablets';
      case MedicationType.capsule:
        return 'capsules';
      case MedicationType.liquid:
      case MedicationType.drops:
        return 'mL';
      case MedicationType.preFilledSyringe:
      case MedicationType.readyMadeVial:
      case MedicationType.lyophilizedVial:
        return 'vials';
      case MedicationType.cream:
      case MedicationType.ointment:
        return 'grams';
      case MedicationType.inhaler:
        return 'devices';
      case MedicationType.patch:
        return 'patches';
      case MedicationType.suppository:
        return 'pieces';
      default:
        return 'units';
    }
  }

  String _getStockLabel() {
    if (_selectedType == null) return 'Stock Quantity';
    
    switch (_selectedType!) {
      case MedicationType.tablet:
        return 'Number of Tablets';
      case MedicationType.capsule:
        return 'Number of Capsules';
      case MedicationType.liquid:
      case MedicationType.drops:
        return 'Volume in Stock';
      case MedicationType.preFilledSyringe:
      case MedicationType.readyMadeVial:
      case MedicationType.lyophilizedVial:
        return 'Number of Vials';
      case MedicationType.cream:
      case MedicationType.ointment:
        return 'Weight in Stock';
      case MedicationType.inhaler:
        return 'Number of Devices';
      case MedicationType.patch:
        return 'Number of Patches';
      default:
        return 'Stock Quantity';
    }
  }

  String _getStockHint() {
    if (_selectedType == null) return '';
    
    switch (_selectedType!) {
      case MedicationType.tablet:
      case MedicationType.capsule:
        return 'e.g., 30, 60, 100';
      case MedicationType.liquid:
      case MedicationType.drops:
        return 'e.g., 100.0, 250.0';
      case MedicationType.preFilledSyringe:
      case MedicationType.readyMadeVial:
      case MedicationType.lyophilizedVial:
        return 'e.g., 1, 5, 10';
      case MedicationType.cream:
      case MedicationType.ointment:
        return 'e.g., 30.0, 50.0';
      default:
        return '';
    }
  }

  String _getStockHelperText() {
    if (_selectedType == null) return '';
    
    switch (_selectedType!) {
      case MedicationType.tablet:
      case MedicationType.capsule:
        return 'Enter the total number of individual ${_selectedType!.displayName.toLowerCase()}s you have';
      case MedicationType.liquid:
      case MedicationType.drops:
        return 'Enter the total volume in milliliters (mL)';
      case MedicationType.preFilledSyringe:
      case MedicationType.readyMadeVial:
      case MedicationType.lyophilizedVial:
        return 'Enter the number of vials/syringes, not the total volume';
      case MedicationType.cream:
      case MedicationType.ointment:
        return 'Enter the total weight in grams';
      case MedicationType.inhaler:
        return 'Enter the number of inhaler devices';
      case MedicationType.patch:
        return 'Enter the number of individual patches';
      default:
        return 'Enter the quantity in stock';
    }
  }

  bool _isStockInteger() {
    if (_selectedType == null) return false;
    
    switch (_selectedType!) {
      case MedicationType.tablet:
      case MedicationType.capsule:
      case MedicationType.preFilledSyringe:
      case MedicationType.readyMadeVial:
      case MedicationType.lyophilizedVial:
      case MedicationType.inhaler:
      case MedicationType.patch:
      case MedicationType.suppository:
        return true;
      default:
        return false;
    }
  }
}
