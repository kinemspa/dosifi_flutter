import 'package:flutter/material.dart';
import 'package:dosifi_flutter/presentation/widgets/embedded_reconstitution_calculator.dart';

class ReconstitutionCalculatorScreen extends StatelessWidget {
  const ReconstitutionCalculatorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reconstitution Calculator'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: const EmbeddedReconstitutionCalculator(),
      ),
    );
  }
}

