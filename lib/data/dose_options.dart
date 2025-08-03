import 'package:flutter/foundation.dart';
import 'models/medication.dart';

@immutable
class DoseOption {
  final String displayName;
  final String unit;

  const DoseOption({required this.displayName, required this.unit});
}

final doseOptions = {
  MedicationType.tablet: [
    DoseOption(displayName: 'tablet(s)', unit: 'tablet'),
    DoseOption(displayName: 'mg', unit: 'mg'),
  ],
  MedicationType.capsule: [
    DoseOption(displayName: 'capsule(s)', unit: 'capsule'),
    DoseOption(displayName: 'mg', unit: 'mg'),
  ],
  MedicationType.liquid: [
    DoseOption(displayName: 'ml', unit: 'ml'),
    DoseOption(displayName: 'mg', unit: 'mg'),
  ],
  MedicationType.injection: [
    DoseOption(displayName: 'mg', unit: 'mg'),
    DoseOption(displayName: 'ml', unit: 'ml'),
  ],
  MedicationType.preFilledSyringe: [
    DoseOption(displayName: 'ml', unit: 'ml'),
    DoseOption(displayName: 'mg', unit: 'mg'),
  ],
  MedicationType.readyMadeVial: [
    DoseOption(displayName: 'ml', unit: 'ml'),
    DoseOption(displayName: 'mg', unit: 'mg'),
  ],
};

List<DoseOption> getDoseOptions(MedicationType type) {
  return doseOptions[type] ?? [];
}
