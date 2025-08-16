import 'package:flutter/material.dart';

class EmbeddedReconstitutionCalculator extends StatefulWidget {
  final Function(double volume, double concentration, String notes)?
      onCalculationResult;
  final double? initialStrength;
  final String? initialStrengthUnit;

  const EmbeddedReconstitutionCalculator({
    super.key,
    this.onCalculationResult,
    this.initialStrength,
    this.initialStrengthUnit,
  });

  @override
  State<EmbeddedReconstitutionCalculator> createState() =>
      _EmbeddedReconstitutionCalculatorState();
}

class _EmbeddedReconstitutionCalculatorState
    extends State<EmbeddedReconstitutionCalculator> {
  final _strengthController = TextEditingController();
  final _desiredDoseController = TextEditingController();

  String _strengthUnit = 'mg';
  String _doseUnit = 'Units';
  String _syringeSize = '1mL';
  String? _targetVialSize;

  Map<String, dynamic>? _results;

  final List<String> _strengthUnits = ['mg', 'mcg', 'g', 'Units', 'IU'];
  final List<String> _doseUnits = ['Units', 'IU', 'mg', 'mcg'];
  final List<String> _syringeSizes = ['0.3mL', '0.5mL', '1mL', '3mL', '5mL'];
  final List<String?> _vialSizes = [null, '1mL', '3mL', '5mL', '10mL', '20mL'];

  @override
  void initState() {
    super.initState();
    // Initialize with values from parent form
    if (widget.initialStrength != null) {
      _strengthController.text = widget.initialStrength.toString();
    }
    if (widget.initialStrengthUnit != null) {
      _strengthUnit = widget.initialStrengthUnit!;
    }
    // Calculate initial results if we have a strength
    if (widget.initialStrength != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _calculate();
      });
    }
  }

  @override
  void didUpdateWidget(EmbeddedReconstitutionCalculator oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Update when parent form changes
    if (widget.initialStrength != oldWidget.initialStrength) {
      _strengthController.text = widget.initialStrength?.toString() ?? '';
      _calculate();
    }
    if (widget.initialStrengthUnit != oldWidget.initialStrengthUnit) {
      setState(() {
        _strengthUnit = widget.initialStrengthUnit ?? 'mg';
      });
      _calculate();
    }
  }

  void _calculate() {
    final strength = double.tryParse(_strengthController.text);

    if (strength == null || strength == 0) {
      setState(() {
        _results = null;
      });
      return;
    }

    // Convert strength to base units for mg pathway
    double strengthInUnits = strength;
    if (_strengthUnit == 'mg') {
      strengthInUnits = strength;
    } else if (_strengthUnit == 'mcg') {
      strengthInUnits = strength / 1000; // Convert mcg to mg
    } else if (_strengthUnit == 'g') {
      strengthInUnits = strength * 1000; // Convert g to mg
    }
    // For IU and Units, keep as provided (treated as per-mL mass-equivalent units)

    // Parse syringe size
    final double syringeVolume = double.parse(
      _syringeSize.replaceAll('mL', ''),
    );

    setState(() {
      _results = _calculateOptions(strengthInUnits, syringeVolume);
    });
  }

  Map<String, dynamic> _calculateOptions(
    double strength,
    double syringeVolume,
  ) {
    final Map<String, dynamic> results = {};

    double? desiredDose = double.tryParse(_desiredDoseController.text);

    void addOption(String key, double volume, double concentration, String desc) {
      // If a desiredDose is provided and concentration > 0, compute the per-dose volume
      double? doseVolume;
      bool withinSyringe = true;
      if (desiredDose != null && concentration > 0) {
        doseVolume = desiredDose / concentration;
        // Simple constraint: dose volume must fit in selected syringe size
        withinSyringe = doseVolume <= syringeVolume;
      }
      results[key] = {
        'volume': volume,
        'concentration': concentration,
        'description': desc,
        'doseVolume': doseVolume,
        'withinSyringe': withinSyringe,
      };
    }

    if (_targetVialSize != null) {
      // With target vial volume
      final double vialVolume = double.parse(
        _targetVialSize!.replaceAll('mL', ''),
      );

      // Concentrated: 1mL reconstitution
      final double concentratedVolume = 1.0;
      final double concentratedConcentration = strength / concentratedVolume;

      // Average: 60% of vial volume
      final double avgVolume = vialVolume * 0.6;
      final double avgConcentration = strength / avgVolume;

      // Diluted: full vial volume
      final double dilutedConcentration = strength / vialVolume;

      addOption(
        'concentrated',
        concentratedVolume,
        concentratedConcentration,
        '${concentratedVolume.toStringAsFixed(1)}mL reconstitution',
      );
      addOption(
        'average',
        avgVolume,
        avgConcentration,
        '${avgVolume.toStringAsFixed(1)}mL reconstitution',
      );
      addOption(
        'diluted',
        vialVolume,
        dilutedConcentration,
        '${vialVolume.toStringAsFixed(1)}mL reconstitution',
      );
    } else {
      // Standard options without target vial
      addOption(
        'concentrated',
        1.0,
        strength,
        '1mL reconstitution (concentrated)',
      );
      addOption(
        'average',
        5.0,
        strength / 5.0,
        '5mL reconstitution (average)',
      );
      addOption(
        'diluted',
        10.0,
        strength / 10.0,
        '10mL reconstitution (diluted)',
      );
    }

    return results;
  }

  void _selectOption(String option) {
    if (_results != null && _results!.containsKey(option)) {
      final result = _results![option];
      if (widget.onCalculationResult != null) {
        widget.onCalculationResult!(
          result['volume'] as double,
          result['concentration'] as double,
          result['description'] as String,
        );
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Selected: ${result['description']}'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Reconstitution Calculator',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              flex: 2,
              child: TextFormField(
                controller: _strengthController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Powder Strength',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                onChanged: (_) => _calculate(),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: DropdownButtonFormField<String>(
                value: _strengthUnit,
                decoration: const InputDecoration(
                  labelText: 'Unit',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                items: _strengthUnits
                    .map(
                      (unit) =>
                          DropdownMenuItem(value: unit, child: Text(unit)),
                    )
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _strengthUnit = value!;
                    _calculate();
                  });
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                value: _syringeSize,
                decoration: const InputDecoration(
                  labelText: 'Syringe Size',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                items: _syringeSizes
                    .map(
                      (size) =>
                          DropdownMenuItem(value: size, child: Text(size)),
                    )
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _syringeSize = value!;
                    _calculate();
                  });
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: DropdownButtonFormField<String?>(
                value: _targetVialSize,
                decoration: const InputDecoration(
                  labelText: 'Target Vial (Optional)',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                items: _vialSizes
                    .map(
                      (size) => DropdownMenuItem(
                        value: size,
                        child: Text(size ?? 'None'),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _targetVialSize = value;
                    _calculate();
                  });
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              flex: 2,
              child: TextFormField(
                controller: _desiredDoseController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Desired dose (optional)',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                onChanged: (_) => _calculate(),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: DropdownButtonFormField<String>(
                value: _doseUnit,
                decoration: const InputDecoration(
                  labelText: 'Dose unit',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                items: _doseUnits
                    .map((u) => DropdownMenuItem(value: u, child: Text(u)))
                    .toList(),
                onChanged: (v) {
                  setState(() {
                    _doseUnit = v!;
                    // Note: unit conversion between mg/IU/Units is domain-specific and
                    // not attempted here; this is a display hint for now.
                  });
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_results != null) ...[
          Text(
            'Reconstitution Options:',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          ..._results!.entries.map((entry) {
            final option = entry.key;
            final data = entry.value as Map<String, dynamic>;
            final concentration = data['concentration'] as double;
            final description = data['description'] as String;
            final doseVolume = data['doseVolume'] as double?;
            final withinSyringe = data['withinSyringe'] as bool? ?? true;

            return Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: InkWell(
                onTap: withinSyringe ? () => _selectOption(option) : null,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: withinSyringe
                          ? Colors.grey.shade300
                          : Colors.red.shade200,
                    ),
                    borderRadius: BorderRadius.circular(4),
                    color: withinSyringe ? null : Colors.red.shade50,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              option.toUpperCase(),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              description,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            if (doseVolume != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Row(
                                  children: [
                                    Icon(
                                      withinSyringe
                                          ? Icons.check_circle
                                          : Icons.error_outline,
                                      size: 14,
                                      color: withinSyringe
                                          ? Colors.green
                                          : Colors.red,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Dose vol: ${doseVolume.toStringAsFixed(2)} mL',
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelMedium
                                          ?.copyWith(
                                            color: withinSyringe
                                                ? Colors.green[800]
                                                : Colors.red[800],
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${concentration.toStringAsFixed(2)} $_strengthUnit/mL',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Syringe: $_syringeSize',
                            style: Theme.of(context).textTheme.labelSmall,
                          ),
                        ],
                      ),
                      const SizedBox(width: 6),
                      const Icon(Icons.arrow_forward_ios, size: 16),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ],
    );
  }

  @override
  void dispose() {
    _strengthController.dispose();
    _desiredDoseController.dispose();
    super.dispose();
  }
}
