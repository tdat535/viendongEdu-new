import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../components/skeleton.dart';
import 'gv_attendance_screen.dart';
import 'gv_qr_attendance_screen.dart';

class GvScheduleScreen extends StatefulWidget {
  const GvScheduleScreen({super.key});

  @override
  State<GvScheduleScreen> createState() => _GvScheduleScreenState();
}

class _GvScheduleScreenState extends State<GvScheduleScreen> {
  DateTime _selectedDate = DateTime.now();
  List<Map<String, dynamic>> _classes = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetch(_selectedDate);
  }

  Future<void> _fetch(DateTime date) async {
    setState(() { _loading = true; _error = null; });
    try {
      final dateStr =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      final data = await ApiService.getGvScheduleByDate(dateStr);
      if (!mounted) return;
      setState(() {
        _classes = data.map((e) => e as Map<String, dynamic>).toList();
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() { _loading = false; _error = e.toString(); });
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: Color(0xFFE65100)),
        ),
        child: child!,
      ),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
      _fetch(picked);
    }
  }

  String get _dateLabel {
    final weekdays = [
      '', 'Thứ 2', 'Thứ 3', 'Thứ 4', 'Thứ 5', 'Thứ 6', 'Thứ 7', 'Chủ nhật'
    ];
    return '${weekdays[_selectedDate.weekday]}, '
        '${_selectedDate.day.toString().padLeft(2, '0')}/'
        '${_selectedDate.month.toString().padLeft(2, '0')}/'
        '${_selectedDate.year}';
  }

  @override
  Widget build(BuildContext context) {
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
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Icon(Icons.arrow_back_ios,
                          color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Lịch dạy',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Date picker button
                GestureDetector(
                  onTap: _pickDate,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.calendar_today,
                            color: Colors.white, size: 16),
                        const SizedBox(width: 8),
                        Text(
                          _dateLabel,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.arrow_drop_down,
                            color: Colors.white, size: 20),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Content ──
          Expanded(
            child: _loading
                ? skeletonList()
                : _error != null
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.error_outline,
                                size: 48, color: Colors.grey),
                            const SizedBox(height: 12),
                            Text(_error!,
                                style:
                                    const TextStyle(color: Colors.grey)),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _fetch(_selectedDate),
                              style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      const Color(0xFFE65100)),
                              child: const Text('Thử lại',
                                  style:
                                      TextStyle(color: Colors.white)),
                            ),
                          ],
                        ),
                      )
                    : _classes.isEmpty
                        ? const Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.event_busy,
                                    size: 64, color: Colors.grey),
                                SizedBox(height: 12),
                                Text('Không có lịch dạy',
                                    style:
                                        TextStyle(color: Colors.grey)),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(
                                16, 16, 16, 24),
                            itemCount: _classes.length,
                            itemBuilder: (ctx, i) =>
                                _ScheduleCard(data: _classes[i]),
                          ),
          ),
        ],
      )),
    );
  }
}

// ── Schedule Card ────────────────────────────────────────
({String label, Color color}) _buoiInfo(String? b) => switch (b) {
      'S' => (label: 'Sáng', color: const Color(0xFF2196F3)),
      'C' => (label: 'Chiều', color: const Color(0xFFFF9800)),
      'T' => (label: 'Tối', color: const Color(0xFF9C27B0)),
      _ => (label: '', color: Colors.grey),
    };

class _ScheduleCard extends StatefulWidget {
  final Map<String, dynamic> data;
  const _ScheduleCard({required this.data});

  @override
  State<_ScheduleCard> createState() => _ScheduleCardState();
}

class _ScheduleCardState extends State<_ScheduleCard> {
  bool _expanded = false;
  bool _loading = false;

  Future<void> _openAttendance() async {
    setState(() => _loading = true);
    try {
      final d = widget.data;
      final ngayRaw = d['ngay'] as String? ?? '';
      final ngay = ngayRaw.length >= 10 ? ngayRaw.substring(0, 10) : ngayRaw;
      final ktRaw = d['thoigiankt'] as String? ?? '';
      final thoigiankt = ktRaw.length >= 16 ? ktRaw.substring(11, 16) : ktRaw;

      final list = await ApiService.postDiemDanhDanhSach(
        tkbid: d['tkbid'].toString(),
        lopid: d['lopid'].toString(),
        phongid: d['phongid'].toString(),
        ngay: ngay,
        thoigianbd: d['thoigianbd']?.toString() ?? '',
        thoigiankt: thoigiankt,
      );
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => GvAttendanceScreen(
            subject: d['mhten']?.toString() ?? '',
            classCode: d['lmhma']?.toString() ?? '',
            ngay: ngay,
            students: list,
            tkbParams: {
              'tkbid': d['tkbid'].toString(),
              'lopid': d['lopid'].toString(),
              'phongid': d['phongid'].toString(),
              'ngay': ngay,
              'thoigianbd': d['thoigianbd']?.toString() ?? '',
              'thoigiankt': thoigiankt,
            },
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _openQrAttendance() {
    final d = widget.data;
    final ngayRaw = d['ngay'] as String? ?? '';
    final ngay = ngayRaw.length >= 10 ? ngayRaw.substring(0, 10) : ngayRaw;
    final ktRaw = d['thoigiankt'] as String? ?? '';
    final thoigiankt = ktRaw.length >= 16 ? ktRaw.substring(11, 16) : ktRaw;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GvQrAttendanceScreen(
          subject: d['mhten']?.toString() ?? '',
          classCode: d['lmhma']?.toString() ?? '',
          ngay: ngay,
          tkbParams: {
            'tkbid': d['tkbid'].toString(),
            'lopid': d['lopid'].toString(),
            'phongid': d['phongid'].toString(),
            'ngay': ngay,
            'thoigianbd': d['thoigianbd']?.toString() ?? '',
            'thoigiankt': thoigiankt,
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.data;
    final subject = d['mhten']?.toString() ?? '';
    final room = d['phongten']?.toString() ?? '';
    final classCode = d['lmhma']?.toString() ?? '';
    final start = d['thoigianbd']?.toString() ?? '';
    final endRaw = d['thoigiankt'] as String? ?? '';
    final end = endRaw.length >= 16 ? endRaw.substring(11, 16) : '';
    final buoi = _buoiInfo(d['buoi']?.toString());

    return GestureDetector(
      onTap: () => setState(() => _expanded = !_expanded),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3)),
          ],
          border: Border(left: BorderSide(color: buoi.color, width: 5)),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  // Giờ
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(start,
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: buoi.color)),
                      const SizedBox(height: 2),
                      Text(end,
                          style: const TextStyle(
                              fontSize: 12, color: Colors.grey)),
                    ],
                  ),
            const SizedBox(width: 14),
            Container(width: 1, height: 40, color: const Color(0xFFEEEEEE)),
            const SizedBox(width: 14),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(subject,
                            style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold)),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: buoi.color.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(buoi.label,
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: buoi.color)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.room,
                          size: 13, color: Color(0xFFE65100)),
                      const SizedBox(width: 4),
                      Text(room,
                          style: const TextStyle(
                              fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      const Icon(Icons.class_outlined,
                          size: 13, color: Color(0xFFE65100)),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(classCode,
                            style: const TextStyle(
                                fontSize: 12, color: Colors.grey),
                            overflow: TextOverflow.ellipsis),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Chevron
            Icon(
              _expanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
              color: Colors.grey, size: 20,
            ),
          ],
        ),
      ),

            // ── Expanded: nút điểm danh ──
            if (_expanded) ...[
              const Divider(height: 1, color: Color(0xFFF0F0F0)),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                child: Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _loading ? null : _openAttendance,
                        icon: _loading
                            ? const SizedBox(
                                width: 16, height: 16,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2))
                            : const Icon(Icons.checklist_rounded,
                                color: Colors.white, size: 18),
                        label: const Text('Điểm danh bằng danh sách',
                            style: TextStyle(color: Colors.white,
                                fontWeight: FontWeight.w600)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFE65100),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _loading ? null : _openQrAttendance,
                        icon: const Icon(Icons.qr_code_scanner,
                            color: Colors.white, size: 18),
                        label: const Text('Điểm danh bằng QR',
                            style: TextStyle(color: Colors.white,
                                fontWeight: FontWeight.w600)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF8C00),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
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
