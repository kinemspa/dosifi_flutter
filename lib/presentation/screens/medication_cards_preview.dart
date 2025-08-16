import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:dosifi_flutter/data/models/medication.dart';
import 'package:dosifi_flutter/core/widgets/info_sheet.dart';

class MedicationCardsPreviewScreen extends StatelessWidget {
  const MedicationCardsPreviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final samples = _buildSampleMeds();

    // Define 20 mixed styles based on favorites (Photo Placeholder, Color Block Left, Outline Divider, Large Title + progress)
    final styles = <_PreviewStyle>[
      _PreviewStyle('1) Photo + Bottom Progress', _mixPhotoProgress),
      _PreviewStyle('2) Photo + Badge + Progress', _mixPhotoProgressAlt),
      _PreviewStyle('3) Photo Glass + Progress', _mixPhotoGlass),
      _PreviewStyle('4) Photo Shadow + Progress', _mixPhotoShadow),

      _PreviewStyle('5) Color Block Left + Progress', _mixColorBlockLT),
      _PreviewStyle('6) Color Block Bold + Progress', _mixColorBlockBold),
      _PreviewStyle('7) Color Block Soft + Progress', _mixColorBlockSoft),
      _PreviewStyle('8) Color Block Icon + Progress', _mixColorBlockIcon),

      _PreviewStyle('9) Outlined Divider + Progress', _mixOutlinedDividerLT),
      _PreviewStyle(
        '10) Outlined Divider Chips + Progress',
        _mixOutlinedDividerChips,
      ),
      _PreviewStyle(
        '11) Outlined Divider Fridge + Progress',
        _mixOutlinedDividerFridge,
      ),
      _PreviewStyle(
        '12) Outlined Divider Expiry + Progress',
        _mixOutlinedDividerExp,
      ),

      _PreviewStyle(
        '13) Large Title + Divider + Progress',
        _mixLargeTitleDivider,
      ),
      _PreviewStyle('14) Large Title Badge + Progress', _mixLargeTitleBadge),
      _PreviewStyle(
        '15) Large Title Minimal + Progress',
        _mixLargeTitleMinimal,
      ),
      _PreviewStyle(
        '16) Large Title Icon Right + Progress',
        _mixLargeTitleIconRight,
      ),

      _PreviewStyle('17) Circle Icon + Bottom Progress', _mixCircleProgressBar),
      _PreviewStyle('18) Circle + Photo + Bottom Progress', _mixCirclePhotoBar),
      _PreviewStyle('19) Compact Tile + Bottom Progress', _mixCompactTileBar),
      _PreviewStyle('20) Banner Top + Bottom Progress', _mixBannerBar),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Medication Cards Preview'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            tooltip: 'About this screen',
            onPressed: () {
              InfoSheet.show(
                context,
                title: 'Cards Preview',
                message:
                    'This screen showcases various medication card styles for experimentation. The app uses a unified signature card by default, but these previews help evaluate alternative layouts.',
              );
            },
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: styles.length,
        itemBuilder: (context, i) {
          final style = styles[i];
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                style.title,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              ...samples.map(
                (m) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: style.builder(context, m),
                ),
              ),
              const SizedBox(height: 20),
            ],
          );
        },
      ),
    );
  }

  // --- Mixed preview builders (20) ---
  static double _stockPct(Medication m) {
    final q = m.stockQuantity is num
        ? (m.stockQuantity as num).toDouble()
        : 0.0;
    final pct = ((q % 100) / 100).clamp(0.0, 1.0);
    return pct;
  }

  static Widget _bottomProgressBar(double pct, {Color color = Colors.teal}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: LayoutBuilder(
        builder: (context, c) => Stack(
          children: [
            Container(
              height: 6,
              width: double.infinity,
              color: Colors.grey.shade200,
            ),
            Container(height: 6, width: c.maxWidth * pct, color: color),
          ],
        ),
      ),
    );
  }

  static Widget _labeledBottomBar(
    double pct,
    String label, {
    Color color = Colors.teal,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: LayoutBuilder(
        builder: (context, c) => Stack(
          children: [
            Container(
              height: 18,
              width: double.infinity,
              color: Colors.grey.shade200,
            ),
            Container(height: 18, width: c.maxWidth * pct, color: color),
            Positioned.fill(
              child: Center(
                child: Text(
                  label,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.95),
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                    shadows: [
                      Shadow(
                        color: Colors.black.withValues(alpha: 0.25),
                        blurRadius: 3,
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

  // Photo Placeholder inspired
  static Widget _mixPhotoProgress(BuildContext context, Medication m) {
    final pct = _stockPct(m);
    final color = Colors.teal;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 84,
                height: 72,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: const BorderRadius.horizontal(
                    left: Radius.circular(12),
                  ),
                ),
                child: const Icon(Icons.image, color: Colors.grey),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: _titleSubtitleStock(context, m),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: _bottomProgressBar(pct, color: color),
          ),
        ],
      ),
    );
  }

  static Widget _mixPhotoProgressAlt(BuildContext context, Medication m) {
    final pct = _stockPct(m);
    final color = Colors.indigo;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
        border: Border.all(color: Colors.indigo.shade100),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Stack(
                children: [
                  Container(
                    width: 84,
                    height: 72,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: const BorderRadius.horizontal(
                        left: Radius.circular(12),
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: Center(
                      child: Icon(Icons.photo, color: Colors.indigo.shade200),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.indigo,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'RX',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: _titleSubtitleStock(context, m),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: _bottomProgressBar(pct, color: color),
          ),
        ],
      ),
    );
  }

  static Widget _mixPhotoGlass(BuildContext context, Medication m) {
    final pct = _stockPct(m);
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.45)),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withValues(alpha: 0.20),
                    Colors.white.withValues(alpha: 0.08),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 84,
                    height: 72,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: const BorderRadius.horizontal(
                        left: Radius.circular(16),
                      ),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.35),
                      ),
                    ),
                    alignment: Alignment.center,
                    child: const Icon(Icons.image, color: Colors.white),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: _titleSubtitleStockColored(m, Colors.white),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: _bottomProgressBar(pct, color: Colors.cyanAccent),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _mixPhotoShadow(BuildContext context, Medication m) {
    final pct = _stockPct(m);
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 84,
                height: 72,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: const BorderRadius.horizontal(
                    left: Radius.circular(14),
                  ),
                ),
                child: const Icon(Icons.image_outlined, color: Colors.white70),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: _titleSubtitleStock(context, m),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: _bottomProgressBar(pct, color: Colors.teal),
          ),
        ],
      ),
    );
  }

  // Color Block Left inspired
  static Widget _mixColorBlockLT(BuildContext context, Medication m) {
    final pct = _stockPct(m);
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.blueGrey.shade900,
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(width: 6, height: 52, color: Colors.cyanAccent),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        m.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        '${m.type.displayName} • ${m.displayStrength}',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  m.stockDisplay,
                  style: const TextStyle(
                    color: Colors.cyanAccent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
            child: _bottomProgressBar(pct, color: Colors.cyanAccent),
          ),
        ],
      ),
    );
  }

  static Widget _mixColorBlockBold(BuildContext context, Medication m) {
    final pct = _stockPct(m);
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 56,
                  decoration: const BoxDecoration(color: Color(0xFF67E8F9)),
                ),
                const SizedBox(width: 10),
                Expanded(child: _titleSubtitleStockColored(m, Colors.white)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
            child: _bottomProgressBar(pct, color: const Color(0xFF67E8F9)),
          ),
        ],
      ),
    );
  }

  static Widget _mixColorBlockSoft(BuildContext context, Medication m) {
    final pct = _stockPct(m);
    final accent = Colors.lightBlueAccent;
    return Container(
      decoration: BoxDecoration(
        color: Colors.blueGrey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blueGrey.shade100),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(width: 4, height: 48, color: accent),
                const SizedBox(width: 10),
                Expanded(child: _titleSubtitleStock(context, m)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: _bottomProgressBar(pct, color: accent),
          ),
        ],
      ),
    );
  }

  static Widget _mixColorBlockIcon(BuildContext context, Medication m) {
    final pct = _stockPct(m);
    final accent = Colors.cyan;
    return Container(
      decoration: BoxDecoration(
        color: Colors.blueGrey.shade900,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: const BoxDecoration(
                    color: Colors.cyan,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.local_pharmacy, color: Colors.black),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        m.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        '${m.type.displayName} • ${m.displayStrength}',
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                ),
                Text(
                  m.stockDisplay,
                  style: const TextStyle(
                    color: Colors.cyanAccent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
            child: _bottomProgressBar(pct, color: accent),
          ),
        ],
      ),
    );
  }

  // Outlined Divider inspired
  static Widget _mixOutlinedDividerLT(BuildContext context, Medication m) {
    final pct = _stockPct(m);
    final color = Colors.teal;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
        color: Colors.white,
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.blueGrey.shade50,
                  ),
                  alignment: Alignment.center,
                  child: Icon(Icons.science, color: Colors.blueGrey.shade700),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        m.name,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${m.type.displayName} • ${m.displayStrength}',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(width: 1, height: 28, color: Colors.grey.shade300),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      m.stockDisplay,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: Colors.teal,
                      ),
                    ),
                    if (m.expirationDate != null)
                      Text(
                        DateFormat('MMM yy').format(m.expirationDate!),
                        style: const TextStyle(color: Colors.red),
                      ),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: _bottomProgressBar(pct, color: color),
          ),
        ],
      ),
    );
  }

  static Widget _mixOutlinedDividerChips(BuildContext context, Medication m) {
    final pct = _stockPct(m);
    final color = Colors.indigo;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
        color: Colors.white,
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                const Icon(Icons.medication_outlined),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        m.name,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          _chip(
                            Icons.category,
                            m.type.displayName,
                            Colors.indigo,
                          ),
                          _chip(
                            Icons.local_fire_department,
                            m.displayStrength,
                            Colors.pink,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(width: 1, height: 28, color: Colors.grey.shade300),
                const SizedBox(width: 10),
                Text(
                  m.stockDisplay,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: Colors.indigo,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: _bottomProgressBar(pct, color: color),
          ),
        ],
      ),
    );
  }

  static Widget _mixOutlinedDividerFridge(BuildContext context, Medication m) {
    final pct = _stockPct(m);
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
        color: Colors.white,
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Icon(
                  m.requiresRefrigeration
                      ? Icons.ac_unit
                      : Icons.local_pharmacy,
                  color: m.requiresRefrigeration ? Colors.blue : Colors.teal,
                ),
                const SizedBox(width: 10),
                Expanded(child: _titleSubtitleStock(context, m)),
                Container(width: 1, height: 28, color: Colors.grey.shade300),
                const SizedBox(width: 10),
                Text(
                  m.stockDisplay,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: Colors.teal,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: _bottomProgressBar(
              pct,
              color: m.requiresRefrigeration ? Colors.blue : Colors.teal,
            ),
          ),
        ],
      ),
    );
  }

  static Widget _mixOutlinedDividerExp(BuildContext context, Medication m) {
    final pct = _stockPct(m);
    final isSoon =
        m.expirationDate != null &&
        m.expirationDate!.isBefore(
          DateTime.now().add(const Duration(days: 30)),
        );
    final barColor = isSoon ? Colors.red : Colors.teal;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
        color: Colors.white,
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                const Icon(Icons.science_outlined),
                const SizedBox(width: 10),
                Expanded(child: _titleSubtitleStock(context, m)),
                Container(width: 1, height: 28, color: Colors.grey.shade300),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      m.stockDisplay,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    if (m.expirationDate != null)
                      Text(
                        'Exp ${DateFormat('MM/yy').format(m.expirationDate!)}',
                        style: TextStyle(
                          color: isSoon ? Colors.red : Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: _bottomProgressBar(pct, color: barColor),
          ),
        ],
      ),
    );
  }

  // Large Title inspired
  static Widget _mixLargeTitleDivider(BuildContext context, Medication m) {
    final pct = _stockPct(m);
    final meta = _computeMeta(m);
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
        color: Colors.white,
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: Colors.teal.shade50,
                      ),
                      alignment: Alignment.center,
                      child: Icon(
                        Icons.local_hospital,
                        color: Colors.teal.shade600,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            m.name,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${m.type.displayName} • ${m.displayStrength}',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: Colors.grey[700]),
                          ),
                          if (m.brandManufacturer != null)
                            Text(
                              'by ${m.brandManufacturer}',
                              style: Theme.of(context).textTheme.labelSmall
                                  ?.copyWith(color: Colors.grey[600]),
                            ),
                        ],
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 36,
                      color: Colors.grey.shade300,
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          m.stockDisplay,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                fontWeight: FontWeight.w900,
                                color: Colors.teal,
                              ),
                        ),
                        if (m.expirationDate != null)
                          Text(
                            'Exp ${DateFormat('MM/yy').format(m.expirationDate!)}',
                            style: Theme.of(
                              context,
                            ).textTheme.labelSmall?.copyWith(color: Colors.red),
                          ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                // Metadata row: Last dose, Next dose, ETA run-out, Restock
                Row(
                  children: [
                    _metaItem(Icons.history, 'Last', meta.lastDose),
                    _metaDivider(),
                    _metaItem(Icons.schedule, 'Next', meta.nextDose),
                    _metaDivider(),
                    _metaItem(Icons.hourglass_bottom, 'Run-out', meta.runOut),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.shopping_cart_outlined, size: 16),
                      label: const Text('Restock'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
            child: _labeledBottomBar(
              pct,
              meta.remainingLabel,
              color: Colors.teal,
            ),
          ),
        ],
      ),
    );
  }

  static Widget _mixLargeTitleBadge(BuildContext context, Medication m) {
    final pct = _stockPct(m);
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
        color: Colors.white,
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                const Icon(Icons.medication, color: Colors.teal),
                const SizedBox(width: 12),
                Expanded(child: _titleSubtitleStock(context, m)),
                Container(width: 1, height: 28, color: Colors.grey.shade300),
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.teal.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'ACTIVE',
                    style: TextStyle(
                      color: Colors.teal,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
            child: _bottomProgressBar(pct, color: Colors.teal),
          ),
        ],
      ),
    );
  }

  static Widget _mixLargeTitleMinimal(BuildContext context, Medication m) {
    final pct = _stockPct(m);
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: _titleSubtitleStock(context, m),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
            child: _bottomProgressBar(pct, color: Colors.teal),
          ),
        ],
      ),
    );
  }

  static Widget _mixLargeTitleIconRight(BuildContext context, Medication m) {
    final pct = _stockPct(m);
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
        color: Colors.white,
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Expanded(child: _titleSubtitleStock(context, m)),
                const SizedBox(width: 8),
                const Icon(Icons.chevron_right, size: 18, color: Colors.grey),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
            child: _bottomProgressBar(pct, color: Colors.teal),
          ),
        ],
      ),
    );
  }

  // Circle icon hybrids
  static Widget _mixCircleProgressBar(BuildContext context, Medication m) {
    final pct = _stockPct(m);
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 44,
                      height: 44,
                      child: CircularProgressIndicator(
                        value: pct,
                        strokeWidth: 6,
                        backgroundColor: Colors.grey.shade200,
                        valueColor: const AlwaysStoppedAnimation(Colors.teal),
                      ),
                    ),
                    const Icon(Icons.medication, size: 18),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        m.name,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      Text(
                        '${m.type.displayName} • ${m.displayStrength}',
                        style: const TextStyle(color: Colors.black54),
                      ),
                    ],
                  ),
                ),
                Text(
                  m.stockDisplay,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: _bottomProgressBar(pct, color: Colors.teal),
          ),
        ],
      ),
    );
  }

  static Widget _mixCirclePhotoBar(BuildContext context, Medication m) {
    final pct = _stockPct(m);
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: const BorderRadius.horizontal(
                    left: Radius.circular(12),
                  ),
                ),
                child: const Icon(Icons.image, color: Colors.grey),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(
                            width: 40,
                            height: 40,
                            child: CircularProgressIndicator(
                              value: pct,
                              strokeWidth: 5,
                              backgroundColor: Colors.grey.shade200,
                              valueColor: const AlwaysStoppedAnimation(
                                Colors.teal,
                              ),
                            ),
                          ),
                          const Icon(Icons.local_pharmacy, size: 16),
                        ],
                      ),
                      const SizedBox(width: 10),
                      Expanded(child: _titleSubtitleStock(context, m)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: _bottomProgressBar(pct, color: Colors.teal),
          ),
        ],
      ),
    );
  }

  static Widget _mixCompactTileBar(BuildContext context, Medication m) {
    final pct = _stockPct(m);
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        children: [
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 12),
            leading: const Icon(Icons.medication),
            title: Text(
              m.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            subtitle: Text('${m.displayStrength} • ${m.type.displayName}'),
            trailing: Text(
              m.stockDisplay,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: _bottomProgressBar(pct, color: Colors.teal),
          ),
        ],
      ),
    );
  }

  static Widget _mixBannerBar(BuildContext context, Medication m) {
    final pct = _stockPct(m);
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            height: 54,
            decoration: const BoxDecoration(
              gradient: LinearGradient(colors: [Colors.blue, Colors.purple]),
              borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                const Icon(Icons.medication, color: Colors.black54),
                const SizedBox(width: 8),
                Expanded(child: _titleSubtitleStock(context, m)),
                Text(
                  m.stockDisplay,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: _bottomProgressBar(pct, color: Colors.purpleAccent),
          ),
        ],
      ),
    );
  }

  static Widget _cardGradientBar(BuildContext context, Medication m) {
    final typeColor = Colors.indigo;
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: typeColor.withValues(alpha: 0.2)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 76,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [typeColor, typeColor.withValues(alpha: 0.5)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: const BorderRadius.horizontal(
                left: Radius.circular(14),
              ),
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
                        Text(
                          m.name,
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w700),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: [
                            _chip(
                              Icons.local_fire_department,
                              m.displayStrength,
                              Colors.pink,
                            ),
                            _chip(
                              Icons.category,
                              m.type.displayName,
                              typeColor,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        m.stockDisplay,
                        style: Theme.of(context).textTheme.labelMedium
                            ?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: Colors.teal,
                            ),
                      ),
                      const SizedBox(height: 6),
                      const Icon(
                        Icons.chevron_right,
                        size: 18,
                        color: Colors.grey,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Widget _cardGlass(BuildContext context, Medication m) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.45)),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.white.withValues(alpha: 0.20),
                Colors.white.withValues(alpha: 0.08),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.35),
                  ),
                ),
                alignment: Alignment.center,
                child: const Icon(Icons.science, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      m.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${m.type.displayName} • ${m.displayStrength}',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    m.stockDisplay,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  if (m.expirationDate != null)
                    Text(
                      DateFormat('MM/yy').format(m.expirationDate!),
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _cardTerminal(BuildContext context, Medication m) {
    const green = Color(0xFF00FF88);
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0A0F0A),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: green, width: 1.5),
        boxShadow: [
          BoxShadow(color: green.withValues(alpha: 0.15), blurRadius: 12),
        ],
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          const Icon(Icons.terminal, color: green, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  '> medication.name',
                  style: TextStyle(
                    color: green,
                    fontFamily: 'RobotoMono',
                    fontSize: 13,
                  ),
                ),
                Text(
                  '> type • strength',
                  style: TextStyle(
                    color: green,
                    fontFamily: 'RobotoMono',
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          Text(
            m.stockDisplay,
            style: const TextStyle(
              color: green,
              fontFamily: 'RobotoMono',
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  static Widget _cardNeumorphic(BuildContext context, Medication m) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFEFEFF4),
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0xFFFFFFFF),
            offset: Offset(-6, -6),
            blurRadius: 12,
          ),
          BoxShadow(
            color: Color(0xFFCDD1D5),
            offset: Offset(6, 6),
            blurRadius: 12,
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFEFEFF4),
              borderRadius: BorderRadius.circular(12),
              boxShadow: const [
                BoxShadow(
                  color: Colors.white,
                  offset: Offset(-3, -3),
                  blurRadius: 6,
                ),
                BoxShadow(
                  color: Color(0xFFCDD1D5),
                  offset: Offset(3, 3),
                  blurRadius: 6,
                ),
              ],
            ),
            alignment: Alignment.center,
            child: const Icon(Icons.medication, color: Color(0xFF60636A)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  m.name,
                  style: const TextStyle(
                    color: Color(0xFF3A3D42),
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  '${m.type.displayName} • ${m.displayStrength}',
                  style: const TextStyle(
                    color: Color(0xFF6B6F76),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                m.stockDisplay,
                style: const TextStyle(
                  color: Color(0xFF3A3D42),
                  fontWeight: FontWeight.w900,
                ),
              ),
              if (m.expirationDate != null)
                Text(
                  DateFormat('MMM yy').format(m.expirationDate!),
                  style: const TextStyle(
                    color: Color(0xFF6B6F76),
                    fontSize: 12,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  static Widget _cardWireframe(BuildContext context, Medication m) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.black, width: 2),
        boxShadow: const [
          BoxShadow(color: Colors.black, offset: Offset(2, 2), blurRadius: 0),
        ],
      ),
      padding: const EdgeInsets.all(10),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.black, width: 2),
              borderRadius: BorderRadius.circular(6),
            ),
            alignment: Alignment.center,
            child: const Icon(Icons.vaccines, color: Colors.black, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  m.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.2,
                  ),
                ),
                Text(
                  '${m.type.displayName} • ${m.displayStrength}',
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            m.stockDisplay,
            style: const TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  static Widget _cardSticker(BuildContext context, Medication m) {
    final bg = const LinearGradient(
      colors: [Color(0xFFFFF8E1), Color(0xFFFFECB3)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
    return Container(
      decoration: BoxDecoration(
        gradient: bg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFFFD54F), width: 2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33FFC107),
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: const Color(0xFFFFF176),
            child: const Icon(Icons.medical_services, color: Color(0xFFF57F17)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  m.name,
                  style: const TextStyle(
                    color: Color(0xFF5D4037),
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  '${m.type.displayName} • ${m.displayStrength}',
                  style: const TextStyle(
                    color: Color(0xFF8D6E63),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Text(
            m.stockDisplay,
            style: const TextStyle(
              color: Color(0xFF5D4037),
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  static Widget _cardOutlinedClassic(BuildContext context, Medication m) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
        color: Colors.white,
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: Colors.blue.shade50,
            ),
            alignment: Alignment.center,
            child: Icon(Icons.medication, color: Colors.blue.shade600),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  m.name,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '${m.type.displayName} • ${m.displayStrength}',
                  style: Theme.of(
                    context,
                  ).textTheme.labelSmall?.copyWith(color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          Text(
            m.stockDisplay,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: Colors.teal,
            ),
          ),
          const SizedBox(width: 6),
          const Icon(Icons.chevron_right, size: 18, color: Colors.grey),
        ],
      ),
    );
  }

  static Widget _cardCompactChips(BuildContext context, Medication m) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
        color: Colors.white,
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: Colors.deepPurple.shade50,
            ),
            alignment: Alignment.center,
            child: Icon(Icons.vaccines, color: Colors.deepPurple.shade600),
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
                        m.name,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    _dot(Colors.red),
                    _dot(Colors.orange),
                  ],
                ),
                const SizedBox(height: 2),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    _chip(
                      Icons.category,
                      m.type.displayName,
                      Colors.deepPurple,
                    ),
                    _chip(
                      Icons.local_fire_department,
                      m.displayStrength,
                      Colors.pink,
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                m.stockDisplay,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: Colors.teal,
                ),
              ),
              const Icon(Icons.chevron_right, size: 18, color: Colors.grey),
            ],
          ),
        ],
      ),
    );
  }

  static Widget _cardLargeTitle(BuildContext context, Medication m) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
        color: Colors.white,
      ),
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: Colors.teal.shade50,
            ),
            alignment: Alignment.center,
            child: Icon(Icons.local_hospital, color: Colors.teal.shade600),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  m.name,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${m.type.displayName} • ${m.displayStrength}',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: Colors.grey[700]),
                ),
                if (m.brandManufacturer != null)
                  Text(
                    'by ${m.brandManufacturer}',
                    style: Theme.of(
                      context,
                    ).textTheme.labelSmall?.copyWith(color: Colors.grey[600]),
                  ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                m.stockDisplay,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: Colors.teal,
                ),
              ),
              if (m.expirationDate != null)
                Text(
                  'Exp ${DateFormat('MM/yy').format(m.expirationDate!)}',
                  style: Theme.of(
                    context,
                  ).textTheme.labelSmall?.copyWith(color: Colors.red),
                ),
            ],
          ),
        ],
      ),
    );
  }

  static Widget _cardBannerTop(BuildContext context, Medication m) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 54,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [Colors.blue, Colors.purple]),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(14),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                const Icon(Icons.medication, color: Colors.black54),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        m.name,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      Text(
                        '${m.type.displayName} • ${m.displayStrength}',
                        style: const TextStyle(color: Colors.black54),
                      ),
                    ],
                  ),
                ),
                Text(
                  m.stockDisplay,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static Widget _cardBigBadge(BuildContext context, Medication m) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.orange.shade50,
              border: Border.all(color: Colors.orange.shade200),
            ),
            alignment: Alignment.center,
            child: Text(
              m.strengthPerUnit.toInt().toString(),
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 20,
                color: Colors.orange.shade700,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  m.name,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                Text(
                  '${m.type.displayName} • ${m.displayStrength}',
                  style: const TextStyle(color: Colors.black54),
                ),
              ],
            ),
          ),
          Text(
            m.stockDisplay,
            style: TextStyle(
              color: Colors.orange.shade700,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  static Widget _cardColorBlock(BuildContext context, Medication m) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.blueGrey.shade900,
      ),
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(width: 6, height: 52, color: Colors.cyanAccent),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  m.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  '${m.type.displayName} • ${m.displayStrength}',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.8)),
                ),
              ],
            ),
          ),
          Text(
            m.stockDisplay,
            style: const TextStyle(
              color: Colors.cyanAccent,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  static Widget _cardShadowed(BuildContext context, Medication m) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.pink.shade50,
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: Icon(Icons.medication_liquid, color: Colors.pink.shade500),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  m.name,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                Text(
                  '${m.type.displayName} • ${m.displayStrength}',
                  style: const TextStyle(color: Colors.black54),
                ),
              ],
            ),
          ),
          Text(
            m.stockDisplay,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  static Widget _cardRibbon(BuildContext context, Medication m) {
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              const Icon(Icons.medication_outlined),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      m.name,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    Text(
                      '${m.type.displayName} • ${m.displayStrength}',
                      style: const TextStyle(color: Colors.black54),
                    ),
                  ],
                ),
              ),
              Text(
                m.stockDisplay,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        Positioned(
          right: 0,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: const BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.only(
                topRight: Radius.circular(12),
                bottomLeft: Radius.circular(12),
              ),
            ),
            child: const Text(
              'NEW',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
      ],
    );
  }

  static Widget _cardMonoSerif(BuildContext context, Medication m) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black87),
        color: Colors.white,
      ),
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          const Icon(Icons.medication, color: Colors.black87),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Georgia Title',
                  style: TextStyle(
                    fontFamily: 'Georgia',
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text('serif subtitle', style: TextStyle(fontFamily: 'Georgia')),
              ],
            ),
          ),
          const Icon(Icons.chevron_right),
        ],
      ),
    );
  }

  static Widget _cardPillCapsule(BuildContext context, Medication m) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.grey.shade300),
        color: Colors.white,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: Colors.purple.shade50,
            child: Icon(Icons.medication, color: Colors.purple.shade600),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  m.name,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                Text(
                  '${m.type.displayName} • ${m.displayStrength}',
                  style: const TextStyle(color: Colors.black54),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.teal.shade50,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Text(
              m.stockDisplay,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  static Widget _cardSplitTwoCol(BuildContext context, Medication m) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    m.name,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${m.type.displayName}\n${m.displayStrength}',
                    style: const TextStyle(color: Colors.black54),
                  ),
                ],
              ),
            ),
          ),
          Container(width: 1, height: 64, color: Colors.grey.shade300),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('Stock', style: TextStyle(color: Colors.grey.shade600)),
                  Text(
                    m.stockDisplay,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  if (m.expirationDate != null)
                    Text(
                      DateFormat('MMM yy').format(m.expirationDate!),
                      style: const TextStyle(color: Colors.red),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Widget _cardBorderlessTile(BuildContext context, Medication m) {
    return Container(
      color: Colors.transparent,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(Icons.medication_outlined, color: Colors.grey.shade700),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  m.name,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                Text(
                  '${m.type.displayName} • ${m.displayStrength}',
                  style: const TextStyle(color: Colors.black54),
                ),
              ],
            ),
          ),
          Text(
            m.stockDisplay,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  static Widget _cardOutlinedDivider(BuildContext context, Medication m) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
        color: Colors.white,
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: Colors.blueGrey.shade50,
            ),
            alignment: Alignment.center,
            child: Icon(Icons.science, color: Colors.blueGrey.shade700),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  m.name,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '${m.type.displayName} • ${m.displayStrength}',
                  style: Theme.of(
                    context,
                  ).textTheme.labelSmall?.copyWith(color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          Container(width: 1, height: 24, color: Colors.grey.shade300),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                m.stockDisplay,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: Colors.teal,
                ),
              ),
              if (m.expirationDate != null)
                Text(
                  DateFormat('MMM yy').format(m.expirationDate!),
                  style: const TextStyle(color: Colors.red),
                ),
            ],
          ),
        ],
      ),
    );
  }

  // New 21-40 builders
  static Widget _cardTimelineDot(BuildContext context, Medication m) {
    return Row(
      children: [
        Column(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: Colors.teal,
                shape: BoxShape.circle,
              ),
            ),
            Container(
              width: 2,
              height: 52,
              color: Colors.teal.withValues(alpha: 0.3),
            ),
          ],
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.teal.withValues(alpha: 0.25)),
            ),
            child: _titleSubtitleStock(context, m),
          ),
        ),
      ],
    );
  }

  static Widget _cardTicketStub(BuildContext context, Medication m) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Stack(
        children: [
          Positioned(
            left: 0,
            top: 24,
            bottom: 24,
            child: Container(
              width: 12,
              decoration: const BoxDecoration(
                color: Colors.amber,
                borderRadius: BorderRadius.only(
                  topRight: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: _titleSubtitleStock(context, m),
          ),
        ],
      ),
    );
  }

  static Widget _cardMagazineCover(BuildContext context, Medication m) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [Colors.black, Colors.black87]),
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          const Icon(Icons.medication, color: Colors.white70),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  m.name.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                  ),
                ),
                Text(
                  '${m.type.displayName} • ${m.displayStrength}',
                  style: const TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
          Text(
            m.stockDisplay,
            style: const TextStyle(
              color: Colors.cyanAccent,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  static Widget _cardBlurLite(BuildContext context, Medication m) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
          ),
        ],
      ),
      padding: const EdgeInsets.all(12),
      child: _titleSubtitleStock(context, m),
    );
  }

  static Widget _cardTonal(BuildContext context, Medication m) {
    final base = Colors.blueGrey;
    return Container(
      decoration: BoxDecoration(
        color: base.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: base.shade100),
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Icon(Icons.medication, color: base.shade700),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  m.name,
                  style: TextStyle(
                    color: base.shade900,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  '${m.type.displayName} • ${m.displayStrength}',
                  style: TextStyle(color: base.shade700),
                ),
              ],
            ),
          ),
          Text(
            m.stockDisplay,
            style: TextStyle(color: base.shade800, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  static Widget _cardIconRail(BuildContext context, Medication m) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            decoration: const BoxDecoration(
              color: Color(0xFFF3F6FF),
              borderRadius: BorderRadius.horizontal(left: Radius.circular(12)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: const [
                SizedBox(height: 12),
                Icon(Icons.local_pharmacy, color: Colors.indigo),
                SizedBox(height: 12),
                Icon(Icons.category, color: Colors.indigo),
                SizedBox(height: 12),
                Icon(Icons.event, color: Colors.indigo),
                SizedBox(height: 12),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: _titleSubtitleStock(context, m),
            ),
          ),
        ],
      ),
    );
  }

  static Widget _cardStackedSheets(BuildContext context, Medication m) {
    return Stack(
      children: [
        Transform.translate(
          offset: const Offset(6, 6),
          child: Container(
            height: 76,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        Transform.translate(
          offset: const Offset(3, 3),
          child: Container(
            height: 76,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: _titleSubtitleStock(context, m),
        ),
      ],
    );
  }

  static Widget _cardDiagonalGrad(BuildContext context, Medication m) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.teal, Colors.lime],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(16),
      child: _titleSubtitleStockColored(m, Colors.white),
    );
  }

  static Widget _cardDashedOutline(BuildContext context, Medication m) {
    // Simulated dashed border using a Row of tiny boxes around
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          _dashLine(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: _titleSubtitleStock(context, m),
          ),
          _dashLine(),
        ],
      ),
    );
  }

  static Widget _dashLine() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: List.generate(
          30,
          (i) => Expanded(
            child: Container(
              height: 1,
              color: i.isEven ? Colors.grey.shade300 : Colors.transparent,
            ),
          ),
        ),
      ),
    );
  }

  static Widget _cardCheckered(BuildContext context, Medication m) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        children: [
          Container(
            height: 18,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.black, Colors.white],
                stops: [0.0, 1.0],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: _titleSubtitleStock(context, m),
          ),
        ],
      ),
    );
  }

  static Widget _cardVerticalTabs(BuildContext context, Medication m) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          Column(children: [_tab('Med'), _tab('Type'), _tab('Stock')]),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: _titleSubtitleStock(context, m),
            ),
          ),
        ],
      ),
    );
  }

  static Widget _tab(String t) => Container(
    margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
    decoration: BoxDecoration(
      color: const Color(0xFFF2F2F7),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Text(t, style: const TextStyle(fontWeight: FontWeight.w700)),
  );

  static Widget _cardSidebarGrid(BuildContext context, Medication m) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          Container(
            width: 72,
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: Color(0xFFFAFAFA),
              borderRadius: BorderRadius.horizontal(left: Radius.circular(12)),
            ),
            child: GridView.count(
              shrinkWrap: true,
              crossAxisCount: 2,
              mainAxisSpacing: 6,
              crossAxisSpacing: 6,
              children: const [
                Icon(Icons.medical_information, size: 16),
                Icon(Icons.vaccines, size: 16),
                Icon(Icons.science, size: 16),
                Icon(Icons.biotech, size: 16),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: _titleSubtitleStock(context, m),
            ),
          ),
        ],
      ),
    );
  }

  static Widget _cardKpiBlock(BuildContext context, Medication m) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade300),
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  m.name,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                Text(
                  '${m.type.displayName} • ${m.displayStrength}',
                  style: const TextStyle(color: Colors.black54),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text('Stock', style: TextStyle(color: Colors.black54)),
              Text(
                m.stockDisplay,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 6),
              if (m.expirationDate != null)
                Text(
                  'Exp ${DateFormat('MM/yy').format(m.expirationDate!)}',
                  style: const TextStyle(color: Colors.red),
                ),
            ],
          ),
        ],
      ),
    );
  }

  static Widget _cardCircleProgress(BuildContext context, Medication m) {
    final pct = ((m.stockQuantity % 100) / 100).clamp(0.0, 1.0);
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade300),
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 44,
                height: 44,
                child: CircularProgressIndicator(
                  value: pct,
                  strokeWidth: 6,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: const AlwaysStoppedAnimation(Colors.teal),
                ),
              ),
              const Icon(Icons.medication, size: 18),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  m.name,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                Text(
                  '${m.type.displayName} • ${m.displayStrength}',
                  style: const TextStyle(color: Colors.black54),
                ),
              ],
            ),
          ),
          Text(
            m.stockDisplay,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  static Widget _cardBadgeCluster(BuildContext context, Medication m) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade300),
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Wrap(
            direction: Axis.vertical,
            spacing: 6,
            children: [
              _chip(Icons.category, m.type.displayName, Colors.indigo),
              _chip(
                Icons.local_fire_department,
                m.displayStrength,
                Colors.pink,
              ),
              if (m.requiresRefrigeration)
                _chip(Icons.ac_unit, 'Fridge', Colors.blue),
            ],
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  m.name,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                Text(
                  m.brandManufacturer ?? '',
                  style: const TextStyle(color: Colors.black54),
                ),
              ],
            ),
          ),
          Text(
            m.stockDisplay,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  static Widget _cardInvertedDark(BuildContext context, Medication m) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          const Icon(Icons.medication, color: Colors.white70),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'INVERTED MODE',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  'high contrast layout',
                  style: TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
          Text(
            m.stockDisplay,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  static Widget _cardPastelBlocks(BuildContext context, Medication m) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: const Color(0xFFFFF7F0),
        border: Border.all(color: const Color(0xFFFFE2C8)),
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFFCCE5FF),
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Pastel Title',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                Text(
                  'soft blocks aesthetic',
                  style: TextStyle(color: Colors.black54),
                ),
              ],
            ),
          ),
          Text(
            m.stockDisplay,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  static Widget _cardEmbossed(BuildContext context, Medication m) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFEDEDED),
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(color: Colors.white, offset: Offset(-2, -2), blurRadius: 3),
          BoxShadow(
            color: Color(0xFFBDBDBD),
            offset: Offset(2, 2),
            blurRadius: 3,
          ),
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: _titleSubtitleStock(context, m),
    );
  }

  static Widget _cardPhotoPlaceholder(BuildContext context, Medication m) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          Container(
            width: 84,
            height: 72,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: const BorderRadius.horizontal(
                left: Radius.circular(12),
              ),
            ),
            child: const Icon(Icons.image, color: Colors.grey),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: _titleSubtitleStock(context, m),
            ),
          ),
        ],
      ),
    );
  }

  static Widget _cardAccordionRow(BuildContext context, Medication m) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 12),
        title: Text(
          m.name,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        subtitle: Text('${m.type.displayName} • ${m.displayStrength}'),
        trailing: Text(
          m.stockDisplay,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 12, right: 12, bottom: 12),
            child: Row(
              children: [
                _chip(Icons.category, m.type.displayName, Colors.indigo),
                const SizedBox(width: 6),
                if (m.expirationDate != null)
                  _chip(
                    Icons.event,
                    DateFormat('MMM yy').format(m.expirationDate!),
                    Colors.red,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- helpers ---
  static Widget _chip(IconData i, String t, Color c) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: c.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: c),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(i, size: 12, color: c),
        const SizedBox(width: 4),
        Text(
          t,
          style: TextStyle(color: c, fontSize: 11, fontWeight: FontWeight.w600),
        ),
      ],
    ),
  );
  static Widget _dot(Color c) => Container(
    width: 12,
    height: 12,
    decoration: BoxDecoration(
      color: c.withValues(alpha: 0.15),
      borderRadius: BorderRadius.circular(2),
    ),
    child: Icon(Icons.circle, size: 8, color: c),
  );

  static Widget _metaDivider() => Container(
    width: 1,
    height: 16,
    color: Colors.grey.shade300,
    margin: const EdgeInsets.symmetric(horizontal: 10),
  );
  static Widget _metaItem(IconData icon, String label, String value) => Row(
    children: [
      Icon(icon, size: 14, color: Colors.grey.shade700),
      const SizedBox(width: 4),
      Text(
        '$label: ',
        style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
      ),
      Text(
        value,
        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
      ),
    ],
  );

  static _Meta _computeMeta(Medication m) {
    // Simple demo logic for preview only
    final now = DateTime.now();
    final qty = m.stockQuantity is num
        ? (m.stockQuantity as num).toDouble()
        : 0.0;
    final isMl = m.stockUnit == StrengthUnit.ml;
    final dailyUse = isMl ? 10.0 : 2.0; // demo assumption
    final daysLeft = (dailyUse > 0) ? (qty / dailyUse) : 0.0;
    final runOutDate = now.add(Duration(days: daysLeft.floor()));
    final lastDose = now.subtract(const Duration(hours: 6));
    final nextDose = now.add(const Duration(hours: 6));
    final unitName = m.stockUnit?.displayName ?? 'units';
    final remainingLabel = '${qty.toStringAsFixed(0)} $unitName left';
    return _Meta(
      lastDose: DateFormat('MMM d, h:mm a').format(lastDose),
      nextDose: DateFormat('MMM d, h:mm a').format(nextDose),
      runOut: daysLeft.isFinite && daysLeft > 0
          ? DateFormat('MMM d').format(runOutDate)
          : '—',
      remainingLabel: remainingLabel,
    );
  }

  // Common row used by many preview cards
  static Widget _titleSubtitleStock(BuildContext context, Medication m) {
    final subtitle = '${m.type.displayName} • ${m.displayStrength}';
    return Row(
      children: [
        const Icon(Icons.medication, color: Colors.black54),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                m.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: Theme.of(
                  context,
                ).textTheme.labelSmall?.copyWith(color: Colors.grey[600]),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text(
          m.stockDisplay,
          style: Theme.of(
            context,
          ).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w900),
        ),
      ],
    );
  }

  // Colored variant without needing a BuildContext
  static Widget _titleSubtitleStockColored(Medication m, Color color) {
    final subtitle = '${m.type.displayName} • ${m.displayStrength}';
    return Row(
      children: [
        Icon(Icons.medication, color: color.withValues(alpha: 0.9)),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                m.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: color, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(color: color.withValues(alpha: 0.85)),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text(
          m.stockDisplay,
          style: TextStyle(color: color, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  List<Medication> _buildSampleMeds() {
    final now = DateTime.now();
    return [
      Medication.create(
        name: 'Amoxicillin',
        type: MedicationType.capsule,
        brandManufacturer: 'Acme Pharma',
        strengthPerUnit: 500,
        strengthUnit: StrengthUnit.mg,
        stockQuantity: 28,
        stockUnit: StrengthUnit.units,
        expirationDate: now.add(const Duration(days: 180)),
      ),
      Medication.create(
        name: 'Lantus Insulin',
        type: MedicationType.preFilledSyringe,
        brandManufacturer: 'Sanofi',
        strengthPerUnit: 100,
        strengthUnit: StrengthUnit.units,
        stockQuantity: 6,
        stockUnit: StrengthUnit.units,
        requiresRefrigeration: true,
        expirationDate: now.add(const Duration(days: 12)),
      ),
      Medication.create(
        name: 'Vancomycin (Lyophilized)',
        type: MedicationType.lyophilizedVial,
        brandManufacturer: 'PharmaCorp',
        strengthPerUnit: 1000,
        strengthUnit: StrengthUnit.mg,
        stockQuantity: 120.0,
        stockUnit: StrengthUnit.ml,
        vialsInStock: 3,
        reconstitutionVolume: 20.0,
        finalConcentration: 50.0,
        expirationDate: now.add(const Duration(days: 45)),
      ),
      Medication.create(
        name: 'Triamcinolone Ointment',
        type: MedicationType.ointment,
        brandManufacturer: 'Dermacare',
        strengthPerUnit: 0.1,
        strengthUnit: StrengthUnit.percent,
        stockQuantity: 1,
        stockUnit: StrengthUnit.units,
        expirationDate: now.subtract(const Duration(days: 5)),
      ),
      Medication.create(
        name: 'Saline Solution',
        type: MedicationType.liquid,
        brandManufacturer: 'Generics Co.',
        strengthPerUnit: 0,
        strengthUnit: StrengthUnit.ml,
        stockQuantity: 850.0,
        stockUnit: StrengthUnit.ml,
        expirationDate: now.add(const Duration(days: 400)),
      ),
    ];
  }
}

class _PreviewStyle {
  final String title;
  final Widget Function(BuildContext, Medication) builder;
  _PreviewStyle(this.title, this.builder);
}

class _Meta {
  final String lastDose;
  final String nextDose;
  final String runOut;
  final String remainingLabel;
  _Meta({
    required this.lastDose,
    required this.nextDose,
    required this.runOut,
    required this.remainingLabel,
  });
}
