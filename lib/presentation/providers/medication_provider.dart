import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/medication.dart';
import '../../data/repositories/medication_repository.dart';

// Repository provider
final medicationRepositoryProvider = Provider<MedicationRepository>((ref) {
  return MedicationRepository();
});

// State notifier for managing medications list
class MedicationListNotifier extends StateNotifier<AsyncValue<List<Medication>>> {
  final MedicationRepository _repository;

  MedicationListNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadMedications();
  }
  
  // Test method to add a sample medication if none exist
  Future<void> _ensureTestMedicationExists() async {
    print('💊 [PROVIDER DEBUG] Checking if test medications exist');
    try {
      final medications = await _repository.getActiveMedications();
      if (medications.isEmpty) {
        print('💊 [PROVIDER DEBUG] No medications found, inserting test medication');
        final testMedication = Medication(
          name: 'Test Aspirin',
          type: MedicationType.tablet,
          strengthPerUnit: 500.0,
          strengthUnit: StrengthUnit.mg,
          stockQuantity: 30.0,
          brandManufacturer: 'Test Brand',
          instructions: 'Take as needed for pain relief',
          notes: 'Test medication for debugging',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        await _repository.insertMedication(testMedication);
        print('💊 [PROVIDER DEBUG] Test medication inserted successfully');
      }
    } catch (e) {
      print('💊 [PROVIDER DEBUG] Error ensuring test medication: $e');
    }
  }

  Future<void> loadMedications() async {
    print('💊 [PROVIDER DEBUG] loadMedications() called');
    state = const AsyncValue.loading();
    try {
      // Ensure we have test data first
      await _ensureTestMedicationExists();
      
      print('💊 [PROVIDER DEBUG] Calling repository.getActiveMedications()');
      final medications = await _repository.getActiveMedications();
      print('💊 [PROVIDER DEBUG] Repository returned ${medications.length} medications');
      if (medications.isNotEmpty) {
        print('💊 [PROVIDER DEBUG] First medication: ${medications.first.name}');
      }
      state = AsyncValue.data(medications);
      print('💊 [PROVIDER DEBUG] State updated with medications data');
    } catch (e, stack) {
      print('💊 [PROVIDER DEBUG] Error loading medications: $e');
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> addMedication(Medication medication) async {
    try {
      final id = await _repository.insertMedication(medication);
      final newMedication = medication.copyWith(id: id);
      
      state.whenData((medications) {
        state = AsyncValue.data([...medications, newMedication]);
      });
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> updateMedication(Medication medication) async {
    try {
      await _repository.updateMedication(medication);
      
      state.whenData((medications) {
        final updatedList = medications.map((m) {
          return m.id == medication.id ? medication : m;
        }).toList();
        state = AsyncValue.data(updatedList);
      });
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> deleteMedication(int id) async {
    try {
      await _repository.deleteMedication(id);
      
      state.whenData((medications) {
        final updatedList = medications.where((m) => m.id != id).toList();
        state = AsyncValue.data(updatedList);
      });
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  // Stock management methods
  Future<void> updateMedicationStock(int medicationId, double newStockQuantity) async {
    try {
      await _repository.updateMedicationStock(medicationId, newStockQuantity);
      
      // Reload medications to reflect stock changes
      await loadMedications();
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> adjustMedicationStock(int medicationId, double adjustment) async {
    try {
      await _repository.adjustMedicationStock(medicationId, adjustment);
      
      // Reload medications to reflect stock changes
      await loadMedications();
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> searchMedications(String query) async {
    state = const AsyncValue.loading();
    try {
      final medications = query.isEmpty 
          ? await _repository.getActiveMedications()
          : await _repository.searchMedications(query);
      state = AsyncValue.data(medications);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> filterByType(String? type) async {
    state = const AsyncValue.loading();
    try {
      final medications = type == null
          ? await _repository.getActiveMedications()
          : await _repository.getMedicationsByType(type);
      state = AsyncValue.data(medications);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}

// Provider for the medication list state notifier
final medicationListProvider = 
    StateNotifierProvider<MedicationListNotifier, AsyncValue<List<Medication>>>((ref) {
  final repository = ref.watch(medicationRepositoryProvider);
  return MedicationListNotifier(repository);
});

// Provider for getting a single medication by ID
final medicationByIdProvider = FutureProvider.family<Medication?, int>((ref, id) async {
  final repository = ref.watch(medicationRepositoryProvider);
  return await repository.getMedicationById(id);
});

// Provider for getting medication with all details
final medicationDetailsProvider = 
    FutureProvider.family<Map<String, dynamic>?, int>((ref, id) async {
  final repository = ref.watch(medicationRepositoryProvider);
  return await repository.getMedicationWithDetails(id);
});

// Provider for expiring medications
final expiringMedicationsProvider = FutureProvider<List<Medication>>((ref) async {
  final repository = ref.watch(medicationRepositoryProvider);
  return await repository.getExpiringMedications(30); // 30 days ahead
});

// Search query provider
final medicationSearchQueryProvider = StateProvider<String>((ref) => '');

// Filter type provider
final medicationTypeFilterProvider = StateProvider<String?>((ref) => null);

// Filtered medications provider
final filteredMedicationsProvider = Provider<AsyncValue<List<Medication>>>((ref) {
  final searchQuery = ref.watch(medicationSearchQueryProvider);
  final typeFilter = ref.watch(medicationTypeFilterProvider);
  final medications = ref.watch(medicationListProvider);

  return medications.whenData((list) {
    var filtered = list;

    // Apply search filter
    if (searchQuery.isNotEmpty) {
      filtered = filtered.where((medication) {
        return medication.name.toLowerCase().contains(searchQuery.toLowerCase()) ||
               (medication.notes?.toLowerCase().contains(searchQuery.toLowerCase()) ?? false);
      }).toList();
    }

    // Apply type filter
    if (typeFilter != null) {
      filtered = filtered.where((medication) => medication.type.name == typeFilter).toList();
    }

    return filtered;
  });
});
