import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dosifi_flutter/data/models/medication.dart';
import 'package:dosifi_flutter/presentation/providers/medication_provider.dart';
import 'package:dosifi_flutter/presentation/providers/medication_layout_provider.dart';
import 'package:dosifi_flutter/presentation/widgets/medication_card.dart';
import 'package:dosifi_flutter/core/widgets/info_sheet.dart';

class MedicationsListScreen extends ConsumerStatefulWidget {
  const MedicationsListScreen({super.key});

  @override
  ConsumerState<MedicationsListScreen> createState() => _MedicationsListScreenState();
}

class _MedicationsListScreenState extends ConsumerState<MedicationsListScreen> {
  String _searchQuery = '';
  MedicationType? _selectedType;
  bool _showLowStockOnly = false;
  bool _showExpiringSoon = false;
  bool _showSearchField = false;

  // Sorting (default: Name)
  SortOption _sortOption = SortOption.name;
  bool _sortAsc = true;

  // No auto-hide controls

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _onUserInteracted() {}

  @override
  Widget build(BuildContext context) {
    final medicationsAsync = ref.watch(medicationListProvider);

    return Scaffold(
      body: Column(
            children: [
              // Top controls: Sort + Filter + Info
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
                child: Row(
                  children: [
                    // Info on the left
                    IconButton(
                      tooltip: 'About this screen',
                      onPressed: () {
                        _onUserInteracted();
                        InfoSheet.show(
                          context,
                          title: 'Medications',
                          message: 'Search\n\nTap the magnifier to show the search bar. Type to filter by medication name or brand.\n\nSort\n\nTap the sort button to flip A–Z and Z–A. Long-press the sort button to choose the sort field (Name, Stock, Type, Expiry).\n\nTips\n\nTap a medication card for full details.',
                        );
                      },
                      icon: const Icon(Icons.info_outline),
                      style: Theme.of(context).iconButtonTheme.style,
                    ),
                    const SizedBox(width: 6),
                    // Search button next
                    IconButton(
                      tooltip: _showSearchField ? 'Hide search' : 'Show search',
                      onPressed: () {
                        setState(() {
                          _showSearchField = !_showSearchField;
                        });
                        _onUserInteracted();
                      },
                      icon: Icon(_showSearchField ? Icons.close : Icons.search),
                      style: Theme.of(context).iconButtonTheme.style,
                    ),
                    const Spacer(),
                    // Sort button on the right
                    _buildSortButton(context),
                  ],
                ),
              ),

              // Optional inline search bar
              if (_showSearchField)
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 4),
                  child: _buildSearchField(context),
                ),

              // Medications List
              Expanded(
                child: medicationsAsync.when(
                  data: (medications) {
                    List<Medication> filteredMedications = _filterMedications(medications);
                    filteredMedications = _applySort(filteredMedications);

                    if (filteredMedications.isEmpty) {
                      return _buildEmptyState();
                    }

                    final layout = ref.watch(medicationLayoutProvider);
                    return ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                      itemCount: filteredMedications.length,
                      itemBuilder: (context, index) {
                        final medication = filteredMedications[index];
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            MedicationCard(
                              medication: medication,
                              forceLayout: layout,
                              onTap: () => context.push('/medications/${medication.id}'),
                            ),
                            const SizedBox(height: 8),
                          ],
                        );
                      },
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (error, stack) => Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error, size: 64, color: Colors.red),
                        const SizedBox(height: 16),
                        Text('Error: $error'),
                        const SizedBox(height: 16),
                        ElevatedButton(onPressed: () => ref.refresh(medicationListProvider), child: const Text('Retry')),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/medications/add'),
        child: const Icon(Icons.add),
      ),
    );
  }

  List<Medication> _filterMedications(List<Medication> medications) {
    return medications.where((medication) {
      // Search filter
      final matchesSearch =
          _searchQuery.isEmpty ||
          medication.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (medication.brandManufacturer?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);

      // Type filter
      final matchesType = _selectedType == null || medication.type == _selectedType;

      // Low stock filter
      final matchesLowStock = !_showLowStockOnly || medication.isLowStock;

      // Expiring soon filter
      final matchesExpiring = !_showExpiringSoon || medication.isExpiringSoon;

      return matchesSearch && matchesType && matchesLowStock && matchesExpiring;
    }).toList();
  }

  // Deprecated: replaced by MedicationCard to support multiple styles.
  // Keeping helper functions below for icon/color mapping as they are still used.

  Widget _buildDetailItem(String label, String value, IconData icon) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.grey[600]),
        const SizedBox(width: 4),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(color: Colors.grey[600], fontWeight: FontWeight.w500),
              ),
              Text(
                value,
                style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.medication_outlined, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No medications found',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text('Add your first medication to get started', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[500])),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => context.push('/medications/add'),
            icon: const Icon(Icons.add),
            label: const Text('Add Medication'),
          ),
        ],
      ),
    );
  }

  // Search field
  Widget _buildSearchField(BuildContext context) {
    return TextField(
      decoration: InputDecoration(
        hintText: 'Search medications...',
        prefixIcon: const Icon(Icons.search),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
      onTap: _onUserInteracted,
      onChanged: (val) {
        _onUserInteracted();
        setState(() => _searchQuery = val.trim());
      },
    );
  }

  // Sorting helpers and UI
  List<Medication> _applySort(List<Medication> meds) {
    switch (_sortOption) {
      case SortOption.name:
        meds.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
        break;
      case SortOption.stock:
        meds.sort((a, b) => b.stockQuantity.compareTo(a.stockQuantity));
        break;
      case SortOption.type:
        meds.sort((a, b) => a.type.displayName.compareTo(b.type.displayName));
        break;
      case SortOption.expiry:
        meds.sort((a, b) {
          final aDate = a.expirationDate ?? DateTime(9999);
          final bDate = b.expirationDate ?? DateTime(9999);
          return aDate.compareTo(bDate);
        });
        break;
    }
    if (!_sortAsc) {
      meds = meds.reversed.toList();
    }
    return meds;
  }

  String _currentSortLabel() {
    String field;
    switch (_sortOption) {
      case SortOption.name:
        field = 'Name';
        break;
      case SortOption.stock:
        field = 'Stock';
        break;
      case SortOption.type:
        field = 'Type';
        break;
      case SortOption.expiry:
        field = 'Expiry';
        break;
    }
    final dir = _sortAsc ? 'A–Z' : 'Z–A';
    return '$field $dir';
  }

  Widget _buildSortButton(BuildContext context) {
    return GestureDetector(
      onLongPressStart: (details) async {
        final overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
        final position = RelativeRect.fromLTRB(
          details.globalPosition.dx,
          details.globalPosition.dy,
          overlay.size.width - details.globalPosition.dx,
          overlay.size.height - details.globalPosition.dy,
        );
        final selected = await showMenu<SortOption>(
          context: context,
          position: position,
          items: const [
            PopupMenuItem(value: SortOption.name, child: Text('Name')),
            PopupMenuItem(value: SortOption.stock, child: Text('Stock')),
            PopupMenuItem(value: SortOption.type, child: Text('Type')),
            PopupMenuItem(value: SortOption.expiry, child: Text('Expiry')),
          ],
        );
        if (selected != null) {
          setState(() {
            if (selected == _sortOption) {
              _sortAsc = !_sortAsc; // same field toggles direction
            } else {
              _sortOption = selected;
              _sortAsc = true; // reset to asc when changing field
            }
          });
        }
      },
      child: OutlinedButton.icon(
        onPressed: () {
          // Toggle sort direction on tap
          setState(() {
            _sortAsc = !_sortAsc;
          });
        },
        icon: Icon(
          _sortAsc ? Icons.arrow_upward : Icons.arrow_downward,
          size: 16,
          color: Colors.grey.shade700,
        ),
        label: Text(
          _currentSortLabel(),
          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey.shade800),
        ),
        style: OutlinedButton.styleFrom(
          visualDensity: VisualDensity.compact,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          backgroundColor: Colors.grey.shade50,
          foregroundColor: Colors.grey.shade800,
          side: BorderSide(color: Colors.grey.shade300),
          shape: const StadiumBorder(),
        ),
      ),
    );
  }

  // Filter dialog removed per simplified UI
  void _showFilterDialog() {
    // Intentionally left blank / deprecated
  }

  Color _getMedicationTypeColor(MedicationType type) {
    switch (type) {
      case MedicationType.tablet:
        return Colors.blue;
      case MedicationType.capsule:
        return Colors.green;
      case MedicationType.liquid:
        return Colors.cyan;
      case MedicationType.preFilledSyringe:
      case MedicationType.readyMadeVial:
        return Colors.purple;
      case MedicationType.lyophilizedVial:
        return Colors.indigo;
      case MedicationType.cream:
      case MedicationType.ointment:
        return Colors.orange;
      case MedicationType.drops:
        return Colors.lightBlue;
      case MedicationType.inhaler:
        return Colors.teal;
      case MedicationType.patch:
        return Colors.amber;
      case MedicationType.suppository:
        return Colors.pink;
      case MedicationType.singleUsePen:
      case MedicationType.multiUsePen:
        return Colors.deepPurple;
      case MedicationType.spray:
        return Colors.lime;
      case MedicationType.gel:
        return Colors.lightGreen;
      case MedicationType.other:
        return Colors.grey;
    }
  }

  IconData _getMedicationTypeIcon(MedicationType type) {
    switch (type) {
      case MedicationType.tablet:
      case MedicationType.capsule:
        return Icons.medication;
      case MedicationType.liquid:
      case MedicationType.drops:
        return Icons.water_drop;
      case MedicationType.preFilledSyringe:
      case MedicationType.readyMadeVial:
      case MedicationType.lyophilizedVial:
        return Icons.vaccines;
      case MedicationType.cream:
      case MedicationType.ointment:
      case MedicationType.gel:
        return Icons.healing;
      case MedicationType.inhaler:
        return Icons.air;
      case MedicationType.patch:
        return Icons.medical_services;
      case MedicationType.suppository:
        return Icons.medication_liquid;
      case MedicationType.singleUsePen:
      case MedicationType.multiUsePen:
        return Icons.colorize;
      case MedicationType.spray:
        return Icons.water_damage;
      case MedicationType.other:
        return Icons.medical_information;
    }
  }

    final now = DateTime.now();
    final difference = date.difference(now).inDays;

    if (difference < 0) {
      return '${(-difference)} days ago';
    } else if (difference == 0) {
      return 'Today';
    } else if (difference == 1) {
      return 'Tomorrow';
    } else if (difference < 30) {
      return 'In $difference days';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [const Icon(Icons.info_outline), const SizedBox(width: 8), Text(title, style: Theme.of(context).textTheme.titleMedium)]),
            const SizedBox(height: 12),
            Text(message),
          ],
        ),
      ),
    );
  }
}

enum SortOption { name, stock, type, expiry }
