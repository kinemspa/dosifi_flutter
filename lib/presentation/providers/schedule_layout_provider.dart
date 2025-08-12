import 'package:flutter_riverpod/flutter_riverpod.dart';

enum ScheduleCardLayout {
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
      case ScheduleCardLayout.outlinedClassic:
        return 'Outlined • Classic';
      case ScheduleCardLayout.outlinedSoft:
        return 'Outlined • Soft';
      case ScheduleCardLayout.outlinedShadow:
        return 'Outlined • Shadow';
      case ScheduleCardLayout.outlinedAccentBar:
        return 'Outlined • Accent Bar';
      case ScheduleCardLayout.outlinedPill:
        return 'Outlined • Pill';
      case ScheduleCardLayout.outlinedDense:
        return 'Outlined • Dense';
      case ScheduleCardLayout.outlinedDivider:
        return 'Outlined • Divider';
      case ScheduleCardLayout.outlinedMonochrome:
        return 'Outlined • Monochrome';
      case ScheduleCardLayout.outlinedCompactChips:
        return 'Outlined • Compact Chips';
      case ScheduleCardLayout.outlinedLargeTitle:
        return 'Outlined • Large Title';
    }
  }

  String get description {
    switch (this) {
      case ScheduleCardLayout.outlinedClassic:
        return 'Clean bordered rows';
      case ScheduleCardLayout.outlinedSoft:
        return 'Rounded, airy border';
      case ScheduleCardLayout.outlinedShadow:
        return 'Border with subtle shadow';
      case ScheduleCardLayout.outlinedAccentBar:
        return 'Border + colored side bar';
      case ScheduleCardLayout.outlinedPill:
        return 'High radius “pill” border';
      case ScheduleCardLayout.outlinedDense:
        return 'Very compact bordered row';
      case ScheduleCardLayout.outlinedDivider:
        return 'Vertical divider before trailing';
      case ScheduleCardLayout.outlinedMonochrome:
        return 'Greyscale, restrained color';
      case ScheduleCardLayout.outlinedCompactChips:
        return 'Tiny status chips inline';
      case ScheduleCardLayout.outlinedLargeTitle:
        return 'Large title, two-line subtitle';
    }
  }
}

class ScheduleLayoutNotifier extends StateNotifier<ScheduleCardLayout> {
  ScheduleLayoutNotifier() : super(ScheduleCardLayout.outlinedClassic);

  void setLayout(ScheduleCardLayout layout) {
    state = layout;
  }

  void cycleLayout() {
    switch (state) {
      case ScheduleCardLayout.outlinedClassic:
        state = ScheduleCardLayout.outlinedSoft;
        break;
      case ScheduleCardLayout.outlinedSoft:
        state = ScheduleCardLayout.outlinedShadow;
        break;
      case ScheduleCardLayout.outlinedShadow:
        state = ScheduleCardLayout.outlinedAccentBar;
        break;
      case ScheduleCardLayout.outlinedAccentBar:
        state = ScheduleCardLayout.outlinedPill;
        break;
      case ScheduleCardLayout.outlinedPill:
        state = ScheduleCardLayout.outlinedDense;
        break;
      case ScheduleCardLayout.outlinedDense:
        state = ScheduleCardLayout.outlinedDivider;
        break;
      case ScheduleCardLayout.outlinedDivider:
        state = ScheduleCardLayout.outlinedMonochrome;
        break;
      case ScheduleCardLayout.outlinedMonochrome:
        state = ScheduleCardLayout.outlinedCompactChips;
        break;
      case ScheduleCardLayout.outlinedCompactChips:
        state = ScheduleCardLayout.outlinedLargeTitle;
        break;
      case ScheduleCardLayout.outlinedLargeTitle:
        state = ScheduleCardLayout.outlinedClassic;
        break;
    }
  }
}

final scheduleLayoutProvider = StateNotifierProvider<ScheduleLayoutNotifier, ScheduleCardLayout>(
  (ref) => ScheduleLayoutNotifier(),
);

