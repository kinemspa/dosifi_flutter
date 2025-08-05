import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../data/models/medication.dart';
import '../../core/utils/medication_utils.dart';
import '../providers/medication_provider.dart';
import '../widgets/embedded_reconstitution_calculator.dart';

class AddMedicationScreenComprehensive extends ConsumerStatefulWidget {
  const AddMedicationScreenComprehensive({Key? key}) : super(key: key);

  @override
  ConsumerState<AddMedicationScreenComprehensive> createState() => _AddMedicationScreenComprehensiveState();
}

class _AddMedicationScreenComprehensiveState extends ConsumerState<AddMedicationScreenComprehensive> {
  final _formKey = GlobalKey<FormState>();
  
  // Basic controllers
  final _nameController = TextEditingController();
  final _brandController = TextEditingController();
  final _strengthController = TextEditingController();
  final _stockQuantityController = TextEditingController();
  final _lotNumberController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _storageInstructionsController = TextEditingController();
  final _notesController = TextEditingController();

  // State variables
  MedicationType? _selectedType;
  StrengthUnit? _selectedStrengthUnit;
  StrengthUnit? _selectedStockUnit;
  DateTime? _expirationDate;
  bool _isLoading = false;
  
  // Alert and notification settings
  bool _alertOnLowStock = false;
  String? _selectedNotificationSet;
  
  // Storage settings
  bool _requiresRefrigeration = false;
  
  // Reconstitution fields (for lyophilized vials)
  bool _reconstitutionEnabled = false;
  double? _reconstitutionVolume;
  double? _finalConcentration;
  String? _reconstitutionNotes;
  String? _reconstitutionFluid;

  @override
  void initState() {
    super.initState();
    
    // Add listeners for dynamic summary updates
    _nameController.addListener(() => setState(() {}));
    _brandController.addListener(() => setState(() {}));
    _strengthController.addListener(() => setState(() {}));
    _stockQuantityController.addListener(() => setState(() {}));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Medication'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Fixed Dynamic Summary at the top
          if (_selectedType != null)
            Container(
              margin: const EdgeInsets.all(16.0),
              child: _buildDynamicSummary(),
            ),
          
          // Scrollable form content
          Expanded(
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    // Medication Type Selection
                    _buildTypeDropdown(),
                    const SizedBox(height: 24),
                    
                    if (_selectedType != null) ...[
                      // Medication Details Section
                      _buildSectionHeader('Details'),
                      const SizedBox(height: 12),
                      _buildTextField(_nameController, 'Name', errorText: 'Required', isRequired: true),
                      const SizedBox(height: 16),
                      _buildTextField(_brandController, 'Brand / Manufacturer'),
                      const SizedBox(height: 24),
                      
                      // Medication Strength Information Section
                      _buildSectionHeader('Strength Information'),
                      const SizedBox(height: 12),
                      _buildStrengthRow(),
                      const SizedBox(height: 24),
                      
                      // Medication Inventory Information Section
                      _buildSectionHeader('Inventory Information'),
                      const SizedBox(height: 12),
                      ..._buildInventorySection(),
                      const SizedBox(height: 24),
                      
                      // Other Section
                      _buildSectionHeader('Other'),
                      const SizedBox(height: 12),
                      _buildTextField(_descriptionController, 'Description'),
                      const SizedBox(height: 16),
                      _buildTextField(_storageInstructionsController, 'Storage Instructions'),
                      const SizedBox(height: 16),
                      _buildRequiresRefrigerationToggle(),
                      const SizedBox(height: 16),
                      _buildTextField(_notesController, 'Notes'),
                      const SizedBox(height: 32),
                      
                      _buildSaveButton(),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.bold,
        color: Theme.of(context).primaryColor,
      ),
    );
  }

  Widget _buildTypeDropdown() {
    final categories = MedicationUtils.getMedicationCategories();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Medication Type',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<MedicationType>(
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
              if (value != null) {
                _selectedStrengthUnit = MedicationUtils.getDefaultStrengthUnit(value);
                // Set default stock unit based on type
                _selectedStockUnit = _getDefaultStockUnit(value);
              } else {
                _selectedStrengthUnit = null;
                _selectedStockUnit = null;
              }
            });
          },
          validator: (value) => value == null ? 'Please select a medication type' : null,
        ),
      ],
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

  Widget _buildStrengthRow() {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: _buildTextField(
            _strengthController,
            'Strength per unit',
            errorText: 'Required',
            isNumber: true,
            isRequired: true,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStrengthUnitDropdown(),
        ),
        const SizedBox(width: 8),
        IconButton(
          icon: const Icon(Icons.info_outline),
          onPressed: () => _showInfoDialog('Strength Information', _getStrengthInfo()),
          tooltip: 'Strength Info',
        ),
      ],
    );
  }

  Widget _buildStrengthUnitDropdown() {
    final availableUnits = MedicationUtils.getAvailableStrengthUnits(_selectedType!);
        
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

  List<Widget> _buildInventorySection() {
    List<Widget> widgets = [];
    
    // Check if medication type requires reconstitution
    if (MedicationUtils.requiresReconstitution(_selectedType!)) {
      widgets.addAll(_buildReconstitutionSection());
    } else {
      // Regular stock quantity field
      widgets.add(_buildStockQuantityRow());
      widgets.add(const SizedBox(height: 16));
    }
    
    // Common inventory fields
    widgets.addAll([
      _buildTextField(_lotNumberController, 'Batch No'),
      const SizedBox(height: 16),
      _buildExpirationDateField(),
      const SizedBox(height: 16),
      _buildAlertOnLowStockToggle(),
      if (_alertOnLowStock) ...[
        const SizedBox(height: 16),
        _buildNotificationSetDropdown(),
      ],
    ]);
    
    return widgets;
  }

  Widget _buildStockQuantityRow() {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: _buildTextField(
            _stockQuantityController,
            'Quantity',
            errorText: 'Required',
            isNumber: true,
            isRequired: true,
          ),
        ),
        if (_selectedStockUnit != null) ...[
          const SizedBox(width: 16),
          Expanded(
            child: _buildStockUnitDropdown(),
          ),
        ],
        const SizedBox(width: 8),
        IconButton(
          icon: const Icon(Icons.info_outline),
          onPressed: () => _showInfoDialog('Stock Information', _getStockInfo()),
          tooltip: 'Stock Info',
        ),
      ],
    );
  }

  Widget _buildStockUnitDropdown() {
    final availableUnits = _getAvailableStockUnits(_selectedType!);
        
    return DropdownButtonFormField<StrengthUnit>(
      decoration: const InputDecoration(
        labelText: 'Unit',
        border: OutlineInputBorder(),
      ),
      value: _selectedStockUnit,
      items: availableUnits.map((unit) {
        return DropdownMenuItem(
          value: unit,
          child: Text(unit.displayName),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          _selectedStockUnit = value;
        });
      },
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
      const SizedBox(height: 16),
      
      if (!_reconstitutionEnabled) ...[
        _buildStockQuantityRow(),
        const SizedBox(height: 16),
      ],
      
      if (_reconstitutionEnabled) ...[
        Card(
          color: Theme.of(context).colorScheme.primaryContainer,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Reconstitution Calculator',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                EmbeddedReconstitutionCalculator(
                  initialStrength: double.tryParse(_strengthController.text),
                  initialStrengthUnit: _selectedStrengthUnit?.displayName,
                  onCalculationResult: (volume, concentration, notes) {
                    setState(() {
                      _reconstitutionVolume = volume;
                      _finalConcentration = concentration;
                      _reconstitutionNotes = notes;
                      _stockQuantityController.text = volume.toStringAsFixed(2);
                    });
                  },
                ),
              ],
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
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        _reconstitutionEnabled = true;
                      });
                    },
                    icon: const Icon(Icons.edit),
                    label: const Text('Edit Reconstitution'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade100,
                      foregroundColor: Colors.blue.shade800,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ],
    ];
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label, {
    String? errorText,
    bool isNumber = false,
    bool isRequired = false,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        suffixIcon: isRequired 
          ? const Icon(Icons.star, color: Colors.red, size: 16)
          : null,
      ),
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      validator: (value) {
        if (isRequired && (value == null || value.isEmpty)) {
          return errorText ?? 'This field is required';
        }
        return null;
      },
    );
  }

  Widget _buildExpirationDateField() {
    return Row(
      children: [
        Expanded(
          child: InkWell(
            onTap: _selectExpirationDate,
            child: InputDecorator(
              decoration: const InputDecoration(
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
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          icon: const Icon(Icons.info_outline),
          onPressed: () => _showInfoDialog('Expiration Date', 'Select the expiration date of the medication as printed on the package.'),
          tooltip: 'Expiration Date Info',
        ),
      ],
    );
  }

  Widget _buildAlertOnLowStockToggle() {
    return SwitchListTile(
      title: const Text('Alert on Low Stock'),
      subtitle: const Text('Receive notifications when stock is running low'),
      value: _alertOnLowStock,
      onChanged: (value) {
        setState(() {
          _alertOnLowStock = value;
        });
      },
    );
  }

  Widget _buildRequiresRefrigerationToggle() {
    return Column(
      children: [
        SwitchListTile(
          title: const Text('Requires Refrigeration'),
          subtitle: const Text('This medication needs to be stored in refrigerator'),
          value: _requiresRefrigeration,
          onChanged: (value) {
            setState(() {
              _requiresRefrigeration = value;
            });
          },
        ),
        if (_requiresRefrigeration) ...[
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.info, color: Colors.blue.shade600, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Store at 2-8°C (36-46°F). Do not freeze. Keep away from light.',
                    style: TextStyle(
                      color: Colors.blue.shade700,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildNotificationSetDropdown() {
    return Row(
      children: [
        Expanded(
          child: DropdownButtonFormField<String>(
            decoration: const InputDecoration(
              labelText: 'Notification Set',
              border: OutlineInputBorder(),
              helperText: 'Select or create a notification schedule',
            ),
            value: _selectedNotificationSet,
            items: [
              const DropdownMenuItem(
                value: 'default',
                child: Text('Default Notifications'),
              ),
              const DropdownMenuItem(
                value: 'custom',
                child: Text('Custom Schedule'),
              ),
              const DropdownMenuItem(
                value: 'none',
                child: Text('No Notifications'),
              ),
            ],
            onChanged: (value) {
              setState(() {
                _selectedNotificationSet = value;
              });
            },
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          icon: const Icon(Icons.add),
          onPressed: () {
            // TODO: Navigate to create notification set screen
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Create notification set functionality coming soon')),
            );
          },
          tooltip: 'Create New Notification Set',
        ),
      ],
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _saveMedication,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        child: _isLoading
            ? const CircularProgressIndicator()
            : const Text('Save Medication'),
      ),
    );
  }

  Future<void> _selectExpirationDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 365)),
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

    // Show confirmation dialog
    final confirmed = await _showSaveConfirmationDialog();
    if (!confirmed) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final medication = Medication.create(
        name: _nameController.text,
        type: _selectedType!,
        brandManufacturer: _brandController.text.isEmpty ? null : _brandController.text,
        strengthPerUnit: double.parse(_strengthController.text),
        strengthUnit: _selectedStrengthUnit!,
        stockQuantity: double.parse(_stockQuantityController.text),
        stockUnit: _selectedStockUnit,
        lotBatchNumber: _lotNumberController.text.isEmpty ? null : _lotNumberController.text,
        expirationDate: _expirationDate,
        alertOnLowStock: _alertOnLowStock,
        notificationSet: _selectedNotificationSet,
        storageInstructions: _storageInstructionsController.text.isEmpty ? null : _storageInstructionsController.text,
        requiresRefrigeration: _requiresRefrigeration,
        reconstitutionVolume: _reconstitutionVolume,
        finalConcentration: _finalConcentration,
        reconstitutionNotes: _reconstitutionNotes,
        reconstitutionFluid: _reconstitutionFluid,
        description: _descriptionController.text.isEmpty ? null : _descriptionController.text,
        notes: _notesController.text.isEmpty ? null : _notesController.text,
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

  void _showInfoDialog(String title, String content) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(content),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  String _getStrengthInfo() {
    switch (_selectedType!) {
      case MedicationType.tablet:
        return 'Enter the amount of active ingredient per tablet as shown on the medication label.';
      case MedicationType.capsule:
        return 'Enter the amount of active ingredient per capsule as shown on the medication label.';
      case MedicationType.preFilledSyringe:
        return 'Enter the concentration or total amount of active ingredient per pre-filled syringe.';
      case MedicationType.readyMadeVial:
      case MedicationType.lyophilizedVial:
        return 'Enter the total amount of active ingredient per vial before any dilution.';
      default:
        return 'Enter the strength or concentration of the active ingredient as shown on the medication label.';
    }
  }

  String _getStockInfo() {
    switch (_selectedType!) {
      case MedicationType.tablet:
        return 'Count the total number of tablets you have in stock.';
      case MedicationType.capsule:
        return 'Count the total number of capsules you have in stock.';
      case MedicationType.preFilledSyringe:
        return 'Count the total number of pre-filled syringes you have in stock. Each syringe is typically single-use.';
      case MedicationType.readyMadeVial:
      case MedicationType.lyophilizedVial:
        return 'Enter the volume of liquid per vial. For lyophilized vials, this will be calculated after reconstitution.';
      default:
        return 'Enter the quantity of medication units you have in stock.';
    }
  }

  StrengthUnit _getDefaultStockUnit(MedicationType type) {
    switch (type) {
      case MedicationType.readyMadeVial:
      case MedicationType.lyophilizedVial:
        return StrengthUnit.ml;
      case MedicationType.preFilledSyringe:
        return StrengthUnit.units;
      default:
        return StrengthUnit.units;
    }
  }

  List<StrengthUnit> _getAvailableStockUnits(MedicationType type) {
    switch (type) {
      case MedicationType.readyMadeVial:
      case MedicationType.lyophilizedVial:
        return [StrengthUnit.ml, StrengthUnit.iu, StrengthUnit.units];
      case MedicationType.preFilledSyringe:
        return [StrengthUnit.units, StrengthUnit.ml, StrengthUnit.iu];
      default:
        return [StrengthUnit.units];
    }
  }

  Widget _buildDynamicSummary() {
    List<String> summaryParts = [];
    
    // Add medication type
    if (_selectedType != null) {
      summaryParts.add(_selectedType!.displayName);
    }
    
    // Add brand name if available
    if (_brandController.text.isNotEmpty) {
      summaryParts.add(_brandController.text);
    }
    
    // Add medication name if available
    if (_nameController.text.isNotEmpty) {
      summaryParts.add(_nameController.text);
    }
    
    // Add strength information
    if (_strengthController.text.isNotEmpty && _selectedStrengthUnit != null) {
      summaryParts.add('${_strengthController.text}${_selectedStrengthUnit!.displayName}');
    }
    
    // Add quantity information
    if (_stockQuantityController.text.isNotEmpty && _selectedStockUnit != null) {
      String stockInfo = '';
      if (_selectedType == MedicationType.tablet) {
        // For tablets, show quantity x strength format
        if (_strengthController.text.isNotEmpty && _selectedStrengthUnit != null) {
          stockInfo = '${_stockQuantityController.text} x ${_strengthController.text}${_selectedStrengthUnit!.displayName} ${_selectedType!.displayName}s';
        }
      } else {
        stockInfo = '${_stockQuantityController.text} ${_selectedStockUnit!.displayName}';
      }
      if (stockInfo.isNotEmpty) {
        summaryParts.add(stockInfo);
      }
    }
    
    // Create the summary text
    String summaryText = summaryParts.isEmpty 
        ? 'Fill in details to see summary'
        : summaryParts.join(' • ');
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).colorScheme.primaryContainer,
            Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.7),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.summarize,
                color: Theme.of(context).colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Medication Summary',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            summaryText,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          if (_requiresRefrigeration) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.ac_unit,
                  color: Colors.blue,
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  'Refrigeration Required (2-8°C)',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.blue,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
          if (_expirationDate != null) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  Icons.event,
                  color: Colors.orange,
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  'Expires: ${DateFormat('MMM dd, yyyy').format(_expirationDate!)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.orange.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Future<bool> _showSaveConfirmationDialog() async {
    final summaryParts = <String>[];
    
    if (_selectedType != null) summaryParts.add(_selectedType!.displayName);
    if (_nameController.text.isNotEmpty) summaryParts.add(_nameController.text);
    if (_brandController.text.isNotEmpty) summaryParts.add('by ${_brandController.text}');
    if (_strengthController.text.isNotEmpty && _selectedStrengthUnit != null) {
      summaryParts.add('${_strengthController.text}${_selectedStrengthUnit!.displayName}');
    }
    if (_stockQuantityController.text.isNotEmpty && _selectedStockUnit != null) {
      summaryParts.add('Stock: ${_stockQuantityController.text} ${_selectedStockUnit!.displayName}');
    }
    if (_expirationDate != null) {
      summaryParts.add('Expires: ${DateFormat('MMM dd, yyyy').format(_expirationDate!)}');
    }
    
    final summary = summaryParts.join('\n');
    
    return await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Save Medication'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Please confirm the medication details:'),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  summary,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              const SizedBox(height: 16),
              const Text('Are you sure you want to save this medication?'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Save'),
            ),
          ],
        );
      },
    ) ?? false;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _brandController.dispose();
    _strengthController.dispose();
    _stockQuantityController.dispose();
    _lotNumberController.dispose();
    _descriptionController.dispose();
    _storageInstructionsController.dispose();
    _notesController.dispose();
    super.dispose();
  }
}
