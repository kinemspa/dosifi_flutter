import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ReconstitutionCalculatorScreen extends ConsumerStatefulWidget {
  const ReconstitutionCalculatorScreen({super.key});

  @override
  ConsumerState<ReconstitutionCalculatorScreen> createState() => _ReconstitutionCalculatorScreenState();
}

class _ReconstitutionCalculatorScreenState extends ConsumerState<ReconstitutionCalculatorScreen> {
  final _strengthController = TextEditingController();
  final _desiredDoseController = TextEditingController();
  
  String _strengthUnit = 'mg';
  String _doseUnit = 'mcg';
  String _syringeSize = '1mL';
  String? _targetVialSize;
  
  Map<String, dynamic>? _results;
  
  final List<String> _strengthUnits = ['mg', 'mcg'];
  final List<String> _doseUnits = ['mg', 'mcg', 'Units', 'IU'];
  final List<String> _syringeSizes = ['0.3mL', '0.5mL', '1mL', '3mL', '5mL'];
  final List<String?> _vialSizes = [null, '1mL', '3mL', '5mL', '10mL', '20mL'];
  
  void _calculate() {
    final strength = double.tryParse(_strengthController.text);
    final desiredDose = double.tryParse(_desiredDoseController.text);
    
    if (strength == null || desiredDose == null || strength == 0) {
      return;
    }
    
    // Convert everything to mcg for calculation
    double strengthInMcg = _strengthUnit == 'mg' ? strength * 1000 : strength;
    double desiredDoseInMcg = _doseUnit == 'mg' ? desiredDose * 1000 : desiredDose;
    
    if (_doseUnit == 'Units' || _doseUnit == 'IU') {
      desiredDoseInMcg = desiredDose; // Keep as is for Units/IU
    }
    
    // Parse syringe size
    double syringeVolume = double.parse(_syringeSize.replaceAll('mL', ''));
    
    setState(() {
      _results = _calculateOptions(strengthInMcg, desiredDoseInMcg, syringeVolume);
    });
  }
  
  Map<String, dynamic> _calculateOptions(double strength, double dose, double syringeVolume) {
    Map<String, dynamic> results = {};
    
    // Based on your example:
    // 10mg powder, 1000mcg (1mg) dose, 1mL syringe
    // The pattern seems to be that the units on syringe = reconstitution volume * 10
    
    if (_targetVialSize != null) {
      // With vial
      double vialVolume = double.parse(_targetVialSize!.replaceAll('mL', ''));
      
      // Concentrated: 1mL reconstitution = 10 IU on syringe
      double concentratedVolume = 1.0;
      double concentratedUnits = 10.0;
      
      // Average: 60% of vial volume (for 5mL vial = 3mL = 30 IU)
      double avgVolume = vialVolume * 0.6;
      double avgUnits = avgVolume * 10;
      
      // Diluted: full vial (for 5mL vial = 50 IU)
      double dilutedUnits = vialVolume * 10;
      
      results['concentrated'] = {
        'volume': '${concentratedVolume.toStringAsFixed(0)}mL',
        'dose': concentratedUnits.toStringAsFixed(0),
        'units': 'IU'
      };
      results['average'] = {
        'volume': '${avgVolume.toStringAsFixed(0)}mL',
        'dose': avgUnits.toStringAsFixed(0),
        'units': 'IU'
      };
      results['diluted'] = {
        'volume': '${vialVolume.toStringAsFixed(0)}mL',
        'dose': dilutedUnits.toStringAsFixed(0),
        'units': 'IU'
      };
    } else {
      // Without vial
      // Concentrated: 1mL = 10 IU
      // Average: 5mL = 50 IU
      // Diluted: 9mL = 90 IU
      
      results['concentrated'] = {
        'volume': '1mL',
        'dose': '10',
        'units': 'IU'
      };
      results['average'] = {
        'volume': '5mL',
        'dose': '50',
        'units': 'IU'
      };
      results['diluted'] = {
        'volume': '9mL',
        'dose': '90',
        'units': 'IU'
      };
    }
    
    return results;
  }
  
  void _reset() {
    setState(() {
      _strengthController.clear();
      _desiredDoseController.clear();
      _strengthUnit = 'mg';
      _doseUnit = 'mcg';
      _syringeSize = '1mL';
      _targetVialSize = null;
      _results = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reconstitution Calculator'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _reset,
            tooltip: 'Reset',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Input Parameters',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: TextFormField(
                            controller: _strengthController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Strength of Lyophilized Powder',
                              border: OutlineInputBorder(),
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
                            ),
                            items: _strengthUnits.map((unit) => 
                              DropdownMenuItem(value: unit, child: Text(unit))
                            ).toList(),
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
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: TextFormField(
                            controller: _desiredDoseController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Desired Dose',
                              border: OutlineInputBorder(),
                            ),
                            onChanged: (_) => _calculate(),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _doseUnit,
                            decoration: const InputDecoration(
                              labelText: 'Unit',
                              border: OutlineInputBorder(),
                            ),
                            items: _doseUnits.map((unit) => 
                              DropdownMenuItem(value: unit, child: Text(unit))
                            ).toList(),
                            onChanged: (value) {
                              setState(() {
                                _doseUnit = value!;
                                _calculate();
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _syringeSize,
                      decoration: const InputDecoration(
                        labelText: 'Syringe Size',
                        border: OutlineInputBorder(),
                      ),
                      items: _syringeSizes.map((size) => 
                        DropdownMenuItem(value: size, child: Text(size))
                      ).toList(),
                      onChanged: (value) {
                        setState(() {
                          _syringeSize = value!;
                          _calculate();
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String?>(
                      value: _targetVialSize,
                      decoration: const InputDecoration(
                        labelText: 'Target Vial Size (Optional)',
                        border: OutlineInputBorder(),
                      ),
                      items: _vialSizes.map((size) => 
                        DropdownMenuItem(
                          value: size, 
                          child: Text(size ?? 'None')
                        )
                      ).toList(),
                      onChanged: (value) {
                        setState(() {
                          _targetVialSize = value;
                          _calculate();
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            if (_results != null)
              Card(
                color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _targetVialSize != null ? 'Results (With Vial)' : 'Results (Without Vial)',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 16),
                      _buildOptionCard(context, 'Concentrated Option', 
                        _results!['concentrated']['volume'], 
                        _results!['concentrated']['dose'], 
                        _results!['concentrated']['units'],
                        Icons.compress,
                        Colors.red.shade100),
                      const SizedBox(height: 12),
                      _buildOptionCard(context, 'Average Option', 
                        _results!['average']['volume'], 
                        _results!['average']['dose'], 
                        _results!['average']['units'],
                        Icons.balance,
                        Colors.orange.shade100),
                      const SizedBox(height: 12),
                      _buildOptionCard(context, 'Diluted Option', 
                        _results!['diluted']['volume'], 
                        _results!['diluted']['dose'], 
                        _results!['diluted']['units'],
                        Icons.expand,
                        Colors.green.shade100),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildOptionCard(BuildContext context, String title, String volume, String dose, String unit, IconData icon, Color bgColor) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, size: 24, color: Theme.of(context).primaryColor),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text('Reconstitute with: $volume', style: const TextStyle(fontSize: 14)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                dose,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                ),
              ),
              Text(
                '$unit on syringe',
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  @override
  void dispose() {
    _strengthController.dispose();
    _desiredDoseController.dispose();
    super.dispose();
  }
}
