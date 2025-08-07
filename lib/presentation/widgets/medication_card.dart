import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../../data/models/medication.dart';
import '../providers/medication_layout_provider.dart';

extension MedicationExtensions on Medication {
  bool get isExpired {
    if (expirationDate == null) return false;
    return expirationDate!.isBefore(DateTime.now());
  }

  bool get isExpiringSoon {
    if (expirationDate == null) return false;
    final now = DateTime.now();
    final warningDate = now.add(const Duration(days: 30)); // 30 days warning
    return expirationDate!.isBefore(warningDate) && expirationDate!.isAfter(now);
  }

  String get stockDisplay {
    return '${stockQuantity.toStringAsFixed(0)} ${stockUnit?.displayName ?? ''}'.trim();
  }

  String get displayStrength {
    return '$strengthPerUnit${strengthUnit.displayName}';
  }
}

class MedicationCard extends StatelessWidget {
  final Medication medication;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final MedicationCardLayout? forceLayout;

  const MedicationCard({
    super.key,
    required this.medication,
    this.onTap,
    this.onEdit,
    this.onDelete,
    this.forceLayout,
  });

  @override
  Widget build(BuildContext context) {
    final layout = forceLayout ?? MedicationCardLayout.large;
    
    switch (layout) {
      case MedicationCardLayout.large:
        return _buildLargeCard(context);
      case MedicationCardLayout.compact:
        return _buildCompactCard(context);
      case MedicationCardLayout.tiles:
        return _buildTileCard(context);
    }
  }

  Widget _buildCompactCard(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.surface,
            Theme.of(context).colorScheme.surface.withOpacity(0.9),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: _getBorderColor(),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            if (medication.id != null) {
              context.push('/edit-medication/${medication.id}');
            }
            onTap?.call();
          },

          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                CircleAvatar(
                  backgroundColor: _getTypeColor().withOpacity(0.15),
                  radius: 24,
                  child: Icon(
                    _getTypeIcon(),
                    size: 20,
                    color: _getTypeColor(),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        medication.name,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${medication.displayStrength} • ${medication.type.displayName}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.secondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            'Stock: ${medication.stockDisplay}',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: _getStockColor(),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const Spacer(),
                          if (medication.expirationDate != null)
                            Text(
                              'Exp: ${DateFormat('MMM yy').format(medication.expirationDate!)}',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: _getExpiryColor(),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ..._buildCompactAlerts(),
                    ..._buildCompactStorageIndicators(),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTileCard(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 4,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            backgroundColor: Theme.of(context).colorScheme.primary,
            radius: 28,
            child: Icon(
              Icons.medication,
              color: Theme.of(context).colorScheme.onPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            medication.name,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildLargeCard(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.surface,
            Theme.of(context).colorScheme.surface.withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.12),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.05),
            blurRadius: 40,
            offset: const Offset(0, 16),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            if (medication.id != null) {
              context.push('/edit-medication/${medication.id}');
            }
            onTap?.call();
          },
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: _getTypeColor().withOpacity(0.3),
                    radius: 28,
                    child: Icon(
                      _getTypeIcon(),
                      size: 24,
                      color: _getTypeColor(),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          medication.name,
                          style: Theme.of(context).textTheme.titleMedium,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '${medication.type.displayName} - ${medication.strengthPerUnit}${medication.strengthUnit.displayName}',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.secondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: _handleMenuSelection,
                    itemBuilder: (context) => [
                      PopupMenuItem(value: 'edit', child: Text('Edit', style: TextStyle(color: Theme.of(context).colorScheme.primary))),
                      PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: Theme.of(context).colorScheme.error))),
                    ],
                  ),
                ],
              ),
              const Divider(height: 20),
              if (medication.brandManufacturer != null) ...[
                Text(
                  'Manufacturer: ${medication.brandManufacturer}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 4),
              ],
              Text(
                'Stock: ${medication.stockQuantity.toStringAsFixed(0)} ${medication.stockUnit?.displayName ?? ''}',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.secondary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              if (medication.expirationDate != null)
                Text(
                  'Expires: ${DateFormat('MMM dd, yyyy').format(medication.expirationDate!)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: medication.isExpired
                        ? Theme.of(context).colorScheme.error
                        : Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              const SizedBox(height: 4),
              if (medication.notes != null)
                Text(
                  'Notes: ${medication.notes}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              const SizedBox(height: 16),
              Row(
                children: [
                  if (medication.isExpired)
                    _buildAlertChip('Expired', Colors.red.shade100, Colors.red.shade800),
                  if (medication.isExpiringSoon)
                    _buildAlertChip('Expires Soon', Colors.orange.shade100, Colors.orange.shade800),
                  if (_isLowStock())
                    _buildAlertChip('Low Stock', Colors.amber.shade100, Colors.amber.shade800),
                  if (medication.requiresRefrigeration)
                    _buildAlertChip('Refrigerated', Colors.blue.shade100, Colors.blue.shade800),
                ],
              ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAlertChip(String label, Color bgColor, Color textColor) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: textColor,
        ),
      ),
    );
  }

  Widget _buildMedicationTypeLabel() {
    Color textColor;
    
    switch (medication.type) {
      case MedicationType.tablet:
      case MedicationType.capsule:
        textColor = Colors.blue.shade700;
        break;
      case MedicationType.preFilledSyringe:
      case MedicationType.readyMadeVial:
      case MedicationType.lyophilizedVial:
        textColor = Colors.red.shade700;
        break;
      case MedicationType.cream:
      case MedicationType.ointment:
        textColor = Colors.green.shade700;
        break;
      default:
        textColor = Colors.grey.shade700;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      child: Text(
        medication.type.displayName,
        style: TextStyle(
          color: textColor,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildMedicationTypeChip() {
    Color chipColor;
    Color textColor;
    
    switch (medication.type) {
      case MedicationType.tablet:
      case MedicationType.capsule:
        chipColor = Colors.blue.shade100;
        textColor = Colors.blue.shade800;
        break;
      case MedicationType.preFilledSyringe:
      case MedicationType.readyMadeVial:
      case MedicationType.lyophilizedVial:
        chipColor = Colors.red.shade100;
        textColor = Colors.red.shade800;
        break;
      case MedicationType.cream:
      case MedicationType.ointment:
        chipColor = Colors.green.shade100;
        textColor = Colors.green.shade800;
        break;
      default:
        chipColor = Colors.grey.shade200;
        textColor = Colors.grey.shade800;
    }
    
    return Chip(
      label: Text(
        medication.type.displayName,
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
      backgroundColor: chipColor,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  Widget _buildDetailColumn(String label, String value, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              icon,
              size: 16,
              color: Colors.grey[600],
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  bool _shouldShowAlerts() {
    return medication.isExpired || 
           medication.isExpiringSoon ||
           (medication.alertOnLowStock && _isLowStock());
  }

  bool _isLowStock() {
    // Simple low stock logic - in a real app this would be configurable
    return medication.stockQuantity < 5;
  }

  Widget _buildAlertsRow() {
    List<Widget> alerts = [];
    
    if (medication.isExpired) {
      alerts.add(_buildAlert(
        'EXPIRED',
        Colors.red,
        Icons.error,
      ));
    } else if (medication.isExpiringSoon) {
      alerts.add(_buildAlert(
        'EXPIRES SOON',
        Colors.orange,
        Icons.warning,
      ));
    }
    
    if (medication.alertOnLowStock && _isLowStock()) {
      alerts.add(_buildAlert(
        'LOW STOCK',
        Colors.amber,
        Icons.inventory_2,
      ));
    }
    
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: alerts,
    );
  }

  Widget _buildAlert(String label, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        border: Border.all(color: color, width: 1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  bool _shouldShowStorageIndicators() {
    return medication.requiresRefrigeration ||
           medication.reconstitutionVolume != null;
  }

  Widget _buildStorageIndicators() {
    List<Widget> indicators = [];
    
    if (medication.requiresRefrigeration) {
      indicators.add(_buildStorageIndicator(
        'Refrigerate',
        Icons.ac_unit,
        Colors.blue,
      ));
    }
    
    if (medication.reconstitutionVolume != null) {
      indicators.add(_buildStorageIndicator(
        'Reconstituted',
        Icons.science,
        Colors.purple,
      ));
    }
    
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: indicators,
    );
  }

  Widget _buildStorageIndicator(String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 12,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  // New helper methods for compact design
  Color _getBorderColor() {
    if (medication.isExpired) return Colors.red.shade200;
    if (medication.isExpiringSoon) return Colors.orange.shade200;
    if (_isLowStock()) return Colors.amber.shade200;
    return Colors.grey.shade200;
  }
  
  Color _getTypeColor() {
    switch (medication.type) {
      case MedicationType.tablet:
      case MedicationType.capsule:
        return Colors.blue.shade600;
      case MedicationType.preFilledSyringe:
      case MedicationType.readyMadeVial:
      case MedicationType.lyophilizedVial:
        return Colors.red.shade600;
      case MedicationType.cream:
      case MedicationType.ointment:
        return Colors.green.shade600;
      default:
        return Colors.grey.shade600;
    }
  }
  
  IconData _getTypeIcon() {
    switch (medication.type) {
      case MedicationType.tablet:
        return Icons.medication;
      case MedicationType.capsule:
        return Icons.medication_liquid;
      case MedicationType.preFilledSyringe:
        return Icons.colorize;
      case MedicationType.readyMadeVial:
      case MedicationType.lyophilizedVial:
        return Icons.science;
      case MedicationType.cream:
      case MedicationType.ointment:
        return Icons.palette;
      default:
        return Icons.medication;
    }
  }
  
  String _getTypeAbbreviation() {
    switch (medication.type) {
      case MedicationType.tablet:
        return 'TAB';
      case MedicationType.capsule:
        return 'CAP';
      case MedicationType.preFilledSyringe:
        return 'SYR';
      case MedicationType.readyMadeVial:
        return 'VIAL';
      case MedicationType.lyophilizedVial:
        return 'LYO';
      case MedicationType.cream:
        return 'CRM';
      case MedicationType.ointment:
        return 'OIN';
      default:
        return 'MED';
    }
  }
  
  Color _getStockColor() {
    if (_isLowStock()) return Colors.red.shade600;
    if (medication.stockQuantity < 10) return Colors.orange.shade600;
    return Colors.green.shade600;
  }
  
  Color _getExpiryColor() {
    if (medication.isExpired) return Colors.red.shade600;
    if (medication.isExpiringSoon) return Colors.orange.shade600;
    return Colors.grey.shade600;
  }
  
  List<Widget> _buildCompactAlerts() {
    List<Widget> alerts = [];
    
    if (medication.isExpired) {
      alerts.add(_buildCompactAlert(Colors.red, Icons.error));
    } else if (medication.isExpiringSoon) {
      alerts.add(_buildCompactAlert(Colors.orange, Icons.warning));
    }
    
    if (medication.alertOnLowStock && _isLowStock()) {
      alerts.add(_buildCompactAlert(Colors.amber, Icons.inventory_2));
    }
    
    return alerts;
  }
  
  List<Widget> _buildCompactStorageIndicators() {
    List<Widget> indicators = [];
    
    if (medication.requiresRefrigeration) {
      indicators.add(_buildCompactAlert(Colors.blue, Icons.ac_unit));
    }
    
    if (medication.reconstitutionVolume != null) {
      indicators.add(_buildCompactAlert(Colors.purple, Icons.science));
    }
    
    return indicators;
  }
  
  Widget _buildCompactAlert(Color color, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(right: 3),
      width: 14,
      height: 14,
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(2),
      ),
      child: Icon(
        icon,
        size: 8,
        color: color,
      ),
    );
  }

  void _handleMenuSelection(String value) {
    debugPrint('🛠️ [CARD DEBUG] MedicationCard menu action: $value for ${medication.name}');
    switch (value) {
      case 'edit':
        print('[DEBUG] Calling onEdit for ${medication.name}');
        onEdit?.call();
        break;
      case 'delete':
        print('[DEBUG] Calling onDelete for ${medication.name}');
        onDelete?.call();
        break;
    }
  }
}
