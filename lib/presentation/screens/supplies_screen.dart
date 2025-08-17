import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dosifi_flutter/data/models/supply.dart';
import 'package:dosifi_flutter/presentation/providers/supply_provider.dart';
import 'package:dosifi_flutter/core/widgets/compact_card.dart';
import 'package:dosifi_flutter/core/widgets/label_chip.dart';
import 'package:dosifi_flutter/core/utils/compact_form_sheet.dart';
import 'package:dosifi_flutter/presentation/screens/add_supply_screen.dart';
import 'package:dosifi_flutter/presentation/providers/supply_layout_provider.dart';
import 'package:intl/intl.dart';
import 'package:dosifi_flutter/core/widgets/info_sheet.dart';

class SuppliesScreen extends ConsumerStatefulWidget {
  const SuppliesScreen({super.key});

  @override
  ConsumerState<SuppliesScreen> createState() => _SuppliesScreenState();
}

class _SuppliesScreenState extends ConsumerState<SuppliesScreen> {
  String _searchQuery = '';
  SupplyType? _filterType;
  bool _isSearchExpanded = false;

  // Sorting
  SupplySortOption _sortOption = SupplySortOption.name;
  bool _ascending = true;

  // Demo style switch for segmented sort
  _SupSortStyle _style = _SupSortStyle.tonal;

  @override
  Widget build(BuildContext context) {
    final suppliesAsync = ref.watch(supplyListProvider);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      // No AppBar here; we follow the Medications screen pattern with inline header controls
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
            child: Row(
              children: [
                IconButton(
                  tooltip: 'About this screen',
                  onPressed: () {
                    InfoSheet.show(
                      context,
                      title: 'Supplies',
                      message:
                          'Search\n\nTap the magnifier to show the search bar. Type to filter by supply name or brand.\n\nSort\n\nUse the left arrow to flip A–Z and Z–A. Tap the Sort button to choose the field (Name, Quantity, Type, Expiry).',
                    );
                  },
                  icon: const Icon(Icons.info_outline),
                ),
                const SizedBox(width: 6),
                IconButton(
                  tooltip: _isSearchExpanded ? 'Hide search' : 'Show search',
                  onPressed: () {
                    setState(() {
                      _isSearchExpanded = !_isSearchExpanded;
                      if (!_isSearchExpanded) _searchQuery = '';
                    });
                  },
                  icon: Icon(_isSearchExpanded ? Icons.close : Icons.search),
                ),
                const Spacer(),
                _buildSortControl(context),
              ],
            ),
          ),
          // Search bar
          if (_isSearchExpanded) _buildSearchBar(),
          // Supplies list
          Expanded(child: _buildSuppliesList(suppliesAsync)),
        ],
      ),
      floatingActionButton: _buildSuppliesFAB(),
    );
  }

  Widget _buildSortControl(BuildContext context) {
    final String label = () {
      switch (_sortOption) {
        case SupplySortOption.name:
          return 'Name';
        case SupplySortOption.quantity:
          return 'Quantity';
        case SupplySortOption.type:
          return 'Type';
        case SupplySortOption.expiry:
          return 'Expiry';
      }
    }();

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.only(right: 6.0),
          child: SizedBox(
            height: 32,
            width: 36,
            child: FilledButton.tonal(
              style: const ButtonStyle(
                padding: WidgetStatePropertyAll(EdgeInsets.zero),
                visualDensity: VisualDensity.compact,
              ),
              onPressed: () {
                setState(() => _ascending = !_ascending);
              },
              child: Icon(
                _ascending ? Icons.arrow_upward : Icons.arrow_downward,
                size: 16,
              ),
            ),
          ),
        ),
        PopupMenuButton<SupplySortOption>(
          tooltip: 'Sort field',
          onSelected: (chosen) {
            setState(() => _sortOption = chosen);
          },
          itemBuilder: (context) => const [
            PopupMenuItem(value: SupplySortOption.name, child: Text('Name')),
            PopupMenuItem(value: SupplySortOption.quantity, child: Text('Quantity')),
            PopupMenuItem(value: SupplySortOption.type, child: Text('Type')),
            PopupMenuItem(value: SupplySortOption.expiry, child: Text('Expiry')),
          ],
          child: FilledButton.tonal(
            style: const ButtonStyle(
              visualDensity: VisualDensity.compact,
              padding: WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 10)),
            ),
            onPressed: null,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.tune, size: 16),
                const SizedBox(width: 6),
                Text(label),
              ],
            ),
          ),
        ),
      ],
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

  Widget _buildSuppliesList(AsyncValue<List<Supply>> suppliesAsync) {
    return suppliesAsync.when(
      data: (supplies) {
        // Filter supplies based on search and type
        final filteredSupplies = supplies.where((supply) {
          final matchesSearch =
              _searchQuery.isEmpty ||
              supply.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              supply.type.displayName.toLowerCase().contains(
                _searchQuery.toLowerCase(),
              ) ||
              (supply.brand?.toLowerCase().contains(
                    _searchQuery.toLowerCase(),
                  ) ??
                  false);
          final matchesType = _filterType == null || supply.type == _filterType;
          return matchesSearch && matchesType;
        }).toList();

        if (supplies.isEmpty) {
          return _buildEmptyState();
        }

        if (filteredSupplies.isEmpty) {
          return _buildNoResultsState();
        }

        // Apply sorting
        final sorted = _applySort(filteredSupplies);

        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(supplyListProvider);
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: sorted.length,
            itemBuilder: (context, index) {
              final supply = sorted[index];
              final layout = ref.watch(supplyLayoutProvider);
              return _buildSupplyCard(supply, layout);
            },
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => _buildErrorState(error),
    );
  }

  Widget _buildSupplyCard(Supply supply, SupplyCardLayout layout) {
    switch (layout) {
      case SupplyCardLayout.outlinedClassic:
        return _supplyOutlinedClassic(supply);
      case SupplyCardLayout.outlinedSoft:
        return _supplyOutlinedSoft(supply);
      case SupplyCardLayout.outlinedShadow:
        return _supplyOutlinedShadow(supply);
      case SupplyCardLayout.outlinedAccentBar:
        return _supplyOutlinedAccentBar(supply);
      case SupplyCardLayout.outlinedPill:
        return _supplyOutlinedPill(supply);
      case SupplyCardLayout.outlinedDense:
        return _supplyOutlinedDense(supply);
      case SupplyCardLayout.outlinedDivider:
        return _supplyOutlinedDivider(supply);
      case SupplyCardLayout.outlinedMonochrome:
        return _supplyOutlinedMonochrome(supply);
      case SupplyCardLayout.outlinedCompactChips:
        return _supplyOutlinedCompactChips(supply);
      case SupplyCardLayout.outlinedLargeTitle:
        return _supplyOutlinedLargeTitle(supply);
    }
  }

  Widget _supplyOutlinedClassic(Supply supply) {
    return CompactCard(
      accentColor: _getTypeColor(supply.type),
      onTap: () => _showSupplyDetails(supply),
      borderRadius: BorderRadius.circular(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: _getTypeColor(supply.type).withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _getTypeColor(supply.type).withValues(alpha: 0.2),
                    width: 0.8,
                  ),
                ),
                alignment: Alignment.center,
                child: Icon(
                  _getTypeIcon(supply.type),
                  color: _getTypeColor(supply.type),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            supply.displayName,
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(fontWeight: FontWeight.w700),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        LabelChip(
                          icon: Icons.category,
                          label: supply.type.displayName,
                          color: _getTypeColor(supply.type),
                        ),
                        if (supply.brand != null)
                          LabelChip(
                            icon: Icons.factory,
                            label: supply.brand!,
                            color: Colors.grey,
                          ),
                        if (supply.location != null)
                          LabelChip(
                            icon: Icons.location_on,
                            label: supply.location!,
                            color: Colors.teal,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${supply.quantity}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: supply.isExpired
                          ? Colors.red
                          : (supply.isLowStock
                                ? Colors.orange
                                : Colors.green.shade700),
                    ),
                  ),
                  Text(
                    supply.effectiveUnit,
                    style: Theme.of(
                      context,
                    ).textTheme.labelSmall?.copyWith(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 2),
                  const Icon(Icons.chevron_right, size: 18, color: Colors.grey),
                ],
              ),
            ],
          ),
          if (supply.isLowStock ||
              supply.isExpiringSoon ||
              supply.isExpired) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                if (supply.isExpired)
                  const LabelChip(
                    icon: Icons.error,
                    label: 'Expired',
                    color: Colors.red,
                  ),
                if (!supply.isExpired && supply.isExpiringSoon)
                  const LabelChip(
                    icon: Icons.schedule,
                    label: 'Expiring Soon',
                    color: Colors.amber,
                  ),
                if (supply.isLowStock)
                  const LabelChip(
                    icon: Icons.inventory_2,
                    label: 'Low Stock',
                    color: Colors.orange,
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _supplyOutlinedSoft(Supply supply) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300),
        color: Colors.white,
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: _getTypeColor(supply.type).withValues(alpha: 0.08),
            ),
            alignment: Alignment.center,
            child: Icon(
              _getTypeIcon(supply.type),
              color: _getTypeColor(supply.type),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  supply.displayName,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    LabelChip(
                      icon: Icons.category,
                      label: supply.type.displayName,
                      color: _getTypeColor(supply.type),
                    ),
                    if (supply.brand != null)
                      LabelChip(
                        icon: Icons.factory,
                        label: supply.brand!,
                        color: Colors.grey,
                      ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${supply.quantity}',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: supply.isLowStock
                      ? Colors.orange
                      : Colors.green.shade700,
                ),
              ),
              Text(
                supply.effectiveUnit,
                style: Theme.of(
                  context,
                ).textTheme.labelSmall?.copyWith(color: Colors.grey[600]),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _supplyOutlinedShadow(Supply supply) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: _supplyRowCore(supply),
    );
  }

  Widget _supplyOutlinedAccentBar(Supply supply) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _getTypeColor(supply.type).withValues(alpha: 0.35),
        ),
        color: Colors.white,
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 44,
            decoration: BoxDecoration(
              color: _getTypeColor(supply.type),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(child: _supplyRowCore(supply)),
        ],
      ),
    );
  }

  Widget _supplyOutlinedPill(Supply supply) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.grey.shade300),
        color: Colors.white,
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: _getTypeColor(supply.type).withValues(alpha: 0.10),
            child: Icon(
              _getTypeIcon(supply.type),
              size: 18,
              color: _getTypeColor(supply.type),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: _supplyTextBlock(supply)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: (supply.isLowStock ? Colors.orange : Colors.green)
                  .withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Text(
              '${supply.quantity} ${supply.effectiveUnit}',
              style: TextStyle(
                color: supply.isLowStock ? Colors.orange : Colors.green,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _supplyOutlinedDense(Supply supply) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300, width: 0.9),
        color: Colors.white,
      ),
      child: Row(
        children: [
          Icon(
            _getTypeIcon(supply.type),
            size: 18,
            color: _getTypeColor(supply.type),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${supply.displayName}  •  ${supply.type.displayName}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${supply.quantity} ${supply.effectiveUnit}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _supplyOutlinedDivider(Supply supply) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
        color: Colors.white,
      ),
      child: Row(
        children: [
          _supplyIconBox(supply),
          const SizedBox(width: 10),
          Expanded(child: _supplyTextBlock(supply)),
          Container(width: 1, height: 24, color: Colors.grey.shade300),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${supply.quantity}',
                style: Theme.of(
                  context,
                ).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
              if (supply.expirationDate != null)
                Text(
                  DateFormat('MMM yy').format(supply.expirationDate!),
                  style: Theme.of(
                    context,
                  ).textTheme.labelSmall?.copyWith(color: Colors.grey[600]),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _supplyOutlinedMonochrome(Supply supply) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
        color: Colors.white,
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: Colors.grey.shade100,
              border: Border.all(color: Colors.grey.shade300),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(child: _supplyTextBlock(supply, monochrome: true)),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${supply.quantity}',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: Colors.black87,
                ),
              ),
              Text(
                supply.effectiveUnit,
                style: Theme.of(
                  context,
                ).textTheme.labelSmall?.copyWith(color: Colors.grey[700]),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _supplyOutlinedCompactChips(Supply supply) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
        color: Colors.white,
      ),
      child: Row(
        children: [
          _supplyIconBox(supply),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        supply.displayName,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (supply.isLowStock)
                      const LabelChip(
                        icon: Icons.inventory_2,
                        label: 'Low',
                        color: Colors.orange,
                      ),
                    if (supply.isExpired)
                      const LabelChip(
                        icon: Icons.error,
                        label: 'Expired',
                        color: Colors.red,
                      ),
                    if (!supply.isExpired && supply.isExpiringSoon)
                      const LabelChip(
                        icon: Icons.warning,
                        label: 'Soon',
                        color: Colors.amber,
                      ),
                  ],
                ),
                const SizedBox(height: 2),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    LabelChip(
                      icon: Icons.category,
                      label: supply.type.displayName,
                      color: _getTypeColor(supply.type),
                    ),
                    if (supply.brand != null)
                      LabelChip(
                        icon: Icons.factory,
                        label: supply.brand!,
                        color: Colors.grey,
                      ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${supply.quantity}',
                style: Theme.of(
                  context,
                ).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
              Text(
                supply.effectiveUnit,
                style: Theme.of(
                  context,
                ).textTheme.labelSmall?.copyWith(color: Colors.grey[600]),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _supplyOutlinedLargeTitle(Supply supply) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
        color: Colors.white,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _supplyIconBox(supply, size: 48),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  supply.displayName,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${supply.type.displayName}${supply.brand != null ? ' • ${supply.brand}' : ''}',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: Colors.grey[700]),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${supply.quantity}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: supply.isLowStock ? Colors.orange : Colors.green,
                ),
              ),
              Text(
                supply.effectiveUnit,
                style: Theme.of(
                  context,
                ).textTheme.labelSmall?.copyWith(color: Colors.grey[600]),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _supplyRowCore(Supply supply) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _supplyIconBox(supply),
            const SizedBox(width: 12),
            Expanded(child: _supplyTextBlock(supply)),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${supply.quantity}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: supply.isLowStock
                        ? Colors.orange
                        : Colors.green.shade700,
                  ),
                ),
                Text(
                  supply.effectiveUnit,
                  style: Theme.of(
                    context,
                  ).textTheme.labelSmall?.copyWith(color: Colors.grey[600]),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 6),
        if (supply.reorderLevel != null) _buildSupplyProgressBar(supply),
      ],
    );
  }

  Widget _buildSupplyProgressBar(Supply supply) {
    final total = (supply.reorderLevel ?? 0).toDouble();
    // Use a soft denominator: display progress relative to 2x reorder level to leave headroom
    final denom = (total > 0 ? total * 2 : (supply.quantity + 1)).toDouble();
    final ratio = (supply.quantity.toDouble() / denom).clamp(0.0, 1.0);
    final color = supply.isLowStock ? Colors.orange : Colors.green;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${supply.quantity}/${supply.reorderLevel} ${supply.effectiveUnit}',
          style: Theme.of(
            context,
          ).textTheme.labelSmall?.copyWith(color: Colors.grey[600]),
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: ratio,
          backgroundColor: Colors.grey.withValues(alpha: 0.2),
          valueColor: AlwaysStoppedAnimation<Color>(color),
          minHeight: 4,
        ),
      ],
    );
  }

  Widget _supplyIconBox(Supply supply, {double size = 44}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: _getTypeColor(supply.type).withValues(alpha: 0.10),
        border: Border.all(
          color: _getTypeColor(supply.type).withValues(alpha: 0.2),
          width: 0.8,
        ),
      ),
      alignment: Alignment.center,
      child: Icon(
        _getTypeIcon(supply.type),
        color: _getTypeColor(supply.type),
        size: size * 0.45,
      ),
    );
  }

  Widget _supplyTextBlock(Supply supply, {bool monochrome = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          supply.displayName,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: monochrome ? Colors.black87 : null,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),
        Wrap(
          spacing: 6,
          runSpacing: 4,
          children: [
            LabelChip(
              icon: Icons.category,
              label: supply.type.displayName,
              color: monochrome ? Colors.grey : _getTypeColor(supply.type),
            ),
            if (supply.brand != null)
              LabelChip(
                icon: Icons.factory,
                label: supply.brand!,
                color: monochrome ? Colors.grey : Colors.grey,
              ),
            if (supply.location != null)
              LabelChip(
                icon: Icons.location_on,
                label: supply.location!,
                color: monochrome ? Colors.grey : Colors.teal,
              ),
          ],
        ),
      ],
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
        Icon(stockIcon, color: stockColor, size: 20),
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
          style: TextStyle(color: Colors.grey[600], fontSize: 12),
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
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
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
          Icon(Icons.warning, color: Colors.amber[700], size: 16),
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
          Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No supplies found',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.grey[600],
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your search or filters',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: Colors.grey[500]),
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
    return Tooltip(
      message: 'Add a new supply item',
      child: FloatingActionButton(
        onPressed: _showAddMenu,
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showSearchDialog() {
    // Implement search dialog
  }

  void _showAddMenu() {
    showCompactFormSheet(
      context,
      title: 'Add Supply',
      child: const AddSupplyScreen(compactSheetMode: true),
    );
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
        builder: (context, scrollController) =>
            _buildSupplyDetailsSheet(supply, scrollController),
      ),
    );
  }

  Widget _buildSupplyDetailsSheet(
    Supply supply,
    ScrollController scrollController,
  ) {
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
                  color: _getTypeColor(supply.type).withValues(alpha: 0.1),
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
                style: Theme.of(context).iconButtonTheme.style,
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Stock Status
          _buildInfoCard('Stock Information', [
            _buildInfoRow(
              'Current Quantity',
              '${supply.quantity} ${supply.effectiveUnit}',
            ),
            if (supply.reorderLevel != null)
              _buildInfoRow(
                'Reorder Level',
                '${supply.reorderLevel} ${supply.effectiveUnit}',
              ),
          ]),

          const SizedBox(height: 16),

          // Details
          _buildInfoCard('Details', [
            if (supply.brand != null) _buildInfoRow('Brand', supply.brand!),
            if (supply.size != null) _buildInfoRow('Size', supply.size!),
            if (supply.lotNumber != null)
              _buildInfoRow('Lot Number', supply.lotNumber!),
          ]),

          const SizedBox(height: 16),

          // Storage & Expiration
          _buildInfoCard('Storage & Expiration', [
            if (supply.location != null)
              _buildInfoRow('Location', supply.location!),
            if (supply.expirationDate != null)
              _buildInfoRow(
                'Expiration Date',
                _formatDate(supply.expirationDate!),
              ),
          ]),

          if (supply.notes != null) ...[
            const SizedBox(height: 16),
            _buildInfoCard('Notes', [
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  supply.notes!,
                  style: TextStyle(fontSize: 14, color: Colors.grey[700]),
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
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.surface,
            Theme.of(context).colorScheme.surface.withValues(alpha: 0.92),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.10),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(
              context,
            ).colorScheme.primary.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.primary.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      title,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ...children,
            ],
          ),
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
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500),
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
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}

enum SupplySortOption { name, quantity, type, expiry }

enum _SupSortStyle { tonal, outline }

enum _SupSortSeg { dir, field }

extension on _SuppliesScreenState {
  List<Supply> _applySort(List<Supply> list) {
    final supplies = [...list];
    switch (_sortOption) {
      case SupplySortOption.name:
        supplies.sort((a, b) => a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase()));
        break;
      case SupplySortOption.quantity:
        supplies.sort((a, b) => a.quantity.compareTo(b.quantity));
        break;
      case SupplySortOption.type:
        supplies.sort((a, b) => a.type.displayName.compareTo(b.type.displayName));
        break;
      case SupplySortOption.expiry:
        DateTime far = DateTime(9999);
        supplies.sort((a, b) => (a.expirationDate ?? far).compareTo(b.expirationDate ?? far));
        break;
    }
    if (!_ascending) {
      // Simple reverse
      supplies.setAll(0, supplies.reversed);
    }
    return supplies;
  }
}
