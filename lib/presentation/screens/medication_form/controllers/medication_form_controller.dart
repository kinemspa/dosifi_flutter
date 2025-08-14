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
  bool _alertOnLowStock = false;
  bool _isActive = true;
  bool _isLoading = false;

  // Theme color state (hex string like #FF6F61)
  String? _selectedThemeColor;

  MedicationFormController(this.ref, this.medicationId) {
    _wireTextListeners();
  }

  // Getters
  MedicationType? get selectedType => _selectedType;
  StrengthUnit? get selectedStrengthUnit => _selectedStrengthUnit;
  String? get selectedStockUnit => _selectedStockUnit;
  DateTime? get expirationDate => _expirationDate;
  bool get requiresRefrigeration => _requiresRefrigeration;
  bool get alertOnLowStock => _alertOnLowStock;
  bool get isActive => _isActive;
  bool get isLoading => _isLoading;
  bool get isEditMode => medicationId != null;
  String? get selectedThemeColor => _selectedThemeColor;

  // Provide a curated palette
  List<String> get colorOptions => const [
        '#6C5CE7', // indigo
        '#00B894', // teal
        '#0984E3', // blue
        '#E17055', // orange
        '#E84393', // pink
        '#636E72', // gray
      ];

  Color colorFromHex(String hex) {
    final cleaned = hex.replaceAll('#', '');
    final intVal = int.parse('FF$cleaned', radix: 16);
    return Color(intVal);
  }

  // Setters
  void setSelectedType(MedicationType? type) {
    _selectedType = type;
    if (type != null) {
      _selectedStrengthUnit = MedicationTypeUtils.getDefaultStrengthUnit(type);
      _selectedStockUnit = MedicationTypeUtils.getStockUnit(type);
      // Default theme color based on type if not explicitly chosen
      _selectedThemeColor ??= _defaultColorForType(type);
    }
    notifyListeners();
  }

  void setSelectedStrengthUnit(StrengthUnit? unit) {
    _selectedStrengthUnit = unit;
    notifyListeners();
  }

  void setSelectedStockUnit(String? unit) {
    _selectedStockUnit = unit;
    notifyListeners();
  }

  void setExpirationDate(DateTime? date) {
    _expirationDate = date;
    notifyListeners();
  }

  void setRequiresRefrigeration(bool value) {
    _requiresRefrigeration = value;
    // Auto-manage temperature field when refrigeration is required
    if (_requiresRefrigeration) {
      storageTemperatureController.text = '2–8 °C';
    }
    notifyListeners();
  }

  void setAlertOnLowStock(bool value) {
    _alertOnLowStock = value;
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

  void setSelectedThemeColor(String? hex) {
    _selectedThemeColor = hex;
    notifyListeners();
  }

  String _defaultColorForType(MedicationType type) {
    switch (type) {
      case MedicationType.tablet:
        return '#0984E3';
      case MedicationType.capsule:
        return '#00B894';
      case MedicationType.liquid:
        return '#6C5CE7';
      case MedicationType.preFilledSyringe:
      case MedicationType.readyMadeVial:
        return '#E84393';
      case MedicationType.lyophilizedVial:
        return '#636E72';
      default:
        return '#6C5CE7';
    }
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
    _selectedThemeColor = medication.themeColor;
    instructionsController.text = medication.instructions ?? '';
    notesController.text = medication.notes ?? '';
    barcodeController.text = medication.barcode ?? '';

    _selectedType = medication.type;
    _selectedStrengthUnit = medication.strengthUnit;
    _selectedStockUnit = medication.stockUnit?.displayName ?? MedicationTypeUtils.getStockUnit(medication.type);
    _expirationDate = medication.expirationDate;
    _requiresRefrigeration = medication.requiresRefrigeration;
    _alertOnLowStock = medication.alertOnLowStock;
    _isActive = medication.isActive;

    notifyListeners();
  }

  // Clear limited fields (kept for backwards compatibility)
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

  // Fully reset the form to initial add state
  void resetFormState() {
    if (isEditMode) return;
    formKey.currentState?.reset();
    nameController.clear();
    brandController.clear();
    strengthController.clear();
    stockController.clear();
    volumeController.clear();
    concentrationController.clear();
    lotBatchController.clear();
    lowStockThresholdController.clear();
    storageInstructionsController.clear();
    storageTemperatureController.clear();
    reconstitutionVolumeController.clear();
    finalConcentrationController.clear();
    reconstitutionNotesController.clear();
    reconstitutionFluidController.clear();
    descriptionController.clear();
    instructionsController.clear();
    notesController.clear();
    _selectedThemeColor = null;
    barcodeController.clear();
    _selectedType = null;
    _selectedStrengthUnit = null;
    _selectedStockUnit = null;
    _expirationDate = null;
    _requiresRefrigeration = false;
    _alertOnLowStock = false;
    _isActive = true;
    notifyListeners();
  }

  // Validate form
  bool validateForm() {
    return formKey.currentState?.validate() ?? false;
  }

  // Map selected stock unit string to StrengthUnit where applicable
  StrengthUnit? _mapStockUnitToEnum(String? unit) {
    switch (unit) {
      case 'mL':
        return StrengthUnit.ml;
      case 'Units':
        return StrengthUnit.units;
      case 'IU':
        return StrengthUnit.iu;
      case 'g':
        return StrengthUnit.g;
      default:
        return null;
    }
  }

  // Create new medication
  Future<void> createMedication() async {
    // Normalize percent for pre-filled syringe: convert % to mg/mL using 1% = 10 mg/mL
    StrengthUnit? normalizedUnit = _selectedStrengthUnit;
    double parsedStrength = double.parse(strengthController.text);
    if (_selectedType == MedicationType.preFilledSyringe && _selectedStrengthUnit == StrengthUnit.percent) {
      // Convert to mg/mL
      final concMgPerMl = parsedStrength * 10.0;
      normalizedUnit = StrengthUnit.mg;
      parsedStrength = concMgPerMl;
    }

    final medication = Medication.create(
      name: nameController.text.trim(),
      type: _selectedType!,
      brandManufacturer: brandController.text.trim().isNotEmpty ? brandController.text.trim() : null,
      strengthPerUnit: parsedStrength,
      strengthUnit: normalizedUnit!,
      stockQuantity: double.parse(stockController.text),
      stockUnit: _mapStockUnitToEnum(_selectedStockUnit),
      lotBatchNumber: lotBatchController.text.trim().isNotEmpty ? lotBatchController.text.trim() : null,
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
      description: descriptionController.text.trim().isNotEmpty ? descriptionController.text.trim() : null,
      instructions: instructionsController.text.trim().isNotEmpty ? instructionsController.text.trim() : null,
      notes: notesController.text.trim().isNotEmpty ? notesController.text.trim() : null,
      barcode: barcodeController.text.trim().isNotEmpty ? barcodeController.text.trim() : null,
      // theme color
      // themeColor stored later via repository update if needed
      alertOnLowStock: _alertOnLowStock,
      packageSize: null,
      vialsInStock: null,
    );

    // Attach themeColor if chosen by setting it on the created object before insert
    final medWithColor = medication.copyWith(themeColor: _selectedThemeColor);
    await ref.read(medicationListProvider.notifier).addMedication(medWithColor);
  }

  // Update existing medication
  Future<void> updateMedication() async {
    final existingMedication = await ref.read(medicationByIdProvider(int.parse(medicationId!)).future);

    if (existingMedication == null) {
      throw Exception('Medication not found');
    }

    // Normalize percent for pre-filled syringe
    StrengthUnit? normalizedUnit = _selectedStrengthUnit;
    double parsedStrength = double.parse(strengthController.text);
    if (_selectedType == MedicationType.preFilledSyringe && _selectedStrengthUnit == StrengthUnit.percent) {
      final concMgPerMl = parsedStrength * 10.0;
      normalizedUnit = StrengthUnit.mg;
      parsedStrength = concMgPerMl;
    }

    final updatedMedication = existingMedication.copyWith(
      name: nameController.text.trim(),
      type: _selectedType!,
      brandManufacturer: brandController.text.trim().isNotEmpty ? brandController.text.trim() : null,
      strengthPerUnit: parsedStrength,
      strengthUnit: normalizedUnit!,
      stockQuantity: double.parse(stockController.text),
      lotBatchNumber: lotBatchController.text.trim().isNotEmpty ? lotBatchController.text.trim() : null,
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
      description: descriptionController.text.trim().isNotEmpty ? descriptionController.text.trim() : null,
      instructions: instructionsController.text.trim().isNotEmpty ? instructionsController.text.trim() : null,
      notes: notesController.text.trim().isNotEmpty ? notesController.text.trim() : null,
      barcode: barcodeController.text.trim().isNotEmpty ? barcodeController.text.trim() : null,
      isActive: _isActive,
      themeColor: _selectedThemeColor,
    );

    await ref.read(medicationListProvider.notifier).updateMedication(updatedMedication);
  }

  // Delete medication
  Future<void> deleteMedication() async {
    if (!isEditMode) return;
    await ref.read(medicationListProvider.notifier).deleteMedication(int.parse(medicationId!));
  }

  void _wireTextListeners() {
    // Rebuild listeners for summary banner and dependent UI
    nameController.addListener(notifyListeners);
    brandController.addListener(notifyListeners);
    strengthController.addListener(notifyListeners);
    stockController.addListener(notifyListeners);
    storageTemperatureController.addListener(notifyListeners);
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
final medicationFormControllerProvider = ChangeNotifierProvider.family<MedicationFormController, String?>((
  ref,
  medicationId,
) {
  return MedicationFormController(ref, medicationId);
});
