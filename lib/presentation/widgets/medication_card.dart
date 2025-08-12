import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:dosifi_flutter/data/models/medication.dart';
import 'package:dosifi_flutter/presentation/providers/medication_layout_provider.dart';
import 'package:dosifi_flutter/core/widgets/compact_card.dart';
import 'package:dosifi_flutter/core/widgets/label_chip.dart';

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

  const MedicationCard({super.key, required this.medication, this.onTap, this.onEdit, this.onDelete, this.forceLayout});

  @override
  Widget build(BuildContext context) {
    // Always use the finalized signature card design for a consistent look across the app.
    return _buildSignatureCard(context);
  }

  // Signature, unified premium card design used across all variants
  Widget _buildSignatureCard(BuildContext context) {
    final Color typeColor = _getTypeColor();
    final bool showExpiry = medication.expirationDate != null;

    // Compute stock indicator to match Medication Details screen logic
    final _StockIndicator ind = _computeStockIndicator(medication);
    final String unit = medication.stockUnit?.displayName ?? '';

    return InkWell(
      onTap: () {
        if (onTap != null) {
          onTap!();
        } else if (medication.id != null) {
          context.push('/medications/${medication.id}');
        }
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.white,
          border: Border.all(color: typeColor.withValues(alpha: 0.25), width: 1),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 12, offset: const Offset(0, 6)),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Leading icon
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: typeColor.withValues(alpha: 0.10),
                    border: Border.all(color: typeColor.withValues(alpha: 0.30)),
                  ),
                  alignment: Alignment.center,
                  child: Icon(_getTypeIcon(), size: 22, color: typeColor),
                ),
                const SizedBox(width: 12),
                // Main content (left)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title row
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              medication.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.2,
                                fontSize: 16,
                                color: Colors.black,
                              ),
                            ),
                          ),
                          // Compact indicators (expiry, storage)
                          ..._buildCompactAlerts(),
                          ..._buildCompactStorageIndicators(),
                        ],
                      ),
                      const SizedBox(height: 6),

                      // Strength and Type as plain text
                      Text(
                        'Strength: ${medication.displayStrength}',
                        style: TextStyle(fontSize: 12, color: Colors.grey[800], fontWeight: FontWeight.w600),
                      ),
                      Text(
                        'Type: ${medication.type.displayName}',
                        style: TextStyle(fontSize: 12, color: Colors.grey[700], fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),

                // Vertical divider on the right between content and trailing
                const SizedBox(width: 12),
                Container(width: 1, height: 48, color: Colors.grey.withValues(alpha: 0.25)),
                const SizedBox(width: 12),

                // Trailing column (right)
                ConstrainedBox(
                  constraints: const BoxConstraints(minWidth: 90, maxWidth: 140),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // Quantity current and unit
                      Text(
                        '${medication.stockQuantity.toStringAsFixed(0)} $unit',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
                        textAlign: TextAlign.right,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (showExpiry)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            DateFormat('MMM yy').format(medication.expirationDate!),
                            style: TextStyle(color: _getExpiryColor(), fontWeight: FontWeight.w700, fontSize: 11),
                            textAlign: TextAlign.right,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            // Bottom progress bar using same styling as details screen stock indicator
            const SizedBox(height: 10),
            LinearProgressIndicator(
              value: ind.percentage,
              backgroundColor: ind.color.withValues(alpha: 0.3),
              valueColor: AlwaysStoppedAnimation<Color>(ind.color),
              minHeight: 2,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactCard(BuildContext context) {
    return CompactCard(
      accentColor: _getTypeColor(),
      onTap: () {
        if (onTap != null) {
          onTap!();
        } else if (medication.id != null) {
          context.push('/medications/${medication.id}');
        }
      },
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _getTypeColor().withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _getTypeColor().withValues(alpha: 0.2), width: 0.8),
            ),
            alignment: Alignment.center,
            child: Icon(_getTypeIcon(), size: 18, color: _getTypeColor()),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        medication.name,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (medication.expirationDate != null)
                      LabelChip(
                        icon: Icons.event,
                        label: DateFormat('MMM yy').format(medication.expirationDate!),
                        color: _getExpiryColor(),
                      ),
                  ],
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    LabelChip(
                      icon: Icons.local_fire_department,
                      label: medication.displayStrength,
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                    LabelChip(icon: Icons.category, label: medication.type.displayName, color: _getTypeColor()),
                    const Spacer(),
                    Text(
                      medication.stockDisplay,
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w800, color: _getStockColor()),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 1) Psychedelic neon gradient card (loud, outside-the-box)
  Widget _buildPsychedelicGradientCard(BuildContext context) {
    final c1 = const Color(0xFF6A00F4);
    final c2 = const Color(0xFFFF1CF7);
    final c3 = const Color(0xFF00E5FF);
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(colors: [c1, c2, c3], begin: Alignment.topLeft, end: Alignment.bottomRight),
        boxShadow: [
          BoxShadow(color: c2.withValues(alpha: 0.3), blurRadius: 24, offset: const Offset(0, 12)),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          if (onTap != null) {
            onTap!();
          } else if (medication.id != null) {
            context.push('/medications/${medication.id}');
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              CircleAvatar(radius: 24, backgroundColor: Colors.white.withValues(alpha: 0.2), child: Icon(_getTypeIcon(), color: Colors.white, size: 22)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(medication.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: -0.3)),
                  const SizedBox(height: 6),
                  Text('${medication.type.displayName} • ${medication.displayStrength}', style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 13, fontWeight: FontWeight.w600)),
                ]),
              ),
              const SizedBox(width: 10),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text(medication.stockDisplay, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w900)),
                if (medication.expirationDate != null)
                  Text(DateFormat('MMM yy').format(medication.expirationDate!), style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 12, fontWeight: FontWeight.bold)),
              ]),
            ],
          ),
        ),
      ),
    );
  }

  // 2) Glassmorphism frosted card
  Widget _buildGlassmorphismCard(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white.withValues(alpha: 0.18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.45), width: 1),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 18, offset: const Offset(0, 10))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () {
            if (onTap != null) {
              onTap!();
            } else if (medication.id != null) {
              context.push('/medications/${medication.id}');
            }
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [Colors.white.withValues(alpha: 0.20), Colors.white.withValues(alpha: 0.08)], begin: Alignment.topLeft, end: Alignment.bottomRight),
            ),
            child: Row(children: [
              Container(width: 44, height: 44, decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white.withValues(alpha: 0.35))), alignment: Alignment.center, child: Icon(_getTypeIcon(), color: Colors.white, size: 20)),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(medication.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
                const SizedBox(height: 4),
                Text('${medication.type.displayName} • ${medication.displayStrength}', style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 12)),
              ])),
              const SizedBox(width: 10),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text(medication.stockDisplay, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
                if (medication.expirationDate != null)
                  Text(DateFormat('MM/yy').format(medication.expirationDate!), style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 12)),
              ]),
            ]),
          ),
        ),
      ),
    );
  }

  // 3) Retro terminal card (monospace, green on black)
  Widget _buildRetroTerminalCard(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(color: const Color(0xFF0A0F0A), borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFF00FF88), width: 1.5), boxShadow: [BoxShadow(color: const Color(0xFF00FF88).withValues(alpha: 0.15), blurRadius: 12)]),
      child: InkWell(
        onTap: () {
          if (onTap != null) {
            onTap!();
          } else if (medication.id != null) {
            context.push('/medications/${medication.id}');
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(children: [
            const Icon(Icons.terminal, color: Color(0xFF00FF88), size: 20),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [
              // Using const style; values below are dynamic text with same style applied
            ])),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text(medication.stockDisplay, style: const TextStyle(color: Color(0xFF00FF88), fontFamily: 'RobotoMono', fontWeight: FontWeight.w800)),
            ]),
          ]),
        ),
      ),
    );
  }

  // Helper to render the terminal text lines (dynamic)
  Widget _terminalText(String text) => Text(text, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xFF00FF88), fontFamily: 'RobotoMono', fontSize: 13));

  // 4) Neumorphic soft card (light grey, soft shadows)
  Widget _buildNeumorphicSoftCard(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFEFEFF4),
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(color: Color(0xFFFFFFFF), offset: Offset(-6, -6), blurRadius: 12),
          BoxShadow(color: Color(0xFFCDD1D5), offset: Offset(6, 6), blurRadius: 12),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () {
          if (onTap != null) {
            onTap!();
          } else if (medication.id != null) {
            context.push('/medications/${medication.id}');
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(children: [
            Container(width: 44, height: 44, decoration: BoxDecoration(color: const Color(0xFFEFEFF4), borderRadius: BorderRadius.circular(12), boxShadow: const [BoxShadow(color: Colors.white, offset: Offset(-3, -3), blurRadius: 6), BoxShadow(color: Color(0xFFCDD1D5), offset: Offset(3, 3), blurRadius: 6)]), alignment: Alignment.center, child: Icon(_getTypeIcon(), color: const Color(0xFF60636A))),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [
            ])),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text(medication.stockDisplay, style: const TextStyle(color: Color(0xFF3A3D42), fontWeight: FontWeight.w900)),
              if (medication.expirationDate != null)
                Text(DateFormat('MMM yy').format(medication.expirationDate!), style: const TextStyle(color: Color(0xFF6B6F76), fontSize: 12)),
            ]),
          ]),
        ),
      ),
    );
  }

  // 5) Wireframe black/white card
  Widget _buildWireframeCard(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.black, width: 2), boxShadow: const [BoxShadow(color: Colors.black, offset: Offset(2, 2), blurRadius: 0)]),
      child: InkWell(
        onTap: () {
          if (onTap != null) {
            onTap!();
          } else if (medication.id != null) {
            context.push('/medications/${medication.id}');
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(children: [
            Container(width: 36, height: 36, decoration: BoxDecoration(border: Border.all(color: Colors.black, width: 2), borderRadius: BorderRadius.circular(6)), alignment: Alignment.center, child: Icon(_getTypeIcon(), color: Colors.black, size: 18)),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(medication.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.black, fontSize: 15, fontWeight: FontWeight.w900, letterSpacing: -0.2)),
              Text('${medication.type.displayName} • ${medication.displayStrength}', style: const TextStyle(color: Colors.black, fontSize: 12, fontWeight: FontWeight.w600)),
            ])),
            const SizedBox(width: 10),
            Text(medication.stockDisplay, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w900)),
          ]),
        ),
      ),
    );
  }

  // 6) Sticker card (rounded, playful background)
  Widget _buildStickerCard(BuildContext context) {
    final bg = const LinearGradient(colors: [Color(0xFFFFF8E1), Color(0xFFFFECB3)], begin: Alignment.topLeft, end: Alignment.bottomRight);
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        gradient: bg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFFFD54F), width: 2),
        boxShadow: const [BoxShadow(color: Color(0x33FFC107), blurRadius: 12, offset: Offset(0, 6))],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () {
          if (onTap != null) {
            onTap!();
          } else if (medication.id != null) {
            context.push('/medications/${medication.id}');
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(children: [
            CircleAvatar(radius: 22, backgroundColor: const Color(0xFFFFF176), child: Icon(_getTypeIcon(), color: const Color(0xFFF57F17))),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [])),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text(medication.stockDisplay, style: const TextStyle(color: Color(0xFF5D4037), fontWeight: FontWeight.w900)),
              if (medication.expirationDate != null)
                Text(DateFormat('MMM yy').format(medication.expirationDate!), style: const TextStyle(color: Color(0xFF8D6E63), fontSize: 12)),
            ]),
          ]),
        ),
      ),
    );
  }

  Widget _buildTileCard(BuildContext context) {
    // Unused with outlined-only variants; keep for compatibility if referenced elsewhere.
    return const SizedBox.shrink();
  }

  Widget _buildOutlinedCard(BuildContext context) {
    return InkWell(
      onTap: () {
        if (onTap != null) {
          onTap!();
        } else if (medication.id != null) {
          context.push('/medications/${medication.id}');
        }
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
          color: Colors.white,
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: _getTypeColor().withValues(alpha: 0.10),
              ),
              alignment: Alignment.center,
              child: Icon(_getTypeIcon(), size: 18, color: _getTypeColor()),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(medication.name, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text('${medication.type.displayName} • ${medication.displayStrength}', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Colors.grey[600])),
                ],
              ),
            ),
            Text(medication.stockDisplay, style: Theme.of(context).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w800, color: _getStockColor())),
            const SizedBox(width: 6),
            const Icon(Icons.chevron_right, size: 18, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildOutlinedSoftCard(BuildContext context) {
    return InkWell(
      onTap: () {
        if (onTap != null) {
          onTap!();
        } else if (medication.id != null) {
          context.push('/medications/${medication.id}');
        }
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade300),
          color: Colors.white,
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: _getTypeColor().withValues(alpha: 0.08),
              ),
              alignment: Alignment.center,
              child: Icon(_getTypeIcon(), size: 20, color: _getTypeColor()),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(medication.name, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      LabelChip(icon: Icons.category, label: medication.type.displayName, color: _getTypeColor()),
                      LabelChip(icon: Icons.local_fire_department, label: medication.displayStrength, color: Theme.of(context).colorScheme.secondary),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(medication.stockDisplay, style: Theme.of(context).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w800, color: _getStockColor())),
                if (medication.isExpiringSoon || medication.isExpired) ..._buildCompactAlerts(),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOutlinedShadowCard(BuildContext context) {
    return InkWell(
      onTap: () {
        if (onTap != null) {
          onTap!();
        } else if (medication.id != null) {
          context.push('/medications/${medication.id}');
        }
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
          color: Colors.white,
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 2)),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: _getTypeColor().withValues(alpha: 0.10),
              ),
              alignment: Alignment.center,
              child: Icon(_getTypeIcon(), size: 18, color: _getTypeColor()),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(medication.name, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 2),
                  Text('${medication.type.displayName} • ${medication.displayStrength}', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Colors.grey[600])),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(medication.stockDisplay, style: Theme.of(context).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w800, color: _getStockColor())),
                const SizedBox(height: 4),
                const Icon(Icons.chevron_right, size: 18, color: Colors.grey),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOutlinedAccentCard(BuildContext context) {
    return InkWell(
      onTap: () {
        if (onTap != null) {
          onTap!();
        } else if (medication.id != null) {
          context.push('/medications/${medication.id}');
        }
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _getTypeColor().withValues(alpha: 0.35)),
          color: Colors.white,
        ),
        child: Row(
          children: [
            Container(
              width: 4,
              height: 44,
              decoration: BoxDecoration(
                color: _getTypeColor(),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(medication.name, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text('${medication.type.displayName} • ${medication.displayStrength}', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Colors.grey[600])),
                ],
              ),
            ),
            Text(medication.stockDisplay, style: Theme.of(context).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w800, color: _getStockColor())),
            const SizedBox(width: 6),
            const Icon(Icons.chevron_right, size: 18, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildOutlinedPillCard(BuildContext context) {
    return InkWell(
      onTap: () {
        if (onTap != null) {
          onTap!();
        } else if (medication.id != null) {
          context.push('/medications/${medication.id}');
        }
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: Colors.grey.shade300),
          color: Colors.white,
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: _getTypeColor().withValues(alpha: 0.10),
              child: Icon(_getTypeIcon(), size: 18, color: _getTypeColor()),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(medication.name, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                  Text('${medication.type.displayName} • ${medication.displayStrength}', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Colors.grey[600])),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: _getStockColor().withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Text(medication.stockDisplay, style: TextStyle(color: _getStockColor(), fontWeight: FontWeight.bold, fontSize: 12)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOutlinedDenseCard(BuildContext context) {
    return InkWell(
      onTap: () {
        if (onTap != null) {
          onTap!();
        } else if (medication.id != null) {
          context.push('/medications/${medication.id}');
        }
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.shade300, width: 0.9),
          color: Colors.white,
        ),
        child: Row(
          children: [
            Icon(_getTypeIcon(), size: 18, color: _getTypeColor()),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '${medication.name}  •  ${medication.displayStrength}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(width: 8),
            Text(medication.stockDisplay, style: TextStyle(color: _getStockColor(), fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildOutlinedDividerCard(BuildContext context) {
    return InkWell(
      onTap: () {
        if (onTap != null) {
          onTap!();
        } else if (medication.id != null) {
          context.push('/medications/${medication.id}');
        }
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
          color: Colors.white,
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: _getTypeColor().withValues(alpha: 0.10),
              ),
              alignment: Alignment.center,
              child: Icon(_getTypeIcon(), size: 18, color: _getTypeColor()),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(medication.name, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text('${medication.type.displayName} • ${medication.displayStrength}', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Colors.grey[600])),
                ],
              ),
            ),
            Container(width: 1, height: 24, color: Colors.grey.shade300),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(medication.stockDisplay, style: Theme.of(context).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w800, color: _getStockColor())),
                if (medication.expirationDate != null)
                  Text(DateFormat('MMM yy').format(medication.expirationDate!), style: Theme.of(context).textTheme.labelSmall?.copyWith(color: _getExpiryColor())),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOutlinedMonochromeCard(BuildContext context) {
    final Color mono = Colors.grey.shade700;
    return InkWell(
      onTap: () {
        if (medication.id != null) {
          context.push('/edit-medication/${medication.id}');
        }
        onTap?.call();
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
          color: Colors.white,
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: Colors.grey.shade100,
                border: Border.all(color: Colors.grey.shade300),
              ),
              alignment: Alignment.center,
              child: Icon(_getTypeIcon(), size: 18, color: mono),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(medication.name, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800, color: Colors.black87)),
                  const SizedBox(height: 2),
                  Text('${medication.type.displayName} • ${medication.displayStrength}', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Colors.grey[700])),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(medication.stockDisplay, style: Theme.of(context).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w800, color: Colors.black87)),
                if (medication.brandManufacturer != null)
                  Text(medication.brandManufacturer!, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Colors.grey[700])),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOutlinedCompactChipsCard(BuildContext context) {
    return InkWell(
      onTap: () {
        if (onTap != null) {
          onTap!();
        } else if (medication.id != null) {
          context.push('/medications/${medication.id}');
        }
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
          color: Colors.white,
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: _getTypeColor().withValues(alpha: 0.10),
              ),
              alignment: Alignment.center,
              child: Icon(_getTypeIcon(), size: 18, color: _getTypeColor()),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(medication.name, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700), maxLines: 1, overflow: TextOverflow.ellipsis),
                      ),
                      Wrap(spacing: 4, children: _buildCompactAlerts()),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      LabelChip(icon: Icons.category, label: medication.type.displayName, color: _getTypeColor()),
                      LabelChip(icon: Icons.local_fire_department, label: medication.displayStrength, color: Theme.of(context).colorScheme.secondary),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(medication.stockDisplay, style: Theme.of(context).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w800, color: _getStockColor())),
                const Icon(Icons.chevron_right, size: 18, color: Colors.grey),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOutlinedLargeTitleCard(BuildContext context) {
    return InkWell(
      onTap: () {
        if (onTap != null) {
          onTap!();
        } else if (medication.id != null) {
          context.push('/medications/${medication.id}');
        }
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
          color: Colors.white,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: _getTypeColor().withValues(alpha: 0.10),
              ),
              alignment: Alignment.center,
              child: Icon(_getTypeIcon(), size: 20, color: _getTypeColor()),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(medication.name, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  Text('${medication.type.displayName} • ${medication.displayStrength}', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[700])),
                  if (medication.brandManufacturer != null)
                    Text('by ${medication.brandManufacturer}', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Colors.grey[600])),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(medication.stockDisplay, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w900, color: _getStockColor())),
                if (medication.expirationDate != null)
                  Text('Exp ${DateFormat('MM/yy').format(medication.expirationDate!)}', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: _getExpiryColor())),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMinimalCard(BuildContext context) {
    return ListTile(
      onTap: () {
        if (onTap != null) {
          onTap!();
        } else if (medication.id != null) {
          context.push('/medications/${medication.id}');
        }
      },
      dense: true,
      visualDensity: VisualDensity.compact,
      leading: Icon(_getTypeIcon(), color: _getTypeColor()),
      title: Text(medication.name, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text('${medication.displayStrength} • ${medication.type.displayName}'),
      trailing: Text(medication.stockDisplay, style: TextStyle(color: _getStockColor(), fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildGradientBarCard(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _getTypeColor().withValues(alpha: 0.2)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          if (onTap != null) {
            onTap!();
          } else if (medication.id != null) {
            context.push('/medications/${medication.id}');
          }
        },
        child: Row(
          children: [
            Container(
              width: 8,
              height: 72,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [_getTypeColor(), _getTypeColor().withValues(alpha: 0.5)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: const BorderRadius.horizontal(left: Radius.circular(14)),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(medication.name, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700), maxLines: 1, overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 2),
                          Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            children: [
                              LabelChip(icon: Icons.local_fire_department, label: medication.displayStrength, color: Theme.of(context).colorScheme.secondary),
                              LabelChip(icon: Icons.category, label: medication.type.displayName, color: _getTypeColor()),
                              ..._buildCompactAlerts(),
                              ..._buildCompactStorageIndicators(),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(medication.stockDisplay, style: Theme.of(context).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w800, color: _getStockColor())),
                        const SizedBox(height: 6),
                        const Icon(Icons.chevron_right, size: 18, color: Colors.grey),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLargeCard(BuildContext context) {
    // Unused with outlined-only variants; keep for compatibility if referenced elsewhere.
    return const SizedBox.shrink();
  }

  Widget _buildAlertChip(String label, Color bgColor, Color textColor) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(12)),
      child: Text(
        label,
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: textColor),
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
        style: TextStyle(color: textColor, fontSize: 11, fontWeight: FontWeight.w600),
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
        style: TextStyle(color: textColor, fontSize: 12, fontWeight: FontWeight.w600),
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
            Icon(icon, size: 16, color: Colors.grey[600]),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w500),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
      ],
    );
  }

  bool _shouldShowAlerts() {
    return medication.isExpired || medication.isExpiringSoon || (medication.alertOnLowStock && _isLowStock());
  }

  bool _isLowStock() {
    // Simple low stock logic - in a real app this would be configurable
    return medication.stockQuantity < 5;
  }

  Widget _buildAlertsRow() {
    final List<Widget> alerts = [];

    if (medication.isExpired) {
      alerts.add(_buildAlert('EXPIRED', Colors.red, Icons.error));
    } else if (medication.isExpiringSoon) {
      alerts.add(_buildAlert('EXPIRES SOON', Colors.orange, Icons.warning));
    }

    if (medication.alertOnLowStock && _isLowStock()) {
      alerts.add(_buildAlert('LOW STOCK', Colors.amber, Icons.inventory_2));
    }

    return Wrap(spacing: 8, runSpacing: 4, children: alerts);
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
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }

  bool _shouldShowStorageIndicators() {
    return medication.requiresRefrigeration || medication.reconstitutionVolume != null;
  }

  Widget _buildStorageIndicators() {
    final List<Widget> indicators = [];

    if (medication.requiresRefrigeration) {
      indicators.add(_buildStorageIndicator('Refrigerate', Icons.ac_unit, Colors.blue));
    }

    if (medication.reconstitutionVolume != null) {
      indicators.add(_buildStorageIndicator('Reconstituted', Icons.science, Colors.purple));
    }

    return Wrap(spacing: 8, runSpacing: 4, children: indicators);
  }

  Widget _buildStorageIndicator(String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: color),
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
    // Align with MedicationViewScreen._getMedicationTypeColor
    switch (medication.type) {
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
    // Keep quick text color logic; progress bar uses detailed indicator
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
    final List<Widget> alerts = [];

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
    final List<Widget> indicators = [];

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
      decoration: BoxDecoration(color: color.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(2)),
      child: Icon(icon, size: 8, color: color),
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

  // Match stock indicator logic from MedicationViewScreen
  _StockIndicator _computeStockIndicator(Medication med) {
    final double threshold = med.lowStockThreshold ?? _getDefaultLowStockThreshold(med);
    final double current = med.stockQuantity;
    final double pct = (current / (threshold * 2)).clamp(0.0, 1.0);

    Color color;
    if (current <= threshold * 0.25) {
      color = Colors.red;
    } else if (current <= threshold) {
      color = Colors.orange;
    } else if (current <= threshold * 1.5) {
      color = Colors.yellow;
    } else {
      color = Colors.green;
    }
    return _StockIndicator(percentage: pct, color: color);
  }

  double _getDefaultLowStockThreshold(Medication med) {
    switch (med.type) {
      case MedicationType.tablet:
      case MedicationType.capsule:
        return 7.0; // week supply
      case MedicationType.liquid:
      case MedicationType.drops:
        return 30.0; // mL
      case MedicationType.preFilledSyringe:
        return 3.0;
      case MedicationType.readyMadeVial:
        return 5.0; // mL
      case MedicationType.lyophilizedVial:
        return 1.0; // vial
      case MedicationType.cream:
      case MedicationType.ointment:
      case MedicationType.gel:
        return 15.0; // grams
      case MedicationType.patch:
        return 3.0;
      case MedicationType.inhaler:
        return 20.0; // doses
      case MedicationType.suppository:
        return 3.0;
      case MedicationType.singleUsePen:
        return 2.0;
      case MedicationType.multiUsePen:
        return 1.0;
      case MedicationType.spray:
        return 10.0; // sprays
      case MedicationType.other:
        return 5.0;
    }
  }
}

class _StockIndicator {
  final double percentage;
  final Color color;
  _StockIndicator({required this.percentage, required this.color});
}
