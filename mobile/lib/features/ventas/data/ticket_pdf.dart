import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/daos/ventas_dao.dart';
import '../../../core/money/money.dart';
import '../../../core/utils/fechas.dart';

/// Comprobante de venta.
///
/// El formato es de **rollo de 80 mm**, no A4: lo normal en un mostrador es una
/// impresora térmica. `PdfPageFormat.roll80` deja la altura libre, así que un
/// ticket de 3 líneas no desperdicia media hoja.
///
/// Se genera desde los datos ya guardados en SQLite: imprimir un ticket no
/// necesita conexión, igual que cobrarlo.
class TicketPdf {
  const TicketPdf._();

  static Future<Uint8List> generar(
    VentaCompleta venta, {
    required String nombreNegocio,
    String? nit,
    String? direccion,
    String? telefono,
    String? mensajeFinal,
  }) async {
    final documento = pw.Document(title: 'Ticket ${venta.venta.numero}');
    final v = venta.venta;

    documento.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80.copyWith(
          marginLeft: 8,
          marginRight: 8,
          marginTop: 10,
          marginBottom: 10,
        ),
        build: (contexto) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: [
            pw.Center(
              child: pw.Text(
                nombreNegocio,
                style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold),
              ),
            ),
            if (nit != null) pw.Center(child: pw.Text('NIT $nit', style: _pequeno)),
            if (direccion != null) pw.Center(child: pw.Text(direccion, style: _pequeno)),
            if (telefono != null) pw.Center(child: pw.Text(telefono, style: _pequeno)),
            pw.SizedBox(height: 8),
            _divisor(),
            _fila('Ticket', v.numero, negrita: true),
            _fila('Fecha', Fechas.formatFechaHora(v.fecha)),
            if (v.clienteNombre != null) _fila('Cliente', v.clienteNombre!),
            if (v.estado == 'ANULADA')
              pw.Center(
                child: pw.Text(
                  '*** ANULADA ***',
                  style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
                ),
              ),
            _divisor(),

            for (final d in venta.detalles) _linea(d),

            _divisor(),
            _fila('Subtotal', Money(v.subtotal).format()),
            if (v.descuentoTotal != 0)
              _fila('Descuento', '-${Money(v.descuentoTotal).format()}'),
            _fila('IVA', Money(v.impuestoTotal).format()),
            pw.SizedBox(height: 3),
            _fila('TOTAL', Money(v.total).format(), negrita: true, tamano: 12),
            _divisor(),
            _fila('Pago', _metodo(v.metodoPago)),
            if (v.montoRecibido != null)
              _fila('Recibido', Money(v.montoRecibido!).format()),
            if (v.cambio != null && v.cambio! > 0)
              _fila('Cambio', Money(v.cambio!).format(), negrita: true),

            pw.SizedBox(height: 10),
            // Marca honesta del estado real del documento. Si la venta aún no
            // salió del dispositivo, el ticket lo dice: es preferible a que el
            // dueño lo descubra al cuadrar caja.
            if (venta.pendienteDeSync)
              pw.Center(
                child: pw.Text(
                  'Pendiente de sincronizar',
                  style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey700),
                ),
              ),
            pw.SizedBox(height: 6),
            pw.Center(
              child: pw.Text(
                mensajeFinal ?? '¡Gracias por su compra!',
                style: _pequeno,
              ),
            ),
          ],
        ),
      ),
    );

    return documento.save();
  }

  /// Abre el diálogo de impresión del sistema (incluye «Guardar como PDF»).
  static Future<void> imprimir(VentaCompleta venta, {required String nombreNegocio}) async {
    final bytes = await generar(venta, nombreNegocio: nombreNegocio);
    await Printing.layoutPdf(
      onLayout: (formato) => bytes,
      name: 'ticket-${venta.venta.numero}.pdf',
    );
  }

  /// Comparte el ticket por WhatsApp, correo, etc.
  static Future<void> compartir(VentaCompleta venta, {required String nombreNegocio}) async {
    final bytes = await generar(venta, nombreNegocio: nombreNegocio);
    await Printing.sharePdf(bytes: bytes, filename: 'ticket-${venta.venta.numero}.pdf');
  }

  // ── Piezas ────────────────────────────────────────────────────────────────

  static const _pequeno = pw.TextStyle(fontSize: 7);

  static pw.Widget _divisor() => pw.Padding(
        padding: const pw.EdgeInsets.symmetric(vertical: 4),
        child: pw.Divider(height: 0.5, borderStyle: pw.BorderStyle.dashed),
      );

  static pw.Widget _fila(
    String etiqueta,
    String valor, {
    bool negrita = false,
    double tamano = 8,
  }) {
    final estilo = pw.TextStyle(
      fontSize: tamano,
      fontWeight: negrita ? pw.FontWeight.bold : pw.FontWeight.normal,
    );
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 1),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(etiqueta, style: estilo),
          pw.Text(valor, style: estilo),
        ],
      ),
    );
  }

  static pw.Widget _linea(VentaDetalle detalle) {
    final cantidad = Cantidad(detalle.cantidad);
    final precio = Money(detalle.precioUnitario);
    final total = Money(detalle.total);

    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 3),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          pw.Text(detalle.descripcion, style: const pw.TextStyle(fontSize: 8)),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                '${cantidad.format()} × ${precio.format()}',
                style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey700),
              ),
              pw.Text(total.format(), style: const pw.TextStyle(fontSize: 8)),
            ],
          ),
        ],
      ),
    );
  }

  static String _metodo(String codigo) => switch (codigo) {
        'EFECTIVO' => 'Efectivo',
        'TARJETA' => 'Tarjeta',
        'TRANSFERENCIA' => 'Transferencia',
        'CREDITO' => 'Crédito',
        'MIXTO' => 'Mixto',
        _ => codigo,
      };
}
