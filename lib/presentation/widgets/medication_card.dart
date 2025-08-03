import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/models/medication.dart';

class MedicationCard extends StatelessWidget {
  final Medication medication;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const MedicationCard({
    Key? key,
    required this.medication,
    this.onTap,
    this.onEdit,
    this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row with medication name and actions
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          medication.name,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (medication.brandManufacturer != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            medication.brandManufacturer!,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  _buildMedicationTypeChip(),
                  PopupMenuButton<String>(
                    onSelected: _handleMenuSelection,
                    itemBuilder: (BuildContext context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: ListTile(
                          leading: Icon(Icons.edit),
                          title: Text('Edit'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: ListTile(
                          leading: Icon(Icons.delete, color: Colors.red),
                          title: Text('Delete', style: TextStyle(color: Colors.red)),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Medication details in a grid
              Row(
                children: [
                  Expanded(
                    child: _buildDetailColumn(
                      'Strength',
                      medication.displayStrength,
                      Icons.medication,
                    ),
                  ),
                  Expanded(
                    child: _buildDetailColumn(
                      'Stock',
                      medication.stockDisplay,
                      Icons.inventory,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Additional information row
              Row(
                children: [
                  if (medication.lotBatchNumber != null)
                    Expanded(
                      child: _buildDetailColumn(
                        'Batch No',
                        medication.lotBatchNumber!,
                        Icons.qr_code,
                      ),
                    ),
                  if (medication.expirationDate != null)
                    Expanded(
                      child: _buildDetailColumn(
                        'Expires',
                        DateFormat('MMM dd, yyyy').format(medication.expirationDate!),
                        Icons.schedule,
                      ),
                    ),
                ],
              ),
              
              // Alerts and warnings
              if (_shouldShowAlerts()) ...[
                const SizedBox(height: 12),
                _buildAlertsRow(),
              ],
              
              // Storage and special handling indicators
              if (_shouldShowStorageIndicators()) ...[
                const SizedBox(height: 8),
                _buildStorageIndicators(),
              ],
            ],
          ),
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
      case MedicationType.injection:
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
        color: color.withOpacity(0.1),
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
        color: color.withOpacity(0.1),
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

  void _handleMenuSelection(String value) {
    switch (value) {
      case 'edit':
        onEdit?.call();
        break;
      case 'delete':
        onDelete?.call();
        break;
    }
  }
}
