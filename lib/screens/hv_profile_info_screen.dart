import 'package:flutter/material.dart';
import '../services/api_service.dart';

class HvProfileInfoScreen extends StatefulWidget {
  const HvProfileInfoScreen({super.key});

  @override
  State<HvProfileInfoScreen> createState() => _HvProfileInfoScreenState();
}

class _HvProfileInfoScreenState extends State<HvProfileInfoScreen> {
  Map<String, dynamic>? _data;
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
      final data = await ApiService.getUserInfo();
      if (!mounted) return;
      setState(() { _data = data; _loading = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _loading = false; _error = e.toString(); });
    }
  }

  String _fmtDate(String? iso) {
    if (iso == null || iso.isEmpty) return '–';
    try {
      final d = DateTime.parse(iso);
      return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
    } catch (_) {
      return '–';
    }
  }

  @override
  Widget build(BuildContext context) {
    final hv = _data?['hocVien'] as Map<String, dynamic>?;
    final khoiNganh = hv?['khoiNganh'] as Map<String, dynamic>?;
    final chuyenNganh = khoiNganh?['chuyenNganh'] as Map<String, dynamic>?;
    final nganh = chuyenNganh?['nganh'] as Map<String, dynamic>?;
    final heDaoTao = nganh?['hedaotao'] as Map<String, dynamic>?;

    final ho = hv?['ho']?.toString() ?? '';
    final ten = hv?['ten']?.toString() ?? '';
    final fullName = '$ho $ten'.trim();
    final mssv = hv?['mshv']?.toString() ?? '–';
    final malop = hv?['malop']?.toString() ?? '–';
    final khoahoc = hv?['khoahoc']?.toString() ?? '–';
    final ngaysinh = _fmtDate(hv?['ngaysinh']?.toString());
    final gioitinh = hv?['gioitinh'] == 1 ? 'Nam' : hv?['gioitinh'] == 0 ? 'Nữ' : '–';
    final email = hv?['email']?.toString() ?? '–';
    final sdt = hv?['sdt']?.toString() ?? '–';
    final cmnd = hv?['cmnd']?.toString() ?? '–';
    final chuyenNganhTen = chuyenNganh?['ten']?.toString() ?? '–';
    final nganhTen = nganh?['ten']?.toString() ?? '–';
    final heDaoTaoTen = heDaoTao?['ten']?.toString() ?? '–';

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 48, 16, 20),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFE65100), Color(0xFFFF8C00)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.arrow_back_ios,
                        color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Thông tin cá nhân',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),

            // Content
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
                                    backgroundColor: const Color(0xFFE65100)),
                                child: const Text('Thử lại',
                                    style: TextStyle(color: Colors.white)),
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _fetch,
                          color: const Color(0xFFE65100),
                          child: ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                          children: [
                            _Section(title: 'Thông tin cơ bản', children: [
                              _InfoRow(icon: Icons.person_outline, label: 'Họ tên', value: fullName),
                              _InfoRow(icon: Icons.badge_outlined, label: 'MSSV', value: mssv),
                              _InfoRow(icon: Icons.cake_outlined, label: 'Ngày sinh', value: ngaysinh),
                              // _InfoRow(icon: Icons.wc_outlined, label: 'Giới tính', value: gioitinh),
                              _InfoRow(icon: Icons.credit_card_outlined, label: 'CCCD', value: cmnd),
                            ]),
                            const SizedBox(height: 12),
                            _Section(title: 'Liên hệ', children: [
                              _InfoRow(icon: Icons.phone_outlined, label: 'Số điện thoại', value: sdt),
                              _InfoRow(icon: Icons.email_outlined, label: 'Email', value: email),
                            ]),
                            const SizedBox(height: 12),
                            _Section(title: 'Học vụ', children: [
                              _InfoRow(icon: Icons.group_outlined, label: 'Lớp', value: malop),
                              _InfoRow(icon: Icons.school_outlined, label: 'Khóa học', value: 'Khóa $khoahoc'),
                              _InfoRow(icon: Icons.menu_book_outlined, label: 'Chuyên ngành', value: chuyenNganhTen),
                              _InfoRow(icon: Icons.account_balance_outlined, label: 'Ngành', value: nganhTen),
                              _InfoRow(icon: Icons.workspace_premium_outlined, label: 'Hệ đào tạo', value: heDaoTaoTen),
                            ]),
                          ],
                        ),
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _Section({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(title,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFE65100))),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [
              BoxShadow(
                  color: Colors.black12, blurRadius: 6, offset: Offset(0, 3)),
            ],
          ),
          child: Column(
            children: [
              for (int i = 0; i < children.length; i++) ...[
                children[i],
                if (i < children.length - 1)
                  const Divider(height: 1, indent: 48, endIndent: 16),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: const Color(0xFFE65100)),
          const SizedBox(width: 12),
          SizedBox(
            width: 110,
            child: Text(label,
                style: const TextStyle(fontSize: 13, color: Colors.grey)),
          ),
          Expanded(
            child: Text(value,
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w600),
                textAlign: TextAlign.end),
          ),
        ],
      ),
    );
  }
}
