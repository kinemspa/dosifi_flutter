import 'package:flutter_riverpod/flutter_riverpod.dart';

enum MedicationCardLayout {
  large,
  compact,
  tiles;

  String get displayName {
    switch (this) {
      case MedicationCardLayout.large:
        return 'Large';
      case MedicationCardLayout.compact:
        return 'Compact';
      case MedicationCardLayout.tiles:
        return 'Tiles';
    }
  }

  String get description {
    switch (this) {
      case MedicationCardLayout.large:
        return 'Full information cards';
      case MedicationCardLayout.compact:
        return 'Essential info only';
      case MedicationCardLayout.tiles:
        return 'Grid view layout';
    }
  }
}

class MedicationLayoutNotifier extends StateNotifier<MedicationCardLayout> {
  MedicationLayoutNotifier() : super(MedicationCardLayout.large);

  void setLayout(MedicationCardLayout layout) {
    state = layout;
  }

  void cycleLayout() {
    switch (state) {
      case MedicationCardLayout.large:
        state = MedicationCardLayout.compact;
        break;
      case MedicationCardLayout.compact:
        state = MedicationCardLayout.tiles;
        break;
      case MedicationCardLayout.tiles:
        state = MedicationCardLayout.large;
        break;
    }
  }
}

final medicationLayoutProvider = StateNotifierProvider<MedicationLayoutNotifier, MedicationCardLayout>(
  (ref) => MedicationLayoutNotifier(),
);
