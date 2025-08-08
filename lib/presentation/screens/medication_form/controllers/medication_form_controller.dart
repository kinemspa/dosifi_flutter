import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dosifi_flutter/data/models/medication.dart';
import 'package:dosifi_flutter/presentation/providers/medication_provider.dart';
import 'package:dosifi_flutter/presentation/screens/medication_form/utils/medication_type_utils.dart';

class MedicationFormController extends ChangeNotifier {
  final Ref ref;
  final String? medicationId;

  // Form controllers
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController brandController = TextEditingController();
  final TextEditingController strengthController = TextEditingController();
  final TextEditingController stockController = TextEditingController();
  final TextEditingController volumeController = TextEditingController();
  final TextEditingController concentrationController = TextEditingController();
  final TextEditingController lotBatchController = TextEditingController();
  final TextEditingController lowStockThresholdController = TextEditingController();
  final TextEditingController storageInstructionsController = TextEditingController();
  final TextEditingController storageTemperatureController = TextEditingController();
  final TextEditingController reconstitutionVolumeController = TextEditingController();
  final TextEditingController finalConcentrationController = TextEditingController();
  final TextEditingController reconstitutionNotesController = TextEditingController();
  final TextEditingController reconstitutionFluidController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController instructionsController = TextEditingController();
  final TextEditingController notesController = TextEditingController();
  final TextEditingController barcodeController = TextEditingController();

  // Form state
  MedicationType? _selectedType;
  StrengthUnit? _selectedStrengthUnit;
  String? _selectedStockUnit;
  DateTime? _expirationDate;
  bool _requiresRefrigeration = false;
  bool _isActive = true;
  bool _isLoading = false;

  MedicationFormController(this.ref, this.medicationId);

  // Getters
  MedicationType? get selectedType => _selectedType;
  StrengthUnit? get selectedStrengthUnit => _selectedStrengthUnit;
  String? get selectedStockUnit => _selectedStockUnit;
  DateTime? get expirationDate => _expirationDate;
  bool get requiresRefrigeration => _requiresRefrigeration;
  bool get isActive => _isActive;
  bool get isLoading => _isLoading;
  bool get isEditMode => medicationId != null;

  // Setters
  void setSelectedType(MedicationType? type) {
    _selectedType = type;
    if (type != null) {
      _selectedStrengthUnit = MedicationTypeUtils.getDefaultStrengthUnit(type);
      _selectedStockUnit = MedicationTypeUtils.getStockUnit(type);
    }
    notifyListeners();
  }

  void setSelectedStrengthUnit(StrengthUnit? unit) {
    _selectedStrengthUnit = unit;
    notifyListeners();
  }

  void setExpirationDate(DateTime? date) {
    _expirationDate = date;
    notifyListeners();
  }

  void setRequiresRefrigeration(bool value) {
    _requiresRefrigeration = value;
    notifyListeners();
  }

  void setIsActive(bool value) {
    _isActive = value;
    notifyListeners();
  }

  void setIsLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  // Load medication data for editing
  Future<void> loadMedicationData() async {
    if (!isEditMode) return;
    
    final medication = await ref.read(medicationByIdProvider(int.parse(medicationId!)).future);
    if (medication != null) {
      populateFormWithMedication(medication);
    }
  }

  // Populate form with existing medication data
  void populateFormWithMedication(Medication medication) {
    nameController.text = medication.name;
    brandController.text = medication.brandManufacturer ?? '';
    strengthController.text = medication.strengthPerUnit.toString();
    stockController.text = medication.stockQuantity.toString();
    lotBatchController.text = medication.lotBatchNumber ?? '';
    lowStockThresholdController.text = medication.lowStockThreshold?.toString() ?? '';
    storageInstructionsController.text = medication.storageInstructions ?? '';
    storageTemperatureController.text = medication.storageTemperature ?? '';
    reconstitutionVolumeController.text = medication.reconstitutionVolume?.toString() ?? '';
    finalConcentrationController.text = medication.finalConcentration?.toString() ?? '';
    reconstitutionNotesController.text = medication.reconstitutionNotes ?? '';
    reconstitutionFluidController.text = medication.reconstitutionFluid ?? '';
    descriptionController.text = medication.description ?? '';
    instructionsController.text = medication.instructions ?? '';
    notesController.text = medication.notes ?? '';
    barcodeController.text = medication.barcode ?? '';

    _selectedType = medication.type;
    _selectedStrengthUnit = medication.strengthUnit;
    _selectedStockUnit = MedicationTypeUtils.getStockUnit(medication.type);
    _expirationDate = medication.expirationDate;
    _requiresRefrigeration = medication.requiresRefrigeration;
    _isActive = medication.isActive;
    
    notifyListeners();
  }

  // Clear form fields (except in edit mode)
  void clearFormFields() {
    if (!isEditMode) {
      nameController.clear();
      brandController.clear();
      strengthController.clear();
      stockController.clear();
      volumeController.clear();
      concentrationController.clear();
    }
  }

  // Validate form
  bool validateForm() {
    return formKey.currentState?.validate() ?? false;
  }

  // Create new medication
  Future<void> createMedication() async {
    final medication = Medication.create(
      name: nameController.text.trim(),
      type: _selectedType!,
      brandManufacturer: brandController.text.trim().isNotEmpty 
          ? brandController.text.trim() 
          : null,
      strengthPerUnit: double.parse(strengthController.text),
      strengthUnit: _selectedStrengthUnit!,
      stockQuantity: double.parse(stockController.text),
      lotBatchNumber: lotBatchController.text.trim().isNotEmpty 
          ? lotBatchController.text.trim() 
          : null,
      expirationDate: _expirationDate,
      storageInstructions: storageInstructionsController.text.trim().isNotEmpty 
          ? storageInstructionsController.text.trim() 
          : null,
      requiresRefrigeration: _requiresRefrigeration,
      reconstitutionVolume: reconstitutionVolumeController.text.trim().isNotEmpty 
          ? double.parse(reconstitutionVolumeController.text) 
          : null,
      finalConcentration: finalConcentrationController.text.trim().isNotEmpty 
          ? double.parse(finalConcentrationController.text) 
          : null,
      reconstitutionNotes: reconstitutionNotesController.text.trim().isNotEmpty 
          ? reconstitutionNotesController.text.trim() 
          : null,
      reconstitutionFluid: reconstitutionFluidController.text.trim().isNotEmpty 
          ? reconstitutionFluidController.text.trim() 
          : null,
      description: descriptionController.text.trim().isNotEmpty 
          ? descriptionController.text.trim() 
          : null,
      instructions: instructionsController.text.trim().isNotEmpty 
          ? instructionsController.text.trim() 
          : null,
      notes: notesController.text.trim().isNotEmpty 
          ? notesController.text.trim() 
          : null,
      barcode: barcodeController.text.trim().isNotEmpty 
          ? barcodeController.text.trim() 
          : null,
    );

    await ref.read(medicationListProvider.notifier).addMedication(medication);
  }

  // Update existing medication
  Future<void> updateMedication() async {
    final existingMedication = await ref.read(
      medicationByIdProvider(int.parse(medicationId!)).future,
    );
    
    if (existingMedication == null) {
      throw Exception('Medication not found');
    }

    final updatedMedication = existingMedication.copyWith(
      name: nameController.text.trim(),
      type: _selectedType!,
      brandManufacturer: brandController.text.trim().isNotEmpty 
          ? brandController.text.trim() 
          : null,
      strengthPerUnit: double.parse(strengthController.text),
      strengthUnit: _selectedStrengthUnit!,
      stockQuantity: double.parse(stockController.text),
      lotBatchNumber: lotBatchController.text.trim().isNotEmpty 
          ? lotBatchController.text.trim() 
          : null,
      expirationDate: _expirationDate,
      reconstitutionVolume: reconstitutionVolumeController.text.trim().isNotEmpty 
          ? double.parse(reconstitutionVolumeController.text) 
          : null,
      finalConcentration: finalConcentrationController.text.trim().isNotEmpty 
          ? double.parse(finalConcentrationController.text) 
          : null,
      reconstitutionNotes: reconstitutionNotesController.text.trim().isNotEmpty 
          ? reconstitutionNotesController.text.trim() 
          : null,
      description: descriptionController.text.trim().isNotEmpty 
          ? descriptionController.text.trim() 
          : null,
      instructions: instructionsController.text.trim().isNotEmpty 
          ? instructionsController.text.trim() 
          : null,
      notes: notesController.text.trim().isNotEmpty 
          ? notesController.text.trim() 
          : null,
      barcode: barcodeController.text.trim().isNotEmpty 
          ? barcodeController.text.trim() 
          : null,
      isActive: _isActive,
    );

    await ref.read(medicationListProvider.notifier).updateMedication(updatedMedication);
  }

  // Delete medication
  Future<void> deleteMedication() async {
    if (!isEditMode) return;
    await ref.read(medicationListProvider.notifier)
        .deleteMedication(int.parse(medicationId!));
  }

  @override
  void dispose() {
    nameController.dispose();
    brandController.dispose();
    strengthController.dispose();
    stockController.dispose();
    volumeController.dispose();
    concentrationController.dispose();
    lotBatchController.dispose();
    lowStockThresholdController.dispose();
    storageInstructionsController.dispose();
    storageTemperatureController.dispose();
    reconstitutionVolumeController.dispose();
    finalConcentrationController.dispose();
    reconstitutionNotesController.dispose();
    reconstitutionFluidController.dispose();
    descriptionController.dispose();
    instructionsController.dispose();
    notesController.dispose();
    barcodeController.dispose();
    super.dispose();
  }
}

// Provider for the form controller
final medicationFormControllerProvider = ChangeNotifierProvider.family<MedicationFormController, String?>((ref, medicationId) {
  return MedicationFormController(ref, medicationId);
});
