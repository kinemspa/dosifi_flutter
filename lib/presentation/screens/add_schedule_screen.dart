import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/models/schedule.dart';
import '../../data/models/medication.dart';
import '../providers/schedule_provider.dart';
import '../providers/medication_provider.dart';
import '../../config/app_router.dart';

class AddScheduleScreen extends ConsumerStatefulWidget {
  final String? scheduleId;
  
  const AddScheduleScreen({
    Key? key,
    this.scheduleId,
  }) : super(key: key);

  @override
  ConsumerState<AddScheduleScreen> createState() => _AddScheduleScreenState();
}

class _AddScheduleScreenState extends ConsumerState<AddScheduleScreen> {
  final _formKey = GlobalKey<FormState>();
  final _doseAmountController = TextEditingController();
  final _strengthPerUnitController = TextEditingController();
  final _notesController = TextEditingController();
  
  int? _selectedMedicationId;
  ScheduleType _selectedScheduleType = ScheduleType.daily;
  TimeOfDay? _selectedTime;
  String _selectedDoseUnit = 'mg';
  String _selectedDoseForm = 'tablet';
  DateTime _startDate = DateTime.now();
  DateTime? _endDate;
  List<int> _selectedDaysOfWeek = [];
  int? _cycleDaysOn;
  int? _cycleDaysOff;
  bool _isLoading = false;

  // Predefined options
  final List<String> _doseUnits = ['mg', 'ml', 'g', 'mcg', 'units', 'drops', 'puffs'];
  final List<String> _doseForms = ['tablet', 'capsule', 'liquid', 'injection', 'drops', 'inhaler', 'patch', 'cream'];
  final List<String> _weekDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  @override
  void initState() {
    super.initState();
    if (isEditMode) {
      _loadScheduleData();
    }
  }

  bool get isEditMode => widget.scheduleId != null;

  @override
  void dispose() {
    _doseAmountController.dispose();
    _strengthPerUnitController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _loadScheduleData() async {
    // TODO: Implement loading existing schedule data for editing
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(isEditMode ? 'Edit Schedule' : 'Add Schedule'),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.navigateBackSmart(),
        ),
        actions: [
          if (isEditMode)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _showDeleteDialog,
            ),
        ],
      ),
      body: _isLoading
        ? const Center(child: CircularProgressIndicator())
        : Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // Step indicator
                _buildStepIndicator(),
                const SizedBox(height: 32),
                
                // Medication Selection Section
                _buildMedicationSelectionSection(),
                const SizedBox(height: 32),
                
                // Schedule Type and Time Section
                _buildScheduleTypeSection(),
                const SizedBox(height: 32),
                
                // Dose Information Section
                _buildDoseInformationSection(),
                const SizedBox(height: 32),
                
                // Date Range Section
                _buildDateRangeSection(),
                
                // Schedule-specific options
                if (_selectedScheduleType == ScheduleType.weekly) ...[
                  const SizedBox(height: 32),
                  _buildWeeklyOptionsSection(),
                ],
                if (_selectedScheduleType == ScheduleType.cycling) ...[
                  const SizedBox(height: 32),
                  _buildCyclingOptionsSection(),
                ],
                
                const SizedBox(height: 40),
                
                // Save button
                _buildSaveButton(),
              ],
            ),
          ),
    );
  }

  Widget _buildStepIndicator() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green[200]!),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: Colors.green,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.schedule,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Medication Schedule',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Set up when and how to take your medication',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMedicationSelectionSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('Select Medication'),
            
            // Medication dropdown
            Consumer(
              builder: (context, ref, child) {
                final medicationsAsync = ref.watch(medicationListProvider);
                
                return medicationsAsync.when(
                  data: (medications) => DropdownButtonFormField<int>(
                    value: _selectedMedicationId,
                    decoration: const InputDecoration(
                      labelText: 'Medication *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.medication),
                      helperText: 'Choose the medication for this schedule',
                    ),
                    items: medications.map((medication) {
                      return DropdownMenuItem(
                        value: medication.id,
                        child: Row(
                          children: [
                            Icon(
                              _getMedicationIcon(medication.type),
                              size: 20,
                              color: Colors.blue,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    medication.name,
                                    style: const TextStyle(fontWeight: FontWeight.w500),
                                  ),
                                  Text(
                                    '${medication.strengthPerUnit} ${medication.strengthUnit.displayName}',
                                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedMedicationId = value;
                        // Auto-populate strength when medication is selected
                        if (value != null) {
                          final medication = medications.firstWhere((m) => m.id == value);
                          _strengthPerUnitController.text = medication.strengthPerUnit.toString();
                        }
                      });
                    },
                    validator: (value) {
                      if (value == null) {
                        return 'Please select a medication';
                      }
                      return null;
                    },
                  ),
                  loading: () => const LinearProgressIndicator(),
                  error: (error, _) => Text('Error loading medications: $error'),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScheduleTypeSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('Schedule Type & Time'),
            
            // Schedule type dropdown
            DropdownButtonFormField<ScheduleType>(
              value: _selectedScheduleType,
              decoration: const InputDecoration(
                labelText: 'Schedule Type *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.repeat),
                helperText: 'How often should this medication be taken?',
              ),
              items: ScheduleType.values.map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Row(
                    children: [
                      Icon(
                        _getScheduleTypeIcon(type),
                        size: 20,
                        color: Colors.green,
                      ),
                      const SizedBox(width: 8),
                      Text(type.displayName),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedScheduleType = value!;
                  // Reset type-specific values when type changes
                  _selectedDaysOfWeek.clear();
                  _cycleDaysOn = null;
                  _cycleDaysOff = null;
                });
              },
            ),
            const SizedBox(height: 16),
            
            // Time picker
            InkWell(
              onTap: _selectTime,
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Time *',
                  suffixIcon: Icon(Icons.access_time),
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.schedule),
                  helperText: 'What time should this dose be taken?',
                ),
                child: Text(
                  _selectedTime != null
                      ? _selectedTime!.format(context)
                      : 'Select time',
                  style: TextStyle(
                    color: _selectedTime != null
                        ? Theme.of(context).textTheme.bodyLarge?.color
                        : Theme.of(context).hintColor,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDoseInformationSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('Dose Information'),
            
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: _doseAmountController,
                    decoration: const InputDecoration(
                      labelText: 'Dose Amount *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.scale),
                      helperText: 'How much to take',
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Dose amount is required';
                      }
                      final amount = double.tryParse(value.trim());
                      if (amount == null || amount <= 0) {
                        return 'Enter a valid dose amount';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedDoseUnit,
                    decoration: const InputDecoration(
                      labelText: 'Unit',
                      border: OutlineInputBorder(),
                    ),
                    items: _doseUnits.map((unit) {
                      return DropdownMenuItem(
                        value: unit,
                        child: Text(unit),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedDoseUnit = value!;
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Dose form dropdown
            DropdownButtonFormField<String>(
              value: _selectedDoseForm,
              decoration: const InputDecoration(
                labelText: 'Dose Form',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.medication),
                helperText: 'How is the medication taken?',
              ),
              items: _doseForms.map((form) {
                return DropdownMenuItem(
                  value: form,
                  child: Text(form.substring(0, 1).toUpperCase() + form.substring(1)),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedDoseForm = value!;
                });
              },
            ),
            const SizedBox(height: 16),
            
            // Strength per unit (auto-populated from medication)
            TextFormField(
              controller: _strengthPerUnitController,
              decoration: const InputDecoration(
                labelText: 'Strength Per Unit',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.straighten),
                helperText: 'Automatically filled from medication',
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Strength is required';
                }
                final strength = double.tryParse(value.trim());
                if (strength == null || strength <= 0) {
                  return 'Enter a valid strength';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateRangeSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('Date Range'),
            
            // Start date
            InkWell(
              onTap: _selectStartDate,
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Start Date *',
                  suffixIcon: Icon(Icons.calendar_today),
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.event_available),
                ),
                child: Text(
                  '${_startDate.day}/${_startDate.month}/${_startDate.year}',
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // End date (optional)
            InkWell(
              onTap: _selectEndDate,
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'End Date (Optional)',
                  suffixIcon: Icon(Icons.calendar_today),
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.event_busy),
                  helperText: 'Leave empty for indefinite schedule',
                ),
                child: Text(
                  _endDate != null
                      ? '${_endDate!.day}/${_endDate!.month}/${_endDate!.year}'
                      : 'No end date',
                  style: TextStyle(
                    color: _endDate != null
                        ? Theme.of(context).textTheme.bodyLarge?.color
                        : Theme.of(context).hintColor,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeeklyOptionsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('Weekly Schedule Options'),
            
            const Text(
              'Select the days of the week:',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            
            Wrap(
              spacing: 8,
              children: List.generate(7, (index) {
                final dayIndex = index + 1; // 1 = Monday, 7 = Sunday
                final isSelected = _selectedDaysOfWeek.contains(dayIndex);
                
                return FilterChip(
                  label: Text(_weekDays[index]),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedDaysOfWeek.add(dayIndex);
                      } else {
                        _selectedDaysOfWeek.remove(dayIndex);
                      }
                    });
                  },
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCyclingOptionsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('Cycling Schedule Options'),
            
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Days On *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.play_arrow),
                      helperText: 'Days to take medication',
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      _cycleDaysOn = int.tryParse(value);
                    },
                    validator: (value) {
                      if (_selectedScheduleType == ScheduleType.cycling) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Required for cycling';
                        }
                        final days = int.tryParse(value.trim());
                        if (days == null || days <= 0) {
                          return 'Enter valid days';
                        }
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Days Off *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.pause),
                      helperText: 'Days to skip medication',
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      _cycleDaysOff = int.tryParse(value);
                    },
                    validator: (value) {
                      if (_selectedScheduleType == ScheduleType.cycling) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Required for cycling';
                        }
                        final days = int.tryParse(value.trim());
                        if (days == null || days <= 0) {
                          return 'Enter valid days';
                        }
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _isLoading ? null : _saveSchedule,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
        ),
        icon: _isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Icon(isEditMode ? Icons.update : Icons.add),
        label: Text(
          isEditMode ? 'Update Schedule' : 'Add Schedule',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // Helper methods for icons
  IconData _getMedicationIcon(MedicationType type) {
    switch (type) {
      case MedicationType.tablet:
        return Icons.medication;
      case MedicationType.capsule:
        return Icons.medication;
      case MedicationType.liquid:
        return Icons.water_drop;
      case MedicationType.preFilledSyringe:
        return Icons.medical_services;
      case MedicationType.drops:
        return Icons.water_drop;
      case MedicationType.inhaler:
        return Icons.air;
      case MedicationType.patch:
        return Icons.healing;
      case MedicationType.cream:
        return Icons.healing;
      default:
        return Icons.medication;
    }
  }

  IconData _getScheduleTypeIcon(ScheduleType type) {
    switch (type) {
      case ScheduleType.daily:
        return Icons.today;
      case ScheduleType.weekly:
        return Icons.date_range;
      case ScheduleType.monthly:
        return Icons.calendar_month;
      case ScheduleType.cycling:
        return Icons.repeat;
      case ScheduleType.asNeeded:
        return Icons.help_outline;
      case ScheduleType.custom:
        return Icons.tune;
    }
  }

  // Date and time picker methods
  void _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  void _selectStartDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (picked != null) {
      setState(() {
        _startDate = picked;
        // If end date is before start date, reset it
        if (_endDate != null && _endDate!.isBefore(_startDate)) {
          _endDate = null;
        }
      });
    }
  }

  void _selectEndDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? _startDate.add(const Duration(days: 30)),
      firstDate: _startDate,
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (picked != null) {
      setState(() {
        _endDate = picked;
      });
    }
  }

  void _showDeleteDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Schedule'),
        content: const Text('Are you sure you want to delete this schedule? This will also remove all future planned doses.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteSchedule();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _deleteSchedule() async {
    // TODO: Implement schedule deletion
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Delete schedule logic here
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Schedule deleted successfully')),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting schedule: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _saveSchedule() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a time')),
      );
      return;
    }
    if (_selectedMedicationId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a medication')),
      );
      return;
    }
    if (_selectedScheduleType == ScheduleType.weekly && _selectedDaysOfWeek.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one day for weekly schedule')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final schedule = Schedule.create(
        medicationId: _selectedMedicationId!,
        scheduleType: _selectedScheduleType.name,
        timeOfDay: '${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}',
        daysOfWeek: _selectedScheduleType == ScheduleType.weekly ? _selectedDaysOfWeek : null,
        startDate: _startDate,
        endDate: _endDate,
        cycleDaysOn: _cycleDaysOn,
        cycleDaysOff: _cycleDaysOff,
        doseAmount: double.parse(_doseAmountController.text.trim()),
        doseUnit: _selectedDoseUnit,
        doseForm: _selectedDoseForm,
        strengthPerUnit: double.parse(_strengthPerUnitController.text.trim()),
      );

      if (isEditMode) {
        // TODO: Implement schedule update
      } else {
        await ref.read(scheduleListProvider.notifier).addSchedule(schedule);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isEditMode ? 'Schedule updated successfully' : 'Schedule added successfully'),
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving schedule: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
