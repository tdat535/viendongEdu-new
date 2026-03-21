import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/app_session.dart';

// ── Model ────────────────────────────────────────────────
class TuitionItem {
  final int ptid;
  final String ptma;
  final int soTien;
  final DateTime ngayTao;
  final String ghiChu;
  final String hkma;
  final String hkten;
  final String lptma;
  final String lptten;

  TuitionItem.fromJson(Map<String, dynamic> j)
      : ptid = j['ptid'] as int? ?? 0,
        ptma = (j['ptma'] as String? ?? '').trim(),
        soTien = j['soTien'] as int? ?? 0,
        ngayTao = DateTime.tryParse(j['ngayTao'] as String? ?? '') ?? DateTime(0),
        ghiChu = j['ghiChu'] as String? ?? '',
        hkma = j['hkma'] as String? ?? '',
        hkten = j['hkten'] as String? ?? '',
        lptma = (j['lptma'] as String? ?? '').trim(),
        lptten = j['lptten'] as String? ?? '';

  bool get isPaid => soTien > 0;
  bool get isDebt => soTien < 0;
}

// ── Helpers ─────────────────────────────────────────────
String _fmtCurrency(int amount) {
  final abs = amount.abs();
  final s = abs.toString();
  final buf = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
    buf.write(s[i]);
  }
  return '${buf.toString()} đ';
}

String _fmtDate(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

// ── Screen ──────────────────────────────────────────────
class TuitionScreen extends StatefulWidget {
  const TuitionScreen({super.key});

  @override
  State<TuitionScreen> createState() => _TuitionScreenState();
}

class _TuitionScreenState extends State<TuitionScreen> {
  List<TuitionItem> _allItems = [];
  List<({String hkma, String hkten})> _semesters = [];
  String _selectedHkma = '';
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() { _loading = true; _error = null; });
    try {
      //final mssv = AppSession.instance.hocVien?.mshv ?? '';
      final data = await ApiService.getTuition();
      final items = data
          .map((e) => TuitionItem.fromJson(e as Map<String, dynamic>))
          .toList()
        ..sort((a, b) => a.ngayTao.compareTo(b.ngayTao));

      final seen = <String>{};
      final sems = items
          .where((t) => seen.add(t.hkma))
          .map((t) => (hkma: t.hkma, hkten: t.hkten))
          .toList()
          .reversed
          .toList();

      if (!mounted) return;
      setState(() {
        _allItems = items;
        _semesters = sems;
        _selectedHkma = sems.isNotEmpty ? sems.first.hkma : '';
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() { _loading = false; _error = e.toString(); });
    }
  }

  // Giao dịch của học kỳ đang chọn (cho list)
  List<TuitionItem> get _items =>
      _allItems.where((t) => t.hkma == _selectedHkma).toList()
        ..sort((a, b) => a.ngayTao.compareTo(b.ngayTao));

  // Tổng toàn bộ học kỳ (cho summary)
  int get _totalPaid =>
      _allItems.where((t) => t.isPaid).fold(0, (s, t) => s + t.soTien);

  int get _totalDebt =>
      _allItems.where((t) => t.isDebt).fold(0, (s, t) => s + t.soTien.abs());

  int get _remaining => _totalDebt - _totalPaid;

  @override
  Widget build(BuildContext context) {
    final items = _items;
    final hkten = _semesters.isEmpty
        ? ''
        : _semesters.firstWhere((s) => s.hkma == _selectedHkma,
                orElse: () => _semesters.first)
            .hkten;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(top: false, child: Column(
        children: [
          // ── Header ──
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 48, 16, 20),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFE65100), Color(0xFFFF8C00)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius:
                  BorderRadius.vertical(bottom: Radius.circular(24)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Back + title
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Icon(Icons.arrow_back_ios,
                          color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Học phí',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                
                const SizedBox(height: 16),

                // Semester chips
                if (!_loading && _semesters.isNotEmpty)
                SizedBox(
                  height: 36,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _semesters.length,
                    itemBuilder: (context, i) {
                      final sem = _semesters[i];
                      final isSelected = sem.hkma == _selectedHkma;
                      return GestureDetector(
                        onTap: () =>
                            setState(() => _selectedHkma = sem.hkma),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.only(right: 10),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 6),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Colors.white
                                : Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            sem.hkten,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: isSelected
                                  ? Color(0xFFE65100)
                                  : Colors.white,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFFE65100)))
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
                                  backgroundColor: Color(0xFFE65100)),
                              child: const Text('Thử lại',
                                  style: TextStyle(color: Colors.white)),
                            ),
                          ],
                        ),
                      )
                    : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Summary cards ──
                  _SummarySection(
                    hkten: 'Tất cả học kỳ',
                    totalDebt: _totalDebt,
                    totalPaid: _totalPaid,
                    remaining: _remaining,
                  ),
                  const SizedBox(height: 20),

                  // ── Section label ──
                  Text(
                    'Giao dịch — $hkten',
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),

                  // ── Transaction list ──
                  if (items.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.only(top: 40),
                        child: Column(
                          children: [
                            Icon(Icons.receipt_long_outlined,
                                size: 64, color: Colors.grey),
                            SizedBox(height: 12),
                            Text('Không có giao dịch',
                                style: TextStyle(color: Colors.grey)),
                          ],
                        ),
                      ),
                    )
                  else
                    ...items.map((t) => _TransactionCard(item: t)),
                ],
              ),
            ),
          ),
        ],
      )),
    );
  }
}

// ── Summary Section ─────────────────────────────────────
class _SummarySection extends StatelessWidget {
  final String hkten;
  final int totalDebt;
  final int totalPaid;
  final int remaining;

  const _SummarySection({
    required this.hkten,
    required this.totalDebt,
    required this.totalPaid,
    required this.remaining,
  });

  @override
  Widget build(BuildContext context) {
    final paidPct = totalDebt > 0
        ? (totalPaid / totalDebt).clamp(0.0, 1.0)
        : 1.0;
    // remaining > 0 → còn thiếu | remaining < 0 → đóng thừa | == 0 → đủ
    final badgeIcon = remaining > 0
        ? Icons.warning_rounded
        : remaining < 0
            ? Icons.arrow_upward_rounded
            : Icons.check_circle;
    final badgeLabel = remaining > 0
        ? 'Còn thiếu'
        : remaining < 0
            ? 'Đóng thừa'
            : 'Đã thanh toán';
    final badgeColor = remaining > 0
        ? Colors.red.withValues(alpha: 0.25)
        : remaining < 0
            ? Colors.blue.withValues(alpha: 0.25)
            : Colors.white.withValues(alpha: 0.25);

    return Column(
      children: [
        // ── Tổng học phí + progress ──
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFE65100), Color(0xFFFF8C00)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [
              BoxShadow(
                  color: Colors.black26,
                  blurRadius: 8,
                  offset: Offset(0, 4)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Tổng học phí',
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: badgeColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(badgeIcon, size: 13, color: Colors.white),
                        const SizedBox(width: 4),
                        Text(
                          badgeLabel,
                          style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                _fmtCurrency(totalDebt),
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                hkten,
                style: const TextStyle(
                    color: Colors.white70, fontSize: 12),
              ),
              const SizedBox(height: 16),

              // Progress bar
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: paidPct,
                  backgroundColor: Colors.white.withValues(alpha: 0.3),
                  color: Colors.white,
                  minHeight: 8,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Đã đóng: ${(paidPct * 100).round()}%',
                    style: const TextStyle(
                        color: Colors.white, fontSize: 12),
                  ),
                  Text(
                    '${_fmtCurrency(totalPaid)} / ${_fmtCurrency(totalDebt)}',
                    style: const TextStyle(
                        color: Colors.white70, fontSize: 11),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // ── 2 stat cards ──
        Row(
          children: [
            Expanded(
              child: _MiniCard(
                icon: Icons.check_circle_outline,
                label: 'Đã đóng',
                amount: totalPaid,
                color: const Color(0xFF4CAF50),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _MiniCard(
                icon: remaining > 0
                    ? Icons.warning_amber_rounded
                    : remaining < 0
                        ? Icons.savings_outlined
                        : Icons.check_circle_outline,
                label: remaining > 0
                    ? 'Còn thiếu'
                    : remaining < 0
                        ? 'Đóng thừa'
                        : 'Đã đủ',
                amount: remaining.abs(),
                color: remaining > 0
                    ? const Color(0xFFF44336)
                    : remaining < 0
                        ? const Color(0xFF2196F3)
                        : const Color(0xFF4CAF50),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _MiniCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final int amount;
  final Color color;

  const _MiniCard({
    required this.icon,
    required this.label,
    required this.amount,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
              color: Colors.black12, blurRadius: 6, offset: Offset(0, 3)),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontSize: 12, color: Colors.grey)),
                const SizedBox(height: 2),
                Text(
                  _fmtCurrency(amount),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Transaction Card ────────────────────────────────────
class _TransactionCard extends StatefulWidget {
  final TuitionItem item;
  const _TransactionCard({required this.item});

  @override
  State<_TransactionCard> createState() => _TransactionCardState();
}

class _TransactionCardState extends State<_TransactionCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final t = widget.item;
    final isPaid = t.isPaid;
    final color = isPaid ? const Color(0xFF4CAF50) : const Color(0xFFF44336);
    final bgColor = isPaid
        ? const Color(0xFFE8F5E9)
        : const Color(0xFFFFEBEE);
    final sign = isPaid ? '+' : '-';
    final label = isPaid ? 'Đã đóng' : 'Phát sinh';
    final icon = isPaid
        ? Icons.arrow_upward_rounded
        : Icons.arrow_downward_rounded;

    // Parse ghiChu thành danh sách môn nếu là "Phát sinh học phí"
    final lines = _parseGhiChu(t.ghiChu);

    return GestureDetector(
      onTap: lines.isNotEmpty
          ? () => setState(() => _expanded = !_expanded)
          : null,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
                color: Colors.black12,
                blurRadius: 6,
                offset: Offset(0, 3)),
          ],
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  // Icon circle
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: bgColor,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: color, size: 20),
                  ),
                  const SizedBox(width: 12),

                  // Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          t.lptten.trim(),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          _fmtDate(t.ngayTao),
                          style: const TextStyle(
                              fontSize: 12, color: Colors.grey),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Mã PT: ${t.ptma.trim()}',
                          style: const TextStyle(
                              fontSize: 11, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),

                  // Amount + badge
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '$sign ${_fmtCurrency(t.soTien.abs())}',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: bgColor,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          label,
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: color),
                        ),
                      ),
                      if (lines.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Icon(
                          _expanded
                              ? Icons.keyboard_arrow_up
                              : Icons.keyboard_arrow_down,
                          size: 16,
                          color: Colors.grey,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            // ── Expanded: chi tiết môn học ──
            if (_expanded && lines.isNotEmpty) ...[
              const Divider(height: 1, color: Color(0xFFF0F0F0)),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Chi tiết phát sinh',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey),
                    ),
                    const SizedBox(height: 8),
                    ...lines.map(
                      (line) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.circle,
                                size: 6,
                                color: Color(0xFFE65100)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    line.subject,
                                    style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500),
                                  ),
                                  Text(
                                    line.amount,
                                    style: const TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFFF44336),
                                        fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// Parse ghiChu "-- Lớp ...: TênMôn : Tiền VND" → danh sách
typedef _GhiChuLine = ({String subject, String amount});

List<_GhiChuLine> _parseGhiChu(String ghiChu) {
  final result = <_GhiChuLine>[];
  final parts = ghiChu.split('--').skip(1);
  for (final part in parts) {
    final trimmed = part.trim();
    // Pattern: "Lớp MaLop: TênMôn : TiềnVND"
    final colonIdx = trimmed.lastIndexOf(':');
    if (colonIdx < 0) continue;
    final amountRaw = trimmed.substring(colonIdx + 1).trim(); // "1,620,000 VND"
    final before = trimmed.substring(0, colonIdx).trim();
    // Tìm tên môn sau dấu ":" đầu tiên (sau mã lớp)
    final firstColon = before.indexOf(':');
    if (firstColon < 0) continue;
    final subject = before.substring(firstColon + 1).trim();
    result.add((subject: subject, amount: amountRaw));
  }
  return result;
}
