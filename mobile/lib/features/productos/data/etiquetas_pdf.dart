import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../../core/config/app_config.dart';
import '../../../core/database/daos/productos_dao.dart';

/// Etiquetas de código QR para productos sin código de fábrica.
///
/// El QR codifica `inv://p/{uuid}`, no el SKU: el SKU se puede renombrar y el
/// UUID no. Una etiqueta impresa dura años pegada al estante, así que debe
/// apuntar a algo inmutable. El SKU se imprime **debajo**, en texto, para que
/// una persona pueda leerlo si la cámara falla.
///
/// Se genera un PDF y no una imagen porque lo que se necesita es imprimir en
/// papel adhesivo A4, no compartir una foto.
class EtiquetasPdf {
  const EtiquetasPdf._();

  /// Hoja A4 con una cuadrícula de etiquetas.
  ///
  /// [copiasPorProducto] permite imprimir varias del mismo artículo: si llegan
  /// 30 unidades sin código, hacen falta 30 etiquetas iguales.
  static Future<void> imprimir(
    List<ProductoConCategoria> productos, {
    int copiasPorProducto = 1,
    String? nombreNegocio,
  }) async {
    final documento = pw.Document(title: 'Etiquetas');

    final etiquetas = <ProductoConCategoria>[
      for (final p in productos)
        for (var i = 0; i < copiasPorProducto; i++) p,
    ];

    documento.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (contexto) => [
          pw.Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              for (final producto in etiquetas) _etiqueta(producto, nombreNegocio),
            ],
          ),
        ],
      ),
    );

    await Printing.layoutPdf(
      onLayout: (formato) => documento.save(),
      name: 'etiquetas-${DateTime.now().millisecondsSinceEpoch}.pdf',
    );
  }

  static pw.Widget _etiqueta(ProductoConCategoria producto, String? negocio) {
    return pw.Container(
      width: 160,
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey400, width: 0.5),
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.BarcodeWidget(
            data: '${AppConfig.qrPrefix}${producto.uuid}',
            barcode: pw.Barcode.qrCode(
              // Corrección media: la etiqueta va pegada a un estante y se raya.
              errorCorrectLevel: pw.BarcodeQRCorrectionLevel.medium,
            ),
            width: 92,
            height: 92,
            drawText: false,
          ),
          pw.SizedBox(height: 6),
          pw.Text(
            producto.nombre,
            maxLines: 2,
            textAlign: pw.TextAlign.center,
            style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 2),
          pw.Text(producto.sku, style: const pw.TextStyle(fontSize: 7)),
          pw.Text(
            producto.precioVenta.format(),
            style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
          ),
          if (negocio != null)
            pw.Text(
              negocio,
              maxLines: 1,
              style: const pw.TextStyle(fontSize: 6, color: PdfColors.grey600),
            ),
        ],
      ),
    );
  }
}
