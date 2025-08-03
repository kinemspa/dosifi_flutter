import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/supply.dart';
import '../../data/repositories/supply_repository.dart';

// Repository provider
final supplyRepositoryProvider = Provider<SupplyRepository>((ref) {
  return SupplyRepository();
});

// State notifier for managing supplies
class SupplyListNotifier extends StateNotifier<AsyncValue<List<Supply>>> {
  final SupplyRepository _repository;

  SupplyListNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadSupplies();
  }

  Future<void> loadSupplies() async {
    state = const AsyncValue.loading();
    try {
      final supplies = await _repository.getAllSupplies();
      state = AsyncValue.data(supplies);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> addSupply(Supply supply) async {
    try {
      final id = await _repository.insertSupply(supply);
      final newSupply = supply.copyWith(id: id);
      
      state.whenData((supplies) {
        state = AsyncValue.data([...supplies, newSupply]);
      });
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> updateSupply(Supply supply) async {
    try {
      await _repository.updateSupply(supply);
      
      state.whenData((supplies) {
        final updatedList = supplies.map((s) {
          return s.id == supply.id ? supply : s;
        }).toList();
        state = AsyncValue.data(updatedList);
      });
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> deleteSupply(int id) async {
    try {
      await _repository.deleteSupply(id);
      
      state.whenData((supplies) {
        final updatedList = supplies.where((s) => s.id != id).toList();
        state = AsyncValue.data(updatedList);
      });
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> updateQuantity(int id, int newQuantity) async {
    try {
      await _repository.updateQuantity(id, newQuantity);
      
      state.whenData((supplies) {
        final updatedList = supplies.map((s) {
          if (s.id == id) {
            return s.copyWith(quantity: newQuantity);
          }
          return s;
        }).toList();
        state = AsyncValue.data(updatedList);
      });
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> adjustQuantity(int id, int adjustment) async {
    try {
      await _repository.adjustQuantity(id, adjustment);
      
      state.whenData((supplies) {
        final updatedList = supplies.map((s) {
          if (s.id == id) {
            final newQuantity = (s.quantity + adjustment).clamp(0, double.infinity).toInt();
            return s.copyWith(quantity: newQuantity);
          }
          return s;
        }).toList();
        state = AsyncValue.data(updatedList);
      });
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}

// Provider for the supply list state notifier
final supplyListProvider = 
    StateNotifierProvider<SupplyListNotifier, AsyncValue<List<Supply>>>((ref) {
  final repository = ref.watch(supplyRepositoryProvider);
  return SupplyListNotifier(repository);
});

// Provider for getting supply by ID
final supplyByIdProvider = FutureProvider.family<Supply?, int>((ref, id) async {
  final repository = ref.watch(supplyRepositoryProvider);
  return await repository.getSupplyById(id);
});

// Provider for getting supplies by category
final suppliesByCategoryProvider = FutureProvider.family<List<Supply>, SupplyCategory>((ref, category) async {
  final repository = ref.watch(supplyRepositoryProvider);
  return await repository.getSuppliesByCategory(category);
});

// Provider for low stock supplies
final lowStockSuppliesProvider = Provider<AsyncValue<List<Supply>>>((ref) {
  final allSupplies = ref.watch(supplyListProvider);
  
  return allSupplies.whenData((supplies) {
    return supplies.where((supply) => supply.isLowStock).toList();
  });
});

// Provider for expiring supplies (within 30 days)
final expiringSuppliesProvider = Provider<AsyncValue<List<Supply>>>((ref) {
  final allSupplies = ref.watch(supplyListProvider);
  
  return allSupplies.whenData((supplies) {
    return supplies.where((supply) => supply.isExpiringSoon).toList();
  });
});

// Provider for expired supplies
final expiredSuppliesProvider = Provider<AsyncValue<List<Supply>>>((ref) {
  final allSupplies = ref.watch(supplyListProvider);
  
  return allSupplies.whenData((supplies) {
    return supplies.where((supply) => supply.isExpired).toList();
  });
});

// Provider for supply statistics
final supplyStatsProvider = Provider<Map<String, dynamic>>((ref) {
  final suppliesAsync = ref.watch(supplyListProvider);
  
  return suppliesAsync.maybeWhen(
    data: (supplies) {
      final totalSupplies = supplies.length;
      final lowStockSupplies = supplies.where((s) => s.isLowStock).length;
      final expiringSupplies = supplies.where((s) => s.isExpiringSoon).length;
      final expiredSupplies = supplies.where((s) => s.isExpired).length;
      
      return {
        'total': totalSupplies,
        'lowStock': lowStockSupplies,
        'expiring': expiringSupplies,
        'expired': expiredSupplies,
      };
    },
    orElse: () => {
      'total': 0,
      'lowStock': 0,
      'expiring': 0,
      'expired': 0,
    },
  );
});

// Provider for searching supplies
final supplySearchProvider = FutureProvider.family<List<Supply>, String>((ref, query) async {
  if (query.isEmpty) {
    final allSupplies = ref.watch(supplyListProvider);
    return allSupplies.maybeWhen(
      data: (supplies) => supplies,
      orElse: () => <Supply>[],
    );
  }
  
  final repository = ref.watch(supplyRepositoryProvider);
  return await repository.searchSupplies(query);
});
