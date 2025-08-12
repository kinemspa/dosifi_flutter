import 'package:flutter_riverpod/flutter_riverpod.dart';

enum SupplyCardLayout {
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
      case SupplyCardLayout.outlinedClassic:
        return 'Outlined • Classic';
      case SupplyCardLayout.outlinedSoft:
        return 'Outlined • Soft';
      case SupplyCardLayout.outlinedShadow:
        return 'Outlined • Shadow';
      case SupplyCardLayout.outlinedAccentBar:
        return 'Outlined • Accent Bar';
      case SupplyCardLayout.outlinedPill:
        return 'Outlined • Pill';
      case SupplyCardLayout.outlinedDense:
        return 'Outlined • Dense';
      case SupplyCardLayout.outlinedDivider:
        return 'Outlined • Divider';
      case SupplyCardLayout.outlinedMonochrome:
        return 'Outlined • Monochrome';
      case SupplyCardLayout.outlinedCompactChips:
        return 'Outlined • Compact Chips';
      case SupplyCardLayout.outlinedLargeTitle:
        return 'Outlined • Large Title';
    }
  }

  String get description {
    switch (this) {
      case SupplyCardLayout.outlinedClassic:
        return 'Clean bordered rows';
      case SupplyCardLayout.outlinedSoft:
        return 'Rounded, airy border';
      case SupplyCardLayout.outlinedShadow:
        return 'Border with subtle shadow';
      case SupplyCardLayout.outlinedAccentBar:
        return 'Border + colored side bar';
      case SupplyCardLayout.outlinedPill:
        return 'High radius “pill” border';
      case SupplyCardLayout.outlinedDense:
        return 'Very compact bordered row';
      case SupplyCardLayout.outlinedDivider:
        return 'Vertical divider before trailing';
      case SupplyCardLayout.outlinedMonochrome:
        return 'Greyscale, restrained color';
      case SupplyCardLayout.outlinedCompactChips:
        return 'Tiny status chips inline';
      case SupplyCardLayout.outlinedLargeTitle:
        return 'Large title, two-line subtitle';
    }
  }
}

class SupplyLayoutNotifier extends StateNotifier<SupplyCardLayout> {
  SupplyLayoutNotifier() : super(SupplyCardLayout.outlinedClassic);

  void setLayout(SupplyCardLayout layout) {
    state = layout;
  }

  void cycleLayout() {
    switch (state) {
      case SupplyCardLayout.outlinedClassic:
        state = SupplyCardLayout.outlinedSoft;
        break;
      case SupplyCardLayout.outlinedSoft:
        state = SupplyCardLayout.outlinedShadow;
        break;
      case SupplyCardLayout.outlinedShadow:
        state = SupplyCardLayout.outlinedAccentBar;
        break;
      case SupplyCardLayout.outlinedAccentBar:
        state = SupplyCardLayout.outlinedPill;
        break;
      case SupplyCardLayout.outlinedPill:
        state = SupplyCardLayout.outlinedDense;
        break;
      case SupplyCardLayout.outlinedDense:
        state = SupplyCardLayout.outlinedDivider;
        break;
      case SupplyCardLayout.outlinedDivider:
        state = SupplyCardLayout.outlinedMonochrome;
        break;
      case SupplyCardLayout.outlinedMonochrome:
        state = SupplyCardLayout.outlinedCompactChips;
        break;
      case SupplyCardLayout.outlinedCompactChips:
        state = SupplyCardLayout.outlinedLargeTitle;
        break;
      case SupplyCardLayout.outlinedLargeTitle:
        state = SupplyCardLayout.outlinedClassic;
        break;
    }
  }
}

final supplyLayoutProvider = StateNotifierProvider<SupplyLayoutNotifier, SupplyCardLayout>(
  (ref) => SupplyLayoutNotifier(),
);

