import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/inventory.dart';
import '../../data/repositories/inventory_repository.dart';

// Repository provider
final inventoryRepositoryProvider = Provider<InventoryRepository>((ref) {
  return InventoryRepository();
});

// State notifier for managing inventory
class InventoryListNotifier extends StateNotifier<AsyncValue<List<Inventory>>> {
  final InventoryRepository _repository;

  InventoryListNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadInventory();
  }

  Future<void> loadInventory() async {
    state = const AsyncValue.loading();
    try {
      final inventory = await _repository.getAllInventory();
      state = AsyncValue.data(inventory);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> addInventory(Inventory inventory) async {
    try {
      final id = await _repository.insertInventory(inventory);
      final newInventory = inventory.copyWith(id: id);
      
      state.whenData((inventoryList) {
        state = AsyncValue.data([...inventoryList, newInventory]);
      });
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> updateInventory(Inventory inventory) async {
    try {
      await _repository.updateInventory(inventory);
      
      state.whenData((inventoryList) {
        final updatedList = inventoryList.map((inv) {
          return inv.id == inventory.id ? inventory : inv;
        }).toList();
        state = AsyncValue.data(updatedList);
      });
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> deleteInventory(int id) async {
    try {
      await _repository.deleteInventory(id);
      
      state.whenData((inventoryList) {
        final updatedList = inventoryList.where((inv) => inv.id != id).toList();
        state = AsyncValue.data(updatedList);
      });
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> updateQuantity(int id, double newQuantity) async {
    try {
      await _repository.updateQuantity(id, newQuantity);
      
      state.whenData((inventoryList) {
        final updatedList = inventoryList.map((inv) {
          if (inv.id == id) {
            return inv.copyWith(quantity: newQuantity);
          }
          return inv;
        }).toList();
        state = AsyncValue.data(updatedList);
      });
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> adjustQuantity(int id, double adjustment) async {
    try {
      final inventory = state.value?.firstWhere((inv) => inv.id == id);
      if (inventory != null) {
        final newQuantity = inventory.quantity + adjustment;
        if (newQuantity >= 0) {
          await updateQuantity(id, newQuantity);
        }
      }
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}

// Provider for the inventory list state notifier
final inventoryListProvider = 
    StateNotifierProvider<InventoryListNotifier, AsyncValue<List<Inventory>>>((ref) {
  final repository = ref.watch(inventoryRepositoryProvider);
  return InventoryListNotifier(repository);
});

// Provider for getting inventory by medication
final inventoryByMedicationProvider = FutureProvider.family<List<Inventory>, int>((ref, medicationId) async {
  final repository = ref.watch(inventoryRepositoryProvider);
  return await repository.getInventoryByMedication(medicationId);
});

// Provider for low stock items
final lowStockInventoryProvider = Provider<AsyncValue<List<Inventory>>>((ref) {
  final allInventory = ref.watch(inventoryListProvider);
  
  return allInventory.whenData((inventory) {
    return inventory.where((inv) {
      return inv.reorderLevel != null && inv.quantity <= inv.reorderLevel!;
    }).toList();
  });
});

// Provider for expiring items (within 30 days)
final expiringInventoryProvider = Provider<AsyncValue<List<Inventory>>>((ref) {
  final allInventory = ref.watch(inventoryListProvider);
  
  return allInventory.whenData((inventory) {
    final thirtyDaysFromNow = DateTime.now().add(const Duration(days: 30));
    return inventory.where((inv) {
      return inv.expiryDate != null && 
             inv.expiryDate!.isBefore(thirtyDaysFromNow) &&
             inv.expiryDate!.isAfter(DateTime.now());
    }).toList();
  });
});

// Provider for expired items
final expiredInventoryProvider = Provider<AsyncValue<List<Inventory>>>((ref) {
  final allInventory = ref.watch(inventoryListProvider);
  
  return allInventory.whenData((inventory) {
    return inventory.where((inv) {
      return inv.expiryDate != null && inv.expiryDate!.isBefore(DateTime.now());
    }).toList();
  });
});

// Provider for total inventory value (count)
final totalInventoryCountProvider = Provider<int>((ref) {
  final inventoryAsync = ref.watch(inventoryListProvider);
  return inventoryAsync.maybeWhen(
    data: (inventory) => inventory.length,
    orElse: () => 0,
  );
});

// Provider for inventory statistics
final inventoryStatsProvider = Provider<Map<String, dynamic>>((ref) {
  final inventoryAsync = ref.watch(inventoryListProvider);
  
  return inventoryAsync.maybeWhen(
    data: (inventory) {
      final totalItems = inventory.length;
      final lowStockItems = inventory.where((inv) => 
        inv.reorderLevel != null && inv.quantity <= inv.reorderLevel!
      ).length;
      final expiringItems = inventory.where((inv) {
        if (inv.expiryDate == null) return false;
        final thirtyDaysFromNow = DateTime.now().add(const Duration(days: 30));
        return inv.expiryDate!.isBefore(thirtyDaysFromNow) && 
               inv.expiryDate!.isAfter(DateTime.now());
      }).length;
      final expiredItems = inventory.where((inv) => 
        inv.expiryDate != null && inv.expiryDate!.isBefore(DateTime.now())
      ).length;
      
      return {
        'total': totalItems,
        'lowStock': lowStockItems,
        'expiring': expiringItems,
        'expired': expiredItems,
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
