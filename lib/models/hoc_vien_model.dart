class HocVien {
  final int id;
  final String mshv;
  final String ho;
  final String ten;
  final String? hinhanh;
  final String malop;
  final int namnhaphoc;
  final int khoahoc;
  final String? ngaysinh;
  final String? email;
  final String? sdt;
  final String? cmnd;
  final int? khoinganhid;

  const HocVien({
    required this.id,
    required this.mshv,
    required this.ho,
    required this.ten,
    this.hinhanh,
    required this.malop,
    required this.namnhaphoc,
    required this.khoahoc,
    this.ngaysinh,
    this.email,
    this.sdt,
    this.cmnd,
    this.khoinganhid,
  });

  String get fullName => '$ho $ten'.trim();

  /// Ngày sinh định dạng dd/MM/yyyy
  String get ngaysinhFormatted {
    if (ngaysinh == null) return '–';
    try {
      final dt = DateTime.parse(ngaysinh!);
      return '${dt.day.toString().padLeft(2, '0')}/'
          '${dt.month.toString().padLeft(2, '0')}/'
          '${dt.year}';
    } catch (_) {
      return ngaysinh!;
    }
  }

  HocVien copyWith({String? email, String? sdt, String? cmnd}) => HocVien(
        id: id,
        mshv: mshv,
        ho: ho,
        ten: ten,
        hinhanh: hinhanh,
        malop: malop,
        namnhaphoc: namnhaphoc,
        khoahoc: khoahoc,
        ngaysinh: ngaysinh,
        email: email ?? this.email,
        sdt: sdt ?? this.sdt,
        cmnd: cmnd ?? this.cmnd,
        khoinganhid: khoinganhid,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'mshv': mshv,
        'ho': ho,
        'ten': ten,
        'hinhanh': hinhanh,
        'malop': malop,
        'namnhaphoc': namnhaphoc,
        'khoahoc': khoahoc,
        'ngaysinh': ngaysinh,
        'email': email,
        'sdt': sdt,
        'cmnd': cmnd,
        'khoinganhid': khoinganhid,
      };

  factory HocVien.fromJson(Map<String, dynamic> json) => HocVien(
        id: json['id'] as int,
        mshv: json['mshv'] as String? ?? '',
        ho: json['ho'] as String? ?? '',
        ten: json['ten'] as String? ?? '',
        hinhanh: json['hinhanh'] as String?,
        malop: json['malop'] as String? ?? '',
        namnhaphoc: json['namnhaphoc'] as int? ?? 0,
        khoahoc: json['khoahoc'] as int? ?? 0,
        ngaysinh: json['ngaysinh'] as String?,
        email: json['email'] as String?,
        sdt: json['sdt'] as String?,
        cmnd: json['cmnd'] as String?,
        khoinganhid: json['khoinganhid'] as int?,
      );
}
