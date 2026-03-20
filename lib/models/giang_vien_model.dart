class GiangVien {
  final int id;
  final String ma;
  final String ten;
  final bool gvcohuuyn;
  final String? email;
  final String? sdt;
  final String? ngaysinh;

  const GiangVien({
    required this.id,
    required this.ma,
    required this.ten,
    required this.gvcohuuyn,
    this.email,
    this.sdt,
    this.ngaysinh,
  });

  factory GiangVien.fromJson(Map<String, dynamic> j) => GiangVien(
        id: j['id'] as int,
        ma: j['ma'] as String? ?? '',
        ten: j['ten'] as String? ?? '',
        gvcohuuyn: j['gvcohuuyn'] as bool? ?? false,
        email: j['email'] as String?,
        sdt: j['sdt'] as String?,
        ngaysinh: j['ngaysinh'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'ma': ma,
        'ten': ten,
        'gvcohuuyn': gvcohuuyn,
        'email': email,
        'sdt': sdt,
        'ngaysinh': ngaysinh,
      };
}
