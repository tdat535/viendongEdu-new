import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../models/mock_data.dart';
import '../services/api_service.dart';
import '../services/app_session.dart';
import '../components/menu_item.dart';

// Helper: "HH:mm" + 3h30 → "HH:mm"
String _calcEndTime(String? start) {
  if (start == null || start.isEmpty) return '';
  try {
    final p = start.split(':');
    final total = int.parse(p[0]) * 60 + int.parse(p[1]) + 210;
    final h = (total ~/ 60) % 24;
    final m = total % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
  } catch (_) {
    return '';
  }
}

// Helper: buoi code → label + color
({String label, Color color}) _buoiInfo(String? b) => switch (b) {
      'S' => (label: 'Sáng', color: const Color(0xFF2196F3)),
      'C' => (label: 'Chiều', color: const Color(0xFFFF9800)),
      'T' => (label: 'Tối', color: const Color(0xFF9C27B0)),
      _ => (label: '', color: Colors.grey),
    };

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  List<Map<String, dynamic>> _todayClasses = [];
  bool _scheduleLoading = true;
  bool _scheduleExpanded = true;

  @override
  void initState() {
    super.initState();
    _loadTodaySchedule();
  }

  Future<void> _loadTodaySchedule() async {
    try {
      final data = await ApiService.getTodaySchedule();
      if (mounted) {
        setState(() {
          _todayClasses =
              data.map((e) => e as Map<String, dynamic>).toList();
          _scheduleLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _scheduleLoading = false);
    }
  }

  // ── Session helpers ──────────────────────────────────
  String get _name => AppSession.instance.hocVien?.fullName ?? '–';
  String get _mssv => AppSession.instance.hocVien?.mshv ?? '–';
  String get _malop => AppSession.instance.hocVien?.malop ?? '–';
  String get _ngaysinh => AppSession.instance.hocVien?.ngaysinhFormatted ?? '–';
  String get _sdt => AppSession.instance.hocVien?.sdt ?? '–';
  String get _email => AppSession.instance.hocVien?.email ?? '–';
  String get _cmnd => AppSession.instance.hocVien?.cmnd ?? '–';
  String get _khoahoc {
    final k = AppSession.instance.hocVien?.khoahoc;
    return k != null ? 'Khóa $k' : '–';
  }

  IconData _mapStringToIcon(String? name) => switch (name) {
        'calendar_today' => Icons.calendar_today,
        'assignment' => Icons.assignment,
        'swap_horiz' => Icons.swap_horiz,
        'add_circle' => Icons.add_circle,
        'bar_chart' => Icons.bar_chart,
        'people' => Icons.people,
        'payments' => Icons.payments,
        'receipt_long' => Icons.receipt_long,
        _ => Icons.help_outline,
      };

  Future<void> _logout() async {
    await AppSession.instance.clear();
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/');
  }

  // ── Today schedule section ───────────────────────────
  Widget _buildTodaySchedule() {
    final now = DateTime.now();
    final weekdays = ['', 'Thứ 2', 'Thứ 3', 'Thứ 4', 'Thứ 5', 'Thứ 6', 'Thứ 7', 'Chủ nhật'];
    final dayLabel = weekdays[now.weekday];
    final dateLabel =
        '$dayLabel, ${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';

    final n = _todayClasses.length;
    final summaryText = n == 0
        ? 'Hôm nay bạn không có lịch học nào 🎉'
        : 'Hôm nay bạn có $n lịch học — nhấn để xem chi tiết';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 8, 8),
          child: Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.calendar_today,
                          size: 16, color: Colors.orange),
                      const SizedBox(width: 6),
                      Text(
                        'Lịch học hôm nay',
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    dateLabel,
                    style: const TextStyle(fontSize: 12, color: Colors.black54, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
              const Spacer(),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () =>
                    setState(() => _scheduleExpanded = !_scheduleExpanded),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _scheduleExpanded ? 'Thu gọn' : 'Mở rộng',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.orange,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 2),
                      Icon(
                        _scheduleExpanded
                            ? Icons.keyboard_arrow_up
                            : Icons.keyboard_arrow_down,
                        color: Colors.orange,
                        size: 16,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        if (_scheduleLoading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.orange),
              ),
            ),
          )
        else if (!_scheduleExpanded)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
            child: GestureDetector(
              onTap: () => Navigator.pushNamed(context, '/schedule'),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: const [
                    BoxShadow(
                        color: Colors.black12,
                        blurRadius: 4,
                        offset: Offset(0, 2)),
                  ],
                ),
                child: Row(
                  children: [
                    Icon(
                      n == 0 ? Icons.event_available : Icons.event_note,
                      size: 18,
                      color: n == 0 ? Colors.green : Colors.orange,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: n == 0
                          ? Text(summaryText,
                              style: const TextStyle(
                                  fontSize: 13, color: Colors.grey))
                          : RichText(
                              text: TextSpan(
                                style: const TextStyle(
                                    fontSize: 13, color: Colors.grey),
                                children: [
                                  const TextSpan(text: 'Hôm nay bạn có '),
                                  TextSpan(
                                    text: '$n',
                                    style: const TextStyle(
                                      color: Colors.red,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const TextSpan(
                                      text: ' lịch học — nhấn để xem chi tiết'),
                                ],
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ),
          )
        else if (_todayClasses.isEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: const [
                  BoxShadow(
                      color: Colors.black12,
                      blurRadius: 4,
                      offset: Offset(0, 2)),
                ],
              ),
              child: const Row(
                children: [
                  Icon(Icons.event_available,
                      size: 18, color: Colors.green),
                  SizedBox(width: 8),
                  Text(
                    'Không có lịch học hôm nay',
                    style: TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                ],
              ),
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
            child: Column(
              children: _todayClasses
                  .map((d) => GestureDetector(
                        onTap: () =>
                            Navigator.pushNamed(context, '/schedule'),
                        child: _ClassChip(data: d),
                      ))
                  .toList(),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final items = MockData.menuItems;

    final List<Widget> tabs = [
      // ──────────── Dashboard ────────────
      Column(
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 56, 20, 20),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFFF8C00), Color(0xFFFFB347)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius:
                  BorderRadius.vertical(bottom: Radius.circular(28)),
            ),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.3),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.person,
                      color: Colors.white, size: 32),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'MSSV: $_mssv',
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 13),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _malop,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Scrollable content
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Lịch học hôm nay
                  _buildTodaySchedule(),

                  // Menu grid
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(12, 4, 12, 20),
                    itemCount: items.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      childAspectRatio: 0.9,
                      crossAxisSpacing: 6,
                      mainAxisSpacing: 6,
                    ),
                    itemBuilder: (context, index) {
                      final m = items[index];
                      return MenuItemWidget(
                        icon: _mapStringToIcon(m['icon']?.toString()),
                        label: m['label']?.toString() ?? '',
                        onTap: () => Navigator.pushNamed(
                          context,
                          m['route']?.toString() ?? '/home',
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),

      // ──────────── QR Code ────────────
      Container(
        color: Colors.grey[100],
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 56, 20, 24),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFFF8C00), Color(0xFFFFB347)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius:
                    BorderRadius.vertical(bottom: Radius.circular(28)),
              ),
              child: Column(
                children: [
                  Text(
                    _name,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'MSSV: $_mssv',
                    style: const TextStyle(
                        fontSize: 14, color: Colors.white70),
                  ),
                ],
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: const [
                  BoxShadow(
                      color: Colors.black12,
                      blurRadius: 20,
                      offset: Offset(0, 8)),
                ],
              ),
              child: QrImageView(
                data: '$_name | $_mssv',
                size: 220,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Quét mã để điểm danh',
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
            const Spacer(),
          ],
        ),
      ),

      // ──────────── Profile ────────────
      Container(
        color: Colors.grey[100],
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 48, 20, 20),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFFF8C00), Color(0xFFFFB347)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius:
                    BorderRadius.vertical(bottom: Radius.circular(24)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.3),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(Icons.person,
                        color: Colors.white, size: 36),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _name,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'MSSV: $_mssv',
                          style: const TextStyle(
                              fontSize: 13, color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                  // GestureDetector(
                  //   onTap: _showEditSheet,
                  //   child: Container(
                  //     padding: const EdgeInsets.all(8),
                  //     decoration: BoxDecoration(
                  //       color: Colors.white.withValues(alpha: 0.2),
                  //       shape: BoxShape.circle,
                  //     ),
                  //     child: const Icon(Icons.edit,
                  //         color: Colors.white, size: 18),
                  //   ),
                  // ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: const [
                      BoxShadow(
                          color: Colors.black12,
                          blurRadius: 8,
                          offset: Offset(0, 4)),
                    ],
                  ),
                  child: Column(
                    children: [
                      _InfoRow(
                          icon: Icons.school,
                          label: 'Khóa học',
                          value: _khoahoc),
                      _Divider(),
                      _InfoRow(
                          icon: Icons.group,
                          label: 'Lớp',
                          value: _malop),
                      _Divider(),
                      _InfoRow(
                          icon: Icons.cake,
                          label: 'Ngày sinh',
                          value: _ngaysinh),
                      _Divider(),
                      _InfoRow(
                          icon: Icons.badge,
                          label: 'CCCD',
                          value: _cmnd),
                      _Divider(),
                      _InfoRow(
                          icon: Icons.phone,
                          label: 'Di động',
                          value: _sdt),
                      _Divider(),
                      _InfoRow(
                          icon: Icons.email_outlined,
                          label: 'Email',
                          value: _email),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _logout,
                  icon: const Icon(Icons.logout, color: Colors.white),
                  label: const Text(
                    'Đăng xuất',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    elevation: 4,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ];

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: tabs[_currentIndex],
      bottomNavigationBar: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            height: 64,
            decoration: const BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                    color: Colors.black12,
                    blurRadius: 8,
                    offset: Offset(0, -2)),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _NavItem(
                  icon: Icons.dashboard_rounded,
                  label: 'Trang chủ',
                  selected: _currentIndex == 0,
                  onTap: () => setState(() => _currentIndex = 0),
                ),
                const SizedBox(width: 64),
                _NavItem(
                  icon: Icons.person_rounded,
                  label: 'Cá nhân',
                  selected: _currentIndex == 2,
                  onTap: () => setState(() => _currentIndex = 2),
                ),
              ],
            ),
          ),
          Positioned(
            top: -24,
            left: 0,
            right: 0,
            child: Center(
              child: GestureDetector(
                onTap: () => setState(() => _currentIndex = 1),
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    gradient: _currentIndex == 1
                        ? const LinearGradient(
                            colors: [Colors.white, Colors.white])
                        : const LinearGradient(
                            colors: [
                              Color(0xFFFF8C00),
                              Color(0xFFFFB347),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.orange, width: 3),
                    boxShadow: const [
                      BoxShadow(
                          color: Colors.black26,
                          blurRadius: 8,
                          offset: Offset(0, 4)),
                    ],
                  ),
                  child: Icon(
                    Icons.qr_code_rounded,
                    size: 34,
                    color:
                        _currentIndex == 1 ? Colors.orange : Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Class Chip (lịch học hôm nay) ───────────────────────
class _ClassChip extends StatelessWidget {
  final Map<String, dynamic> data;
  const _ClassChip({required this.data});

  @override
  Widget build(BuildContext context) {
    final subject = data['mhten']?.toString() ?? '';
    final room = data['phongten']?.toString() ?? '';
    final teacher = data['gvten']?.toString() ?? '';
    final start = data['thoigianbd']?.toString() ?? '';
    final end = _calcEndTime(start);
    final buoi = _buoiInfo(data['buoi']?.toString());

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
        ],
        border: Border(left: BorderSide(color: buoi.color, width: 4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Giờ
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(start,
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: buoi.color)),
              Text(end,
                  style: const TextStyle(fontSize: 11, color: Colors.grey)),
            ],
          ),
          const SizedBox(width: 12),
          Container(width: 1, height: 36, color: const Color(0xFFEEEEEE)),
          const SizedBox(width: 12),
          // Thông tin môn
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(subject,
                          style: const TextStyle(
                              fontSize: 13, fontWeight: FontWeight.bold)),
                    ),
                    if (buoi.label.isNotEmpty) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: buoi.color.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(buoi.label,
                            style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: buoi.color)),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.room, size: 12, color: Colors.orange),
                    const SizedBox(width: 3),
                    Text(room,
                        style: const TextStyle(
                            fontSize: 11, color: Colors.grey)),
                    const SizedBox(width: 10),
                    const Icon(Icons.person_outline,
                        size: 12, color: Colors.orange),
                    const SizedBox(width: 3),
                    Expanded(
                      child: Text(teacher,
                          style: const TextStyle(
                              fontSize: 11, color: Colors.grey),
                          overflow: TextOverflow.ellipsis),
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
}

// ── Reusable widgets ─────────────────────────────────────
class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(icon, color: Colors.orange, size: 20),
          const SizedBox(width: 12),
          SizedBox(
            width: 80,
            child: Text(label,
                style: const TextStyle(fontSize: 13, color: Colors.grey)),
          ),
          Expanded(
            child: Text(value,
                style: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Divider(
        height: 1, indent: 48, endIndent: 16, color: Color(0xFFF0F0F0));
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _NavItem(
      {required this.icon,
      required this.label,
      required this.selected,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                color: selected ? Colors.orange : Colors.grey, size: 26),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: selected ? Colors.orange : Colors.grey,
                fontWeight:
                    selected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

