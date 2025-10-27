class AuditoriaModel {
  final int id;
  final int idInf;
  final int idUser;
  final String? dni;
  final String? ruc;
  final String? titulo;
  final String? nota;
  final String? politica;
  final String? obs;
  final String? estadoActual;
  final String? estado;
  final String? fecCre;
  final int? useReg;
  final String? hostname;
  final String? fecEdit;
  final int? useEdit;
  final int? useElim;
  final int? cantidad;
  final double? total;
  final int? cantidadAprobado;
  final double? totalAprobado;
  final int? cantidadDesaprobado;
  final double? totalDesaprobado;

  AuditoriaModel({
    required this.id,
    required this.idInf,
    required this.idUser,
    this.dni,
    this.ruc,
    this.titulo,
    this.nota,
    this.politica,
    this.obs,
    this.estadoActual,
    this.estado,
    this.fecCre,
    this.useReg,
    this.hostname,
    this.fecEdit,
    this.useEdit,
    this.useElim,
    this.cantidad,
    this.total,
    this.cantidadAprobado,
    this.totalAprobado,
    this.cantidadDesaprobado,
    this.totalDesaprobado,
  });

  Map<String, dynamic> toMap() {
    return {
      'idAd': id,
      'idInf': idInf,
      'idUser': idUser,
      'dni': dni,
      'ruc': ruc,
      'titulo': titulo,
      'nota': nota,
      'politica': politica,
      'obs': obs,
      'estadoActual': estadoActual,
      'estado': estado,
      'fecCre': fecCre,
      'useReg': useReg,
      'hostname': hostname,
      'fecEdit': fecEdit,
      'useEdit': useEdit,
      'useElim': useElim,
      'cantidad': cantidad,
      'total': total,
      'cantidadAprobado': cantidadAprobado,
      'totalAprobado': totalAprobado,
      'cantidadDesaprobado': cantidadDesaprobado,
      'totalDesaprobado': totalDesaprobado,
    };
  }

  factory AuditoriaModel.fromJson(Map<String, dynamic> map) {
    return AuditoriaModel(
      id: map['idAd'],
      idInf: map['idInf'],
      idUser: map['idUser'],
      dni: map['dni'],
      ruc: map['ruc'],
      titulo: map['titulo'],
      nota: map['nota'],
      politica: map['politica'],
      obs: map['obs'],
      estadoActual: map['estadoActual'],
      estado: map['estado'],
      fecCre: map['fecCre'],
      useReg: map['useReg'],
      hostname: map['hostname'],
      fecEdit: map['fecEdit'],
      useEdit: map['useEdit'],
      useElim: map['useElim'],
      cantidad: map['cantidad'],
      total: map['total']?.toDouble(),
      cantidadAprobado: map['cantidadAprobado'],
      totalAprobado: map['totalAprobado']?.toDouble(),
      cantidadDesaprobado: map['cantidadDesaprobado'],
      totalDesaprobado: map['totalDesaprobado']?.toDouble(),
    );
  }

  AuditoriaModel copyWith({
    int? id,
    int? idInf,
    int? idUser,
    String? dni,
    String? ruc,
    String? titulo,
    String? nota,
    String? politica,
    String? obs,
    String? estadoActual,
    String? estado,
    String? fecCre,
    int? useReg,
    String? hostname,
    String? fecEdit,
    int? useEdit,
    int? useElim,
    int? cantidad,
    double? total,
    int? cantidadAprobado,
    double? totalAprobado,
    int? cantidadDesaprobado,
    double? totalDesaprobado,
  }) {
    return AuditoriaModel(
      id: id ?? this.id,
      idInf: idInf ?? this.idInf,
      idUser: idUser ?? this.idUser,
      dni: dni ?? this.dni,
      ruc: ruc ?? this.ruc,
      titulo: titulo ?? this.titulo,
      nota: nota ?? this.nota,
      politica: politica ?? this.politica,
      obs: obs ?? this.obs,
      estadoActual: estadoActual ?? this.estadoActual,
      estado: estado ?? this.estado,
      fecCre: fecCre ?? this.fecCre,
      useReg: useReg ?? this.useReg,
      hostname: hostname ?? this.hostname,
      fecEdit: fecEdit ?? this.fecEdit,
      useEdit: useEdit ?? this.useEdit,
      useElim: useElim ?? this.useElim,
      cantidad: cantidad ?? this.cantidad,
      total: total ?? this.total,
      cantidadAprobado: cantidadAprobado ?? this.cantidadAprobado,
      totalAprobado: totalAprobado ?? this.totalAprobado,
      cantidadDesaprobado: cantidadDesaprobado ?? this.cantidadDesaprobado,
      totalDesaprobado: totalDesaprobado ?? this.totalDesaprobado,
    );
  }
}
