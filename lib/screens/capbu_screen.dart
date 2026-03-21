import 'package:flutter/material.dart';
import '../services/api_service.dart';

class CapBuScreen extends StatefulWidget {
  const CapBuScreen({super.key});

  @override
  State<CapBuScreen> createState() => _CapBuScreenState();
}

class _CapBuScreenState extends State<CapBuScreen> {
  List<Map<String, dynamic>> _items = [];
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
      final data = await ApiService.getCapBu();
      if (!mounted) return;
      setState(() {
        _items = data.map((e) => e as Map<String, dynamic>).toList();
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
            padding: const EdgeInsets.fromLTRB(16, 48, 16, 20),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFFF8C00), Color(0xFFFFB347)],
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
                const Expanded(
                  child: Text(
                    'Cấp bù',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                if (!_loading && _error == null && _items.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${_items.length} hóa đơn',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
              ],
            ),
          ),

          // ── Content ──
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(
                        color: Color(0xFFFF8C00)))
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
                                  backgroundColor: const Color(0xFFFF8C00)),
                              child: const Text('Thử lại',
                                  style: TextStyle(color: Colors.white)),
                            ),
                          ],
                        ),
                      )
                    : _items.isEmpty
                        ? const Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.account_balance,
                                    size: 64, color: Colors.grey),
                                SizedBox(height: 12),
                                Text('Không có hóa đơn cấp bù',
                                    style: TextStyle(color: Colors.grey)),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding:
                                const EdgeInsets.fromLTRB(16, 16, 16, 24),
                            itemCount: _items.length,
                            itemBuilder: (_, i) => _CapBuCard(
                              item: _items[i],
                              onTap: () => showModalBottomSheet(
                                context: context,
                                isScrollControlled: true,
                                backgroundColor: Colors.transparent,
                                builder: (ctx) => SizedBox(
                                    height: MediaQuery.of(ctx).size.height * 0.75,
                                    child: _CapBuDetailSheet(item: _items[i]),
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

class _CapBuCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final VoidCallback onTap;
  const _CapBuCard({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final ma = item['ma']?.toString() ?? '';
    final ten = item['ten']?.toString() ?? '';
    final hocKy = item['hocKy']?.toString() ?? '';
    final ngayCap = item['ngayCap']?.toString() ?? '';
    final thanhTien = item['thanhTien']?.toString() ?? '';

    return GestureDetector(
      onTap: onTap,
      child: Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
              color: Colors.black12, blurRadius: 6, offset: Offset(0, 3)),
        ],
        border: const Border(
            left: BorderSide(color: Color(0xFFFF8C00), width: 4)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tên + số tiền
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    ten,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '$thanhTien đ',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFFF8C00),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Học kỳ
            Row(
              children: [
                const Icon(Icons.school_outlined,
                    size: 13, color: Colors.grey),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(hocKy,
                      style: const TextStyle(
                          fontSize: 12, color: Colors.grey)),
                ),
              ],
            ),
            const SizedBox(height: 4),
            // Mã + ngày cấp
            Row(
              children: [
                const Icon(Icons.tag, size: 13, color: Colors.grey),
                const SizedBox(width: 5),
                Text('Mã: $ma',
                    style: const TextStyle(
                        fontSize: 12, color: Colors.grey)),
                const Spacer(),
                const Icon(Icons.calendar_today,
                    size: 12, color: Colors.grey),
                const SizedBox(width: 4),
                Text(ngayCap,
                    style: const TextStyle(
                        fontSize: 12, color: Colors.grey)),
              ],
            ),
          ],
        ),
      ),
    ));
  }
}

// ── Detail Sheet ─────────────────────────────────────
class _CapBuDetailSheet extends StatelessWidget {
  final Map<String, dynamic> item;
  const _CapBuDetailSheet({required this.item});

  @override
  Widget build(BuildContext context) {
    final ma = item['ma']?.toString() ?? '';
    final ten = item['ten']?.toString() ?? '';
    final kyHieu = item['kyHieu']?.toString() ?? '';
    final hocKy = item['hocKy']?.toString() ?? '';
    final ngayCap = item['ngayCap']?.toString() ?? '';
    final donGia = item['donGia']?.toString() ?? '';
    final thanhTien = item['thanhTien']?.toString() ?? '';
    final total = item['total']?.toString() ?? '';
    final ghiChu = item['ghiChu']?.toString() ?? '';

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 20),
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Text(ten,
              style: const TextStyle(
                  fontSize: 17, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text('$thanhTien đ',
              style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFFF8C00))),
          const SizedBox(height: 16),
          const Divider(height: 1, color: Color(0xFFF0F0F0)),
          const SizedBox(height: 16),
          _Row(icon: Icons.tag, label: 'Mã HĐ', value: ma),
          const SizedBox(height: 10),
          _Row(icon: Icons.confirmation_number_outlined, label: 'Ký hiệu', value: kyHieu),
          const SizedBox(height: 10),
          _Row(icon: Icons.school_outlined, label: 'Học kỳ', value: hocKy),
          const SizedBox(height: 10),
          _Row(icon: Icons.calendar_today, label: 'Ngày cấp', value: ngayCap),
          const SizedBox(height: 10),
          _Row(icon: Icons.price_change_outlined, label: 'Đơn giá', value: '$donGia đ'),
          const SizedBox(height: 10),
          _Row(icon: Icons.payments_outlined, label: 'Thành tiền', value: '$thanhTien đ'),
          const SizedBox(height: 10),
          _Row(icon: Icons.calculate_outlined, label: 'Tổng cộng', value: '$total đ'),
          if (ghiChu.isNotEmpty) ...[
            const SizedBox(height: 12),
            _Row(icon: Icons.notes_outlined, label: 'Ghi chú', value: ghiChu),
          ],
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final IconData icon;
  final String label, value;
  const _Row({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: const Color(0xFFFF8C00)),
        const SizedBox(width: 10),
        SizedBox(
          width: 88,
          child: Text(label,
              style: const TextStyle(fontSize: 13, color: Colors.grey)),
        ),
        Expanded(
          child: Text(value,
              style: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w600),
              softWrap: true),
        ),
      ],
    );
  }
}
