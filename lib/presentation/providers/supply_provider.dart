import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/supply.dart';
import '../../data/repositories/supply_repository.dart';
import '../../core/services/database_service.dart';

// Supply repository provider
final supplyRepositoryProvider = Provider<SupplyRepository>((ref) {
  return SupplyRepository();
});

// Supply list notifier
class SupplyListNotifier extends StateNotifier<AsyncValue<List<Supply>>> {
  final SupplyRepository _repository;

  SupplyListNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadSupplies();
  }

  Future<void> loadSupplies() async {
    try {
      state = const AsyncValue.loading();
      final supplies = await _repository.getAll();
      state = AsyncValue.data(supplies);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addSupply(Supply supply) async {
    try {
      final id = await _repository.insert(supply);
      final newSupply = supply.copyWith(id: id);
      
      state.whenData((supplies) {
        state = AsyncValue.data([...supplies, newSupply]);
      });
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateSupply(Supply supply) async {
    try {
      await _repository.update(supply);
      
      state.whenData((supplies) {
        state = AsyncValue.data([
          for (final s in supplies)
            if (s.id == supply.id) supply else s,
        ]);
      });
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> deleteSupply(int id) async {
    try {
      await _repository.delete(id);
      
      state.whenData((supplies) {
        state = AsyncValue.data(
          supplies.where((s) => s.id != id).toList(),
        );
      });
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> adjustQuantity(int id, int adjustment) async {
    try {
      await _repository.adjustQuantity(id, adjustment);
      
      final updatedSupply = await _repository.getById(id);
      if (updatedSupply != null) {
        state.whenData((supplies) {
          state = AsyncValue.data([
            for (final s in supplies)
              if (s.id == id) updatedSupply else s,
          ]);
        });
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

// Supply list provider
final supplyListProvider = StateNotifierProvider<SupplyListNotifier, AsyncValue<List<Supply>>>((ref) {
  final repository = ref.watch(supplyRepositoryProvider);
  return SupplyListNotifier(repository);
});

// Get supply by ID
final supplyByIdProvider = FutureProvider.family<Supply?, int>((ref, id) async {
  final repository = ref.watch(supplyRepositoryProvider);
  return repository.getById(id);
});

// Low stock supplies
final lowStockSuppliesProvider = FutureProvider<List<Supply>>((ref) async {
  final repository = ref.watch(supplyRepositoryProvider);
  return repository.getLowStock();
});

// Expiring supplies
final expiringSuppliesProvider = FutureProvider<List<Supply>>((ref) async {
  final repository = ref.watch(supplyRepositoryProvider);
  return repository.getExpiring();
});

// Supply statistics
final supplyStatisticsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final repository = ref.watch(supplyRepositoryProvider);
  return repository.getStatistics();
});

// Supply search
final supplySearchQueryProvider = StateProvider<String>((ref) => '');

final searchedSuppliesProvider = Provider<AsyncValue<List<Supply>>>((ref) {
  final searchQuery = ref.watch(supplySearchQueryProvider);
  final supplies = ref.watch(supplyListProvider);

  return supplies.whenData((supplyList) {
    if (searchQuery.isEmpty) {
      return supplyList;
    }

    return supplyList.where((supply) {
      final searchLower = searchQuery.toLowerCase();
      return supply.name.toLowerCase().contains(searchLower) ||
          (supply.brand?.toLowerCase().contains(searchLower) ?? false) ||
          (supply.size?.toLowerCase().contains(searchLower) ?? false) ||
          supply.category.displayName.toLowerCase().contains(searchLower);
    }).toList();
  });
});

// Supply category filter
final supplyCategoryFilterProvider = StateProvider<SupplyCategory?>((ref) => null);

final filteredSuppliesProvider = Provider<AsyncValue<List<Supply>>>((ref) {
  final categoryFilter = ref.watch(supplyCategoryFilterProvider);
  final searchedSupplies = ref.watch(searchedSuppliesProvider);

  return searchedSupplies.whenData((supplyList) {
    if (categoryFilter == null) {
      return supplyList;
    }

    return supplyList.where((supply) => supply.category == categoryFilter).toList();
  });
});
