import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dosifi_flutter/config/app_router.dart';
import 'package:dosifi_flutter/presentation/screens/medication_form/controllers/medication_form_controller.dart';
import 'package:dosifi_flutter/presentation/screens/medication_form/form_sections/medication_type_section.dart';
import 'package:dosifi_flutter/presentation/screens/medication_form/form_sections/basic_information_section.dart';
import 'package:dosifi_flutter/presentation/screens/medication_form/form_sections/strength_section.dart';
import 'package:dosifi_flutter/presentation/screens/medication_form/form_sections/stock_information_section.dart';
import 'package:dosifi_flutter/presentation/screens/medication_form/form_sections/storage_section.dart';
import 'package:dosifi_flutter/presentation/screens/medication_form/form_sections/additional_info_section.dart';
import 'package:dosifi_flutter/presentation/screens/medication_form/utils/medication_type_utils.dart';
import 'package:dosifi_flutter/data/models/medication.dart';

class MedicationFormScreenRefactored extends ConsumerStatefulWidget {
  final String? medicationId; // null for add, not null for edit
  final bool compactSheetMode;

  const MedicationFormScreenRefactored({
    super.key,
    this.medicationId,
    this.compactSheetMode = false,
  });

  @override
  ConsumerState<MedicationFormScreenRefactored> createState() =>
      _MedicationFormScreenRefactoredState();
}

class _MedicationFormScreenRefactoredState
    extends ConsumerState<MedicationFormScreenRefactored> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final controller = ref.read(
        medicationFormControllerProvider(widget.medicationId),
      );
      controller.loadMedicationData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, child) {
        final controller = ref.watch(
          medicationFormControllerProvider(widget.medicationId),
        );

        // Build the common list of form sections
        final List<Widget> sections = [
          const SizedBox(height: 12), // top padding from app bar
          // Helper tip before type selection only
          if (controller.selectedType == null) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: _buildStepHelper(context),
            ),
            const SizedBox(height: 8),
          ],
          // Medication Type - First and Required
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: MedicationTypeSection(controller: controller),
          ),
        ];

        if (controller.selectedType != null) {
          sections.addAll([
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: BasicInformationSection(controller: controller),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: StrengthSection(controller: controller),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: StockInformationSection(controller: controller),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: StorageSection(controller: controller),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: AdditionalInfoSection(controller: controller),
            ),
            const SizedBox(
              height: 140,
            ), // Extra space so fields aren't hidden behind floating summary
          ]);
        }

        final formBody = controller.isLoading
            ? const Center(child: CircularProgressIndicator())
            : Form(
                key: controller.formKey,
                child: widget.compactSheetMode
                    // In compact sheet mode we are already in a SingleChildScrollView provided by the sheet.
                    // Avoid nesting another scrollable. Use a Column instead.
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: sections,
                      )
                    // In full-screen mode, make the form scrollable with padding.
                    : CustomScrollView(
                        slivers: [
                          SliverList(
                            delegate: SliverChildListDelegate(sections),
                          ),
                        ],
                      ),
              );

        if (widget.compactSheetMode) {
          return Stack(
            children: [
              formBody,
              if (controller.selectedType != null)
                Positioned(
                  left: 12,
                  right: 12,
                  bottom: 12,
                  child: _buildFloatingSummary(context, controller),
                ),
            ],
          );
        }

        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            title: Text(
              controller.isEditMode ? 'Edit Medication' : 'Add Medication',
            ),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => context.navigateBackSmart(),
            ),
            actions: [
              if (controller.isEditMode)
                IconButton(
                  tooltip: 'Delete medication',
                  icon: const Icon(Icons.delete),
                  onPressed: () => _showDeleteDialog(context, controller),
                ),
            ],
          ),
          body: Stack(
            children: [
              formBody,
              if (controller.selectedType != null)
                Positioned(
                  left: 12,
                  right: 12,
                  bottom: 12,
                  child: _buildFloatingSummary(context, controller),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStepHelper(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: Colors.blue[700]),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'Step 1: Select medication type to continue',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingSummary(
    BuildContext context,
    MedicationFormController controller,
  ) {
    final type = controller.selectedType!;
    final baseColor = MedicationTypeUtils.getMedicationTypeColor(type);
    final icon = MedicationTypeUtils.getMedicationTypeIcon(type);
    final name = controller.nameController.text.trim();
    final brand = controller.brandController.text.trim();
    final strength = controller.strengthController.text.trim();
    final strengthUnit = controller.selectedStrengthUnit?.displayName ?? '';
    final stock = controller.stockController.text.trim();
    final stockUnit = controller.selectedStockUnit ?? '';
    final refrigerated = controller.requiresRefrigeration;
    final expiry = controller.expirationDate;

    String expiryTextStr() {
      if (expiry == null) return 'No expiry set';
      final now = DateTime.now();
      final days = expiry
          .difference(DateTime(now.year, now.month, now.day))
          .inDays;
      if (days < 0) return 'Expired';
      if (days == 0) return 'Expires today';
      if (days == 1) return 'Expires tomorrow';
      return 'Expires in $days days';
    }

    // Build the summary content according to requested layout
    Widget summaryContent({bool showTypeChip = true}) {
      final theme = Theme.of(context);
      final description = controller.descriptionController.text.trim();
      final instructions = controller.instructionsController.text.trim();
      final notes = controller.notesController.text.trim();

      Widget labelValue(String label, String value) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: '$label\n',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: Colors.white70,
                  ),
                ),
                TextSpan(
                  text: value.isEmpty ? '—' : value,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        );
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (name.isNotEmpty) labelValue('Name', name),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (brand.isNotEmpty)
                          Expanded(
                            child: labelValue('Brand/Manufacturer', brand),
                          ),
                        if (showTypeChip)
                          Container(
                            margin: const EdgeInsets.only(left: 8, top: 6),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.35),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(icon, size: 16, color: Colors.white),
                                const SizedBox(width: 6),
                                Text(
                                  type.displayName,
                                  style: theme.textTheme.labelLarge?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    if (description.isNotEmpty)
                      labelValue('Description', description),
                    if (strength.isNotEmpty || strengthUnit.isNotEmpty)
                      labelValue(
                        type == MedicationType.tablet
                            ? 'Strength per Tablet'
                            : type == MedicationType.capsule
                            ? 'Strength per Capsule'
                            : 'Strength',
                        (strength.isEmpty ? '' : strength) +
                            (strengthUnit.isEmpty ? '' : ' $strengthUnit'),
                      ),
                    if (stock.isNotEmpty)
                      labelValue(
                        'Number of ${type.displayName}s in Stock',
                        (stock.isEmpty ? '' : stock) +
                            (stockUnit.isEmpty ? '' : ' $stockUnit'),
                      ),
                    if (refrigerated) labelValue('Refrigeration', 'Required'),
                    if (instructions.isNotEmpty)
                      labelValue('Instructions', instructions),
                    if (notes.isNotEmpty) labelValue('Notes', notes),
                  ],
                ),
              ),
            ],
          ),
        ],
      );
    }

    return Material(
      elevation: 8,
      borderRadius: BorderRadius.circular(16),
      shadowColor: Colors.black.withValues(alpha: 0.2),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [baseColor, baseColor.withValues(alpha: 0.85)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.all(14),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            summaryContent(),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: Tooltip(
                message: controller.isEditMode
                    ? 'Save changes'
                    : 'Save medication',
                child: ElevatedButton(
                  onPressed: controller.isLoading
                      ? null
                      : () => _confirmAndSave(
                          context,
                          controller,
                        ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: baseColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: controller.isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.black54,
                            ),
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              controller.isEditMode
                                  ? Icons.save
                                  : Icons.save_outlined,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              controller.isEditMode
                                  ? 'Save Changes'
                                  : 'Save Medication',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tag(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton(
    BuildContext context,
    MedicationFormController controller,
  ) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: controller.isLoading
            ? null
            : () => _confirmAndSave(context, controller),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue[600],
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 1,
        ),
        child: controller.isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(controller.isEditMode ? Icons.update : Icons.add),
                  const SizedBox(width: 8),
                  Text(
                    controller.isEditMode
                        ? 'Update Medication'
                        : 'Add Medication',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Future<void> _confirmAndSave(
    BuildContext context,
    MedicationFormController controller,
  ) async {
    // Validate required fields first
    if (!controller.validateForm()) {
      return;
    }

    final theme = Theme.of(context);
    final name = controller.nameController.text.trim();
    final type = controller.selectedType?.displayName ?? '—';
    final strength = controller.strengthController.text.trim();
    final strengthUnit = controller.selectedStrengthUnit?.displayName ?? '';
    final qty = controller.stockController.text.trim();
    final stockUnit = controller.selectedStockUnit ?? '';

    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: Text(
            controller.isEditMode ? 'Save Changes' : 'Save Medication',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Please review the details before saving:',
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 12),
                _confirmRow(theme, 'Name', name.isEmpty ? '—' : name),
                _confirmRow(theme, 'Type', type),
                _confirmRow(theme, 'Strength', strength.isEmpty ? '—' : '$strength $strengthUnit'),
                _confirmRow(theme, 'Quantity', qty.isEmpty ? '—' : '$qty $stockUnit'),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(ctx).pop();
                await _saveMedication(context, controller);
              },
              child: Text(
                controller.isEditMode ? 'Save Changes' : 'Save Medication',
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _confirmRow(ThemeData theme, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 92,
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveMedication(
    BuildContext context,
    MedicationFormController controller,
  ) async {
    if (!controller.validateForm()) {
      return;
    }

    controller.setIsLoading(true);

    try {
      if (controller.isEditMode) {
        await controller.updateMedication();
      } else {
        await controller.createMedication();
      }

      if (mounted) {
        // Reset form state after successful save when adding new medication
        if (!controller.isEditMode) {
          controller.resetFormState();
        }
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              controller.isEditMode
                  ? 'Medication updated successfully'
                  : 'Medication saved successfully',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error ${controller.isEditMode ? 'updating' : 'adding'} medication: $e',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        controller.setIsLoading(false);
      }
    }
  }

  void _showDeleteDialog(
    BuildContext context,
    MedicationFormController controller,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Medication'),
        content: const Text(
          'Are you sure you want to delete this medication? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              try {
                await controller.deleteMedication();
                if (mounted) {
                  context.go('/medications');
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Medication deleted successfully'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error deleting medication: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  // Floating summary removed; inline summary is now shown at the top in the step area.
}
