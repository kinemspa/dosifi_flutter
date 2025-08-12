import 'package:flutter_riverpod/flutter_riverpod.dart';

enum MedicationCardLayout {
  outlinedClassic,
  outlinedSoft,
  outlinedShadow,
  outlinedAccentBar,
  outlinedPill,
  outlinedDense,
  outlinedDivider,
  outlinedMonochrome,
  outlinedCompactChips,
  outlinedLargeTitle;

  String get displayName {
    switch (this) {
      case MedicationCardLayout.outlinedClassic:
        return 'Outlined • Classic';
      case MedicationCardLayout.outlinedSoft:
        return 'Outlined • Soft';
      case MedicationCardLayout.outlinedShadow:
        return 'Outlined • Shadow';
      case MedicationCardLayout.outlinedAccentBar:
        return 'Outlined • Accent Bar';
      case MedicationCardLayout.outlinedPill:
        return 'Outlined • Pill';
      case MedicationCardLayout.outlinedDense:
        return 'Outlined • Dense';
      case MedicationCardLayout.outlinedDivider:
        return 'Outlined • Divider';
      case MedicationCardLayout.outlinedMonochrome:
        return 'Outlined • Monochrome';
      case MedicationCardLayout.outlinedCompactChips:
        return 'Outlined • Compact Chips';
      case MedicationCardLayout.outlinedLargeTitle:
        return 'Outlined • Large Title';
    }
  }

  String get description {
    switch (this) {
      case MedicationCardLayout.outlinedClassic:
        return 'Clean bordered rows';
      case MedicationCardLayout.outlinedSoft:
        return 'Rounded, airy border';
      case MedicationCardLayout.outlinedShadow:
        return 'Border with subtle shadow';
      case MedicationCardLayout.outlinedAccentBar:
        return 'Border + colored side bar';
      case MedicationCardLayout.outlinedPill:
        return 'High radius “pill” border';
      case MedicationCardLayout.outlinedDense:
        return 'Very compact bordered row';
      case MedicationCardLayout.outlinedDivider:
        return 'Vertical divider before trailing';
      case MedicationCardLayout.outlinedMonochrome:
        return 'Greyscale, restrained color';
      case MedicationCardLayout.outlinedCompactChips:
        return 'Tiny status chips inline';
      case MedicationCardLayout.outlinedLargeTitle:
        return 'Large title, two-line subtitle';
    }
  }
}

class MedicationLayoutNotifier extends StateNotifier<MedicationCardLayout> {
  MedicationLayoutNotifier() : super(MedicationCardLayout.outlinedClassic);

  void setLayout(MedicationCardLayout layout) {
    state = layout;
  }

  void cycleLayout() {
    switch (state) {
      case MedicationCardLayout.outlinedClassic:
        state = MedicationCardLayout.outlinedSoft;
        break;
      case MedicationCardLayout.outlinedSoft:
        state = MedicationCardLayout.outlinedShadow;
        break;
      case MedicationCardLayout.outlinedShadow:
        state = MedicationCardLayout.outlinedAccentBar;
        break;
      case MedicationCardLayout.outlinedAccentBar:
        state = MedicationCardLayout.outlinedPill;
        break;
      case MedicationCardLayout.outlinedPill:
        state = MedicationCardLayout.outlinedDense;
        break;
      case MedicationCardLayout.outlinedDense:
        state = MedicationCardLayout.outlinedDivider;
        break;
      case MedicationCardLayout.outlinedDivider:
        state = MedicationCardLayout.outlinedMonochrome;
        break;
      case MedicationCardLayout.outlinedMonochrome:
        state = MedicationCardLayout.outlinedCompactChips;
        break;
      case MedicationCardLayout.outlinedCompactChips:
        state = MedicationCardLayout.outlinedLargeTitle;
        break;
      case MedicationCardLayout.outlinedLargeTitle:
        state = MedicationCardLayout.outlinedClassic;
        break;
    }
  }
}

final medicationLayoutProvider = StateNotifierProvider<MedicationLayoutNotifier, MedicationCardLayout>(
  (ref) => MedicationLayoutNotifier(),
);
