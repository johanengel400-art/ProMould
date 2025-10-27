// lib/widgets/oee_gauge.dart
// OEE (Overall Equipment Effectiveness) gauge widget

import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';

class OEEGauge extends StatelessWidget {
  final double oeePercentage;
  final String label;
  
  const OEEGauge({
    super.key,
    required this.oeePercentage,
    this.label = 'OEE',
  });

  @override
  Widget build(BuildContext context) {
    final color = _getOEEColor(oeePercentage);
    
    return SfRadialGauge(
      axes: <RadialAxis>[
        RadialAxis(
          minimum: 0,
          maximum: 100,
          showLabels: false,
          showTicks: false,
          startAngle: 180,
          endAngle: 0,
          radiusFactor: 0.9,
          axisLineStyle: AxisLineStyle(
            thickness: 0.15,
            color: Colors.white.withOpacity(0.1),
            thicknessUnit: GaugeSizeUnit.factor,
          ),
          pointers: <GaugePointer>[
            RangePointer(
              value: oeePercentage,
              width: 0.15,
              sizeUnit: GaugeSizeUnit.factor,
              gradient: SweepGradient(
                colors: [
                  color.withOpacity(0.5),
                  color,
                ],
              ),
              cornerStyle: CornerStyle.bothCurve,
            ),
          ],
          annotations: <GaugeAnnotation>[
            GaugeAnnotation(
              widget: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${oeePercentage.toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _getOEEStatus(oeePercentage),
                    style: TextStyle(
                      fontSize: 12,
                      color: color,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              angle: 90,
              positionFactor: 0.5,
            ),
          ],
        ),
      ],
    );
  }
  
  Color _getOEEColor(double oee) {
    if (oee >= 85) return const Color(0xFF00D26A); // World Class
    if (oee >= 60) return const Color(0xFF80ED99); // Good
    if (oee >= 40) return const Color(0xFFFFD166); // Fair
    return const Color(0xFFFF6B6B); // Poor
  }
  
  String _getOEEStatus(double oee) {
    if (oee >= 85) return 'World Class';
    if (oee >= 60) return 'Good';
    if (oee >= 40) return 'Fair';
    return 'Needs Improvement';
  }
}
