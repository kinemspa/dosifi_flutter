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

class MedicationFormScreenRefactored extends ConsumerStatefulWidget {
  final String? medicationId; // null for add, not null for edit

  const MedicationFormScreenRefactored({
    super.key,
    this.medicationId,
  });

  @override
  ConsumerState<MedicationFormScreenRefactored> createState() => _MedicationFormScreenRefactoredState();
}

class _MedicationFormScreenRefactoredState extends ConsumerState<MedicationFormScreenRefactored> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final controller = ref.read(medicationFormControllerProvider(widget.medicationId));
      controller.loadMedicationData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, child) {
        final controller = ref.watch(medicationFormControllerProvider(widget.medicationId));
        
        return Scaffold(
          backgroundColor: Colors.grey[50],
          appBar: AppBar(
            title: Text(controller.isEditMode ? 'Edit Medication' : 'Add Medication'),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => context.navigateBackSmart(),
            ),
            actions: [
              if (controller.isEditMode)
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () => _showDeleteDialog(context, controller),
                ),
            ],
          ),
          body: controller.isLoading
              ? const Center(child: CircularProgressIndicator())
              : Form(
                  key: controller.formKey,
                  child: ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      // Step indicator
                      _buildStepIndicator(context, controller),
                      const SizedBox(height: 32),
                      
                      // Medication Type - First and Required
                      MedicationTypeSection(controller: controller),
                      
                      // Only show rest of form if type is selected
                      if (controller.selectedType != null) ...[
                        const SizedBox(height: 32),
                        BasicInformationSection(controller: controller),
                        const SizedBox(height: 32),
                        StrengthSection(controller: controller),
                        const SizedBox(height: 32),
                        StockInformationSection(controller: controller),
                        const SizedBox(height: 32),
                        StorageSection(controller: controller),
                        const SizedBox(height: 32),
                        AdditionalInfoSection(controller: controller),
                        const SizedBox(height: 40),
                        _buildSaveButton(context, controller),
                      ],
                    ],
                  ),
                ),
        );
      },
    );
  }

  Widget _buildStepIndicator(BuildContext context, MedicationFormController controller) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: Colors.blue[700]),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              controller.selectedType == null 
                ? 'Step 1: Select medication type to continue'
                : 'Step 2: Fill in the medication details',
              style: TextStyle(
                color: Colors.blue[700],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton(BuildContext context, MedicationFormController controller) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: controller.isLoading ? null : () => _saveMedication(context, controller),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue[600],
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 2,
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
                  controller.isEditMode ? 'Update Medication' : 'Add Medication',
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

  void _saveMedication(BuildContext context, MedicationFormController controller) async {
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
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(controller.isEditMode 
              ? 'Medication updated successfully' 
              : 'Medication added successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error ${controller.isEditMode ? 'updating' : 'adding'} medication: $e'),
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

  void _showDeleteDialog(BuildContext context, MedicationFormController controller) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Medication'),
        content: const Text('Are you sure you want to delete this medication? This action cannot be undone.'),
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
                  context.pop();
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
}
