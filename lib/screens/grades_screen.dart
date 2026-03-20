import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/api_service.dart';

// ── Model ────────────────────────────────────────────────
class GradeItem {
  final String mhma;
  final String mhten;
  final int sotinchi;
  final double tongdiem;
  final double diem4;
  final String diemchu;
  final bool datyn;
  final int solan;

  GradeItem.fromJson(Map<String, dynamic> j)
      : mhma = j['mhma'] as String? ?? '',
        mhten = j['mhten'] as String? ?? '',
        sotinchi = j['sotinchi'] as int? ?? 0,
        tongdiem = (j['tongdiem'] as num?)?.toDouble() ?? 0,
        diem4 = (j['diem4'] as num?)?.toDouble() ?? 0,
        diemchu = j['diemchu'] as String? ?? '',
        datyn = j['datyn'] as bool? ?? false,
        solan = j['solan'] as int? ?? 1;

  Color get letterColor => switch (diemchu) {
        'A' => const Color(0xFF4CAF50),
        'B' => const Color(0xFF2196F3),
        'C' => const Color(0xFFFF9800),
        'D' => const Color(0xFFFF5722),
        _ => const Color(0xFFF44336),
      };
}

// ── Screen ───────────────────────────────────────────────
class GradesScreen extends StatefulWidget {
  const GradesScreen({super.key});

  @override
  State<GradesScreen> createState() => _GradesScreenState();
}

class _GradesScreenState extends State<GradesScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  Map<String, dynamic> _stats = {};
  List<GradeItem> _grades = [];
  List<Map<String, dynamic>> _chuaDat = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fetch();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetch() async {
    setState(() { _loading = true; _error = null; });
    try {
      final results = await Future.wait([
        ApiService.getThongKeCTDT(),
        ApiService.getBangDiem(),
        ApiService.getMonHocChuaDat(),
      ]);
      if (!mounted) return;
      final grades = (results[1] as List<dynamic>)
          .map((e) => GradeItem.fromJson(e as Map<String, dynamic>))
          .toList();
      grades.sort((a, b) => b.tongdiem.compareTo(a.tongdiem));
      setState(() {
        _stats = results[0] as Map<String, dynamic>;
        _grades = grades;
        _chuaDat = (results[2] as List<dynamic>)
            .map((e) => e as Map<String, dynamic>)
            .toList();
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() { _loading = false; _error = e.toString(); });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Column(
        children: [
          // ── Header ──
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 48, 16, 0),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFFF8C00), Color(0xFFFFB347)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius:
                  BorderRadius.vertical(bottom: Radius.circular(24)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Icon(Icons.arrow_back_ios,
                          color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Bảng điểm',
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                TabBar(
                  controller: _tabController,
                  indicatorColor: Colors.white,
                  indicatorWeight: 3,
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.white60,
                  labelStyle: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w600),
                  tabs: const [
                    Tab(text: 'Tổng quan'),
                    Tab(text: 'Chi tiết'),
                    Tab(text: 'Chưa học'),
                  ],
                ),
              ],
            ),
          ),

          // ── Content ──
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(color: Colors.orange))
                : _error != null
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.error_outline,
                                size: 48, color: Colors.grey),
                            const SizedBox(height: 12),
                            Text(_error!,
                                style: const TextStyle(color: Colors.grey),
                                textAlign: TextAlign.center),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _fetch,
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.orange),
                              child: const Text('Thử lại',
                                  style: TextStyle(color: Colors.white)),
                            ),
                          ],
                        ),
                      )
                    : TabBarView(
                        controller: _tabController,
                        children: [
                          _OverviewTab(stats: _stats, grades: _grades),
                          _DetailTab(grades: _grades),
                          _ChuaDatTab(items: _chuaDat),
                        ],
                      ),
          ),
        ],
      ),
    );
  }
}

// ── Overview Tab ─────────────────────────────────────────
class _OverviewTab extends StatelessWidget {
  final Map<String, dynamic> stats;
  final List<GradeItem> grades;

  const _OverviewTab({required this.stats, required this.grades});

  @override
  Widget build(BuildContext context) {
    final tcDat = (stats['sotinchidat'] as num?)?.toInt() ?? 0;
    final tcTong = (stats['sotinchi'] as num?)?.toInt() ?? 0;
    final tbTichLuy = (stats['trungbinhtichluy'] as num?)?.toDouble() ?? 0;
    final tbTongKet = (stats['trungbinhtongket'] as num?)?.toDouble() ?? 0;
    final tcChuaDiem = (stats['sotinchichuacodiem'] as num?)?.toInt() ?? 0;
    final tcKhongDat = (stats['sotinchikhongdat'] as num?)?.toInt() ?? 0;
    final progress = tcTong > 0 ? (tcDat / tcTong).clamp(0.0, 1.0) : 0.0;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Hero card ──
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFF8C00), Color(0xFFFFB347)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.orange.withValues(alpha: 0.35),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('ĐTB Tích lũy',
                          style: TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                              fontWeight: FontWeight.w500)),
                      const SizedBox(height: 4),
                      Text(
                        tbTichLuy.toStringAsFixed(2),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 52,
                          fontWeight: FontWeight.bold,
                          height: 1,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.22),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Tổng kết: ${tbTongKet.toStringAsFixed(2)}',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          const Icon(Icons.school_outlined,
                              color: Colors.white70, size: 14),
                          const SizedBox(width: 5),
                          Text(
                            '$tcDat / $tcTong tín chỉ đạt',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                // Circular progress
                SizedBox(
                  width: 96,
                  height: 96,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      _CircularArc(
                        value: progress,
                        size: 96,
                        trackColor: Colors.white.withValues(alpha: 0.2),
                        progressColor: Colors.white,
                        strokeWidth: 9,
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${(progress * 100).toInt()}%',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              height: 1,
                            ),
                          ),
                          const SizedBox(height: 2),
                          const Text('hoàn thành',
                              style: TextStyle(
                                  color: Colors.white70, fontSize: 9)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // ── Mini stat row ──
          Row(
            children: [
              _MiniStat(
                label: 'Môn đã học',
                value: '${grades.length}',
                icon: Icons.menu_book_outlined,
                color: const Color(0xFF2196F3),
              ),
              const SizedBox(width: 10),
              _MiniStat(
                label: 'Không đạt',
                value: '$tcKhongDat TC',
                icon: Icons.cancel_outlined,
                color: const Color(0xFFF44336),
              ),
              const SizedBox(width: 10),
              _MiniStat(
                label: 'Chưa có điểm',
                value: '$tcChuaDiem TC',
                icon: Icons.hourglass_empty,
                color: Colors.orange,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ── Grade distribution (donut + legend) ──
          _GradeDistribution(grades: grades),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

// Circular arc widget
class _CircularArc extends StatelessWidget {
  final double value;
  final double size;
  final Color trackColor;
  final Color progressColor;
  final double strokeWidth;

  const _CircularArc({
    required this.value,
    required this.size,
    required this.trackColor,
    required this.progressColor,
    required this.strokeWidth,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _ArcPainter(
        value: value,
        trackColor: trackColor,
        progressColor: progressColor,
        strokeWidth: strokeWidth,
      ),
    );
  }
}

class _ArcPainter extends CustomPainter {
  final double value;
  final Color trackColor;
  final Color progressColor;
  final double strokeWidth;

  _ArcPainter({
    required this.value,
    required this.trackColor,
    required this.progressColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = trackColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth,
    );

    if (value > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2,
        2 * math.pi * value,
        false,
        Paint()
          ..color = progressColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(_ArcPainter old) =>
      old.value != value || old.progressColor != progressColor;
}

// Mini stat card
class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _MiniStat({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: const [
            BoxShadow(
                color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(height: 6),
            Text(value,
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: color)),
            const SizedBox(height: 2),
            Text(label,
                style: const TextStyle(fontSize: 10, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}

// Grade distribution with donut chart
class _GradeDistribution extends StatelessWidget {
  final List<GradeItem> grades;
  const _GradeDistribution({required this.grades});

  static const _colors = {
    'A': Color(0xFF4CAF50),
    'B': Color(0xFF2196F3),
    'C': Color(0xFFFF9800),
    'D': Color(0xFFFF5722),
    'F': Color(0xFFF44336),
  };

  @override
  Widget build(BuildContext context) {
    if (grades.isEmpty) return const SizedBox.shrink();

    final Map<String, int> dist = {};
    for (final g in grades) {
      if (g.diemchu.isNotEmpty) {
        dist[g.diemchu] = (dist[g.diemchu] ?? 0) + 1;
      }
    }
    if (dist.isEmpty) return const SizedBox.shrink();

    final order = ['A', 'B', 'C', 'D', 'F'];
    final entries = order
        .where((k) => dist.containsKey(k))
        .map((k) => MapEntry(k, dist[k]!))
        .toList();
    final total = entries.fold(0, (s, e) => s + e.value);

    final sections = entries.map((e) {
      return PieChartSectionData(
        value: e.value.toDouble(),
        color: _colors[e.key] ?? Colors.grey,
        radius: 30,
        showTitle: false,
      );
    }).toList();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
              color: Colors.black12, blurRadius: 6, offset: Offset(0, 3)),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Phân bổ điểm chữ',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Row(
            children: [
              // Donut chart
              SizedBox(
                width: 110,
                height: 110,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    PieChart(
                      PieChartData(
                        sections: sections,
                        centerSpaceRadius: 34,
                        sectionsSpace: 2,
                        startDegreeOffset: -90,
                        borderData: FlBorderData(show: false),
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '$total',
                          style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87),
                        ),
                        const Text('môn',
                            style: TextStyle(
                                fontSize: 11, color: Colors.grey)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              // Legend
              Expanded(
                child: Column(
                  children: entries.map((e) {
                    final color = _colors[e.key] ?? Colors.grey;
                    final pct = (e.value / total * 100).round();
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 9),
                      child: Row(
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Loại ${e.key}',
                            style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600),
                          ),
                          const Spacer(),
                          Text(
                            '${e.value} môn · $pct%',
                            style: const TextStyle(
                                fontSize: 11, color: Colors.grey),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Detail Tab ───────────────────────────────────────────
class _DetailTab extends StatelessWidget {
  final List<GradeItem> grades;
  const _DetailTab({required this.grades});

  @override
  Widget build(BuildContext context) {
    if (grades.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.bar_chart, size: 64, color: Colors.grey),
            SizedBox(height: 12),
            Text('Chưa có điểm', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      itemCount: grades.length,
      itemBuilder: (context, i) => _GradeCard(item: grades[i]),
    );
  }
}

class _GradeCard extends StatelessWidget {
  final GradeItem item;
  const _GradeCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final color = item.letterColor;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
              color: Colors.black12, blurRadius: 5, offset: Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          // Thanh màu trái
          Container(
            width: 5,
            height: 72,
            decoration: BoxDecoration(
              color: color,
              borderRadius:
                  const BorderRadius.horizontal(left: Radius.circular(14)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.mhten,
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.school_outlined,
                          size: 12, color: Colors.orange),
                      const SizedBox(width: 4),
                      Text('${item.sotinchi} TC',
                          style: const TextStyle(
                              fontSize: 12, color: Colors.grey)),
                      const SizedBox(width: 12),
                      const Icon(Icons.tag,
                          size: 12, color: Colors.orange),
                      const SizedBox(width: 4),
                      Text(item.mhma,
                          style: const TextStyle(
                              fontSize: 12, color: Colors.grey)),
                      if (item.solan > 1) ...[
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.orange.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text('Lần ${item.solan}',
                              style: const TextStyle(
                                  fontSize: 10,
                                  color: Colors.orange,
                                  fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
          // Điểm
          Padding(
            padding: const EdgeInsets.only(right: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    item.diemchu,
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: color),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.tongdiem.toStringAsFixed(1),
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: color),
                ),
                // Text(
                //   '${item.diem4.toStringAsFixed(0)}/4',
                //   style: const TextStyle(
                //       fontSize: 11, color: Colors.grey),
                // ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Chưa học Tab ─────────────────────────────────────────
class _ChuaDatTab extends StatelessWidget {
  final List<Map<String, dynamic>> items;
  const _ChuaDatTab({required this.items});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle_outline, size: 64, color: Colors.green),
            SizedBox(height: 12),
            Text('Không có môn chưa học',
                style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${items.length} môn chưa học',
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.orange),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
            itemCount: items.length,
            itemBuilder: (context, i) {
              final item = items[i];
              final mhten = item['mhten'] as String? ?? '';
              final mhma = item['mhma'] as String? ?? '';
              final sotinchi = item['sotinchi'] as int? ?? 0;
              final trangthai = item['trangthai'] as int? ?? 0;

              final (statusLabel, statusColor) = switch (trangthai) {
                1 => ('Đang học', const Color(0xFF2196F3)),
                2 => ('Không đạt', const Color(0xFFF44336)),
                _ => ('Chưa học', Colors.orange),
              };

              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: const [
                    BoxShadow(
                        color: Colors.black12,
                        blurRadius: 5,
                        offset: Offset(0, 2)),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 5,
                      height: 68,
                      decoration: BoxDecoration(
                        color: statusColor,
                        borderRadius: const BorderRadius.horizontal(
                            left: Radius.circular(14)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(mhten,
                                style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.school_outlined,
                                    size: 12, color: Colors.orange),
                                const SizedBox(width: 4),
                                Text('$sotinchi TC',
                                    style: const TextStyle(
                                        fontSize: 12, color: Colors.grey)),
                                const SizedBox(width: 12),
                                const Icon(Icons.tag,
                                    size: 12, color: Colors.orange),
                                const SizedBox(width: 4),
                                Text(mhma,
                                    style: const TextStyle(
                                        fontSize: 12, color: Colors.grey)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(right: 14),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          statusLabel,
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: statusColor),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
