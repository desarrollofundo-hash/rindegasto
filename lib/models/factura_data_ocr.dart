class FacturaOcrData {
  String? rucEmisor;
  String? razonSocialEmisor;
  String? tipoComprobante;
  String? serie;
  String? numero;
  String? fecha;
  String? subtotal;
  String? igv;
  String? total;
  String? moneda;
  String? rucCliente;
  String? razonSocialCliente;

  @override
  String toString() =>
      '''
RUC emisor: $rucEmisor
Razón social emisor: $razonSocialEmisor
Tipo comprobante: $tipoComprobante
Serie: $serie
Número: $numero
Fecha: $fecha
Subtotal: $subtotal
IGV: $igv
Total: $total
Moneda: $moneda
RUC cliente: $rucCliente
Razón social cliente: $razonSocialCliente
''';
}
