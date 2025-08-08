import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dosifi_flutter/data/models/supply.dart';
import 'package:dosifi_flutter/presentation/providers/supply_provider.dart';

class SuppliesScreen extends ConsumerStatefulWidget {
  const SuppliesScreen({super.key});

  @override
  ConsumerState<SuppliesScreen> createState() => _SuppliesScreenState();
}

class _SuppliesScreenState extends ConsumerState<SuppliesScreen> {
  String _searchQuery = '';
  SupplyType? _filterType;
  bool _isSearchExpanded = false;

  @override
  Widget build(BuildContext context) {
    final suppliesAsync = ref.watch(supplyListProvider);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Medical Supplies'),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        actions: [
          IconButton(
            icon: Icon(_isSearchExpanded ? Icons.search_off : Icons.search),
            onPressed: () {
              setState(() {
                _isSearchExpanded = !_isSearchExpanded;
                if (!_isSearchExpanded) {
                  _searchQuery = '';
                }
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          if (_isSearchExpanded) _buildSearchBar(),
          // Filter chips
          _buildFilterChips(),
          // Supplies list
          Expanded(
            child: _buildSuppliesList(suppliesAsync),
          ),
        ],
      ),
      floatingActionButton: _buildSuppliesFAB(),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16.0),
      child: TextField(
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
        },
        decoration: InputDecoration(
          hintText: 'Search supplies...',
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          filled: true,
          fillColor: Colors.grey[50],
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            FilterChip(
              label: const Text('All'),
              selected: _filterType == null,
              onSelected: (selected) {
                setState(() {
                  _filterType = null;
                });
              },
            ),
            const SizedBox(width: 8),
            ...SupplyType.values.map((type) {
              return Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: FilterChip(
                  label: Text(type.displayName),
                  selected: _filterType == type,
                  onSelected: (selected) {
                    setState(() {
                      _filterType = selected ? type : null;
                    });
                  },
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildSuppliesList(AsyncValue<List<Supply>> suppliesAsync) {
    return suppliesAsync.when(
      data: (supplies) {
        // Filter supplies based on search and type
        final filteredSupplies = supplies.where((supply) {
          final matchesSearch = _searchQuery.isEmpty ||
              supply.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              supply.type.displayName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              (supply.brand?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);
          final matchesType = _filterType == null || supply.type == _filterType;
          return matchesSearch && matchesType;
        }).toList();

        if (supplies.isEmpty) {
          return _buildEmptyState();
        }

        if (filteredSupplies.isEmpty) {
          return _buildNoResultsState();
        }

        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(supplyListProvider);
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: filteredSupplies.length,
            itemBuilder: (context, index) {
              final supply = filteredSupplies[index];
              return _buildSupplyCard(supply);
            },
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => _buildErrorState(error),
    );
  }

  Widget _buildSupplyCard(Supply supply) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      elevation: 2,
      child: InkWell(
        onTap: () => _showSupplyDetails(supply),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _getTypeColor(supply.type).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _getTypeIcon(supply.type),
                      color: _getTypeColor(supply.type),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          supply.displayName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: _getTypeColor(supply.type),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                supply.type.displayName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            if (supply.brand != null) ...[
                              const SizedBox(width: 8),
                              Text(
                                supply.brand!,
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  _buildStockIndicator(supply),
                ],
              ),
              const SizedBox(height: 16),
              _buildSupplyDetails(supply),
              if (supply.isLowStock || supply.isExpiringSoon || supply.isExpired)
                _buildAlerts(supply),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStockIndicator(Supply supply) {
    Color stockColor = Colors.green;
    String stockText = 'In Stock';
    IconData stockIcon = Icons.check_circle;

    if (supply.isExpired) {
      stockColor = Colors.red;
      stockText = 'Expired';
      stockIcon = Icons.error;
    } else if (supply.isLowStock) {
      stockColor = Colors.orange;
      stockText = 'Low Stock';
      stockIcon = Icons.warning;
    } else if (supply.isExpiringSoon) {
      stockColor = Colors.amber;
      stockText = 'Expiring Soon';
      stockIcon = Icons.schedule;
    }

    return Column(
      children: [
        Icon(
          stockIcon,
          color: stockColor,
          size: 20,
        ),
        const SizedBox(height: 4),
        Text(
          '${supply.quantity}',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: stockColor,
            fontSize: 16,
          ),
        ),
        Text(
          supply.effectiveUnit,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildSupplyDetails(Supply supply) {
    return Row(
      children: [
        Expanded(
          child: _buildDetailItem(
            Icons.inventory_2_outlined,
            'Quantity',
            '${supply.quantity} ${supply.effectiveUnit}',
          ),
        ),
        if (supply.reorderLevel != null)
          Expanded(
            child: _buildDetailItem(
              Icons.notification_important_outlined,
              'Reorder at',
              '${supply.reorderLevel} ${supply.effectiveUnit}',
            ),
          ),
        if (supply.expirationDate != null)
          Expanded(
            child: _buildDetailItem(
              Icons.schedule_outlined,
              'Expires',
              _formatDate(supply.expirationDate!),
            ),
          ),
        if (supply.location != null)
          Expanded(
            child: _buildDetailItem(
              Icons.location_on_outlined,
              'Location',
              supply.location!,
            ),
          ),
      ],
    );
  }

  Widget _buildDetailItem(IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(
          icon,
          size: 16,
          color: Colors.grey[600],
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildAlerts(Supply supply) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.amber[50],
        border: Border.all(color: Colors.amber[200]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            Icons.warning,
            color: Colors.amber[700],
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _getAlertMessage(supply),
              style: TextStyle(
                color: Colors.amber[700],
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getAlertMessage(Supply supply) {
    final alerts = <String>[];
    if (supply.isExpired) alerts.add('Expired');
    if (supply.isLowStock) alerts.add('Low stock');
    if (supply.isExpiringSoon) alerts.add('Expiring soon');
    return alerts.join(', ');
  }

  Widget _buildNoResultsState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No supplies found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your search or filters',
            style: TextStyle(
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.inventory_2_outlined, size: 64),
          const SizedBox(height: 16),
          const Text('No Supplies Added'),
          const SizedBox(height: 8),
          const Text('Tap the add button to add your first supply'),
        ],
      ),
    );
  }

  Widget _buildErrorState(Object error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64),
          const SizedBox(height: 16),
          const Text('Error loading supplies'),
          const SizedBox(height: 8),
          Text(error.toString()),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => ref.invalidate(supplyListProvider),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildSuppliesFAB() {
    return FloatingActionButton.extended(
      onPressed: _showAddMenu,
      icon: const Icon(Icons.add),
      label: const Text('Add'),
    );
  }

  void _showSearchDialog() {
    // Implement search dialog
  }

  void _showAddMenu() {
    context.go('/supplies/add');
  }

  void _showSupplyDetails(Supply supply) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) => _buildSupplyDetailsSheet(supply, scrollController),
      ),
    );
  }

  Widget _buildSupplyDetailsSheet(Supply supply, ScrollController scrollController) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: ListView(
        controller: scrollController,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _getTypeColor(supply.type).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _getTypeIcon(supply.type),
                  color: _getTypeColor(supply.type),
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      supply.displayName,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: _getTypeColor(supply.type),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        supply.type.displayName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => context.go('/supplies/edit/${supply.id}'),
                icon: const Icon(Icons.edit),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.blue[50],
                  foregroundColor: Colors.blue[700],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Stock Status
          _buildInfoCard('Stock Information', [
            _buildInfoRow('Current Quantity', '${supply.quantity} ${supply.effectiveUnit}'),
            if (supply.reorderLevel != null)
              _buildInfoRow('Reorder Level', '${supply.reorderLevel} ${supply.effectiveUnit}'),
          ]),
          
          const SizedBox(height: 16),
          
          // Details
          _buildInfoCard('Details', [
            if (supply.brand != null) _buildInfoRow('Brand', supply.brand!),
            if (supply.size != null) _buildInfoRow('Size', supply.size!),
            if (supply.lotNumber != null) _buildInfoRow('Lot Number', supply.lotNumber!),
          ]),
          
          const SizedBox(height: 16),
          
          // Storage & Expiration
          _buildInfoCard('Storage & Expiration', [
            if (supply.location != null) _buildInfoRow('Location', supply.location!),
            if (supply.expirationDate != null)
              _buildInfoRow('Expiration Date', _formatDate(supply.expirationDate!)),
          ]),
          
          if (supply.notes != null) ...[
            const SizedBox(height: 16),
            _buildInfoCard('Notes', [
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  supply.notes!,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                  ),
                ),
              ),
            ]),
          ],
          
          const SizedBox(height: 24),
          
          // Action buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    context.go('/supplies/edit/${supply.id}');
                  },
                  icon: const Icon(Icons.edit),
                  label: const Text('Edit'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _showQuantityUpdateDialog(supply),
                  icon: const Icon(Icons.add_box),
                  label: const Text('Update Stock'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(String title, List<Widget> children) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showQuantityUpdateDialog(Supply supply) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update Stock'),
        content: const Text('Stock update functionality coming soon!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Color _getTypeColor(SupplyType type) {
    switch (type) {
      case SupplyType.item:
        return Colors.blue;
      case SupplyType.fluid:
        return Colors.teal;
      case SupplyType.diluent:
        return Colors.purple;
    }
  }

  IconData _getTypeIcon(SupplyType type) {
    switch (type) {
      case SupplyType.item:
        return Icons.inventory_2;
      case SupplyType.fluid:
        return Icons.water_drop;
      case SupplyType.diluent:
        return Icons.science;
    }
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}
