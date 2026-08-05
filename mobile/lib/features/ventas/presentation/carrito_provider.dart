import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/daos/productos_dao.dart';
import '../../../core/database/daos/ventas_dao.dart';
import '../../../core/money/money.dart';
import '../../../core/providers/providers.dart';
import '../../auth/presentation/auth_providers.dart';

/// Una línea del carrito.
///
/// Guarda el precio y el costo **en el momento de añadirla**, no una referencia
/// al producto: si el catálogo se sincroniza a mitad de una venta y cambia un
/// precio, el importe que el cliente ya vio en pantalla no debe moverse.
class LineaCarrito {
  const LineaCarrito({
    required this.productoUuid,
    required this.nombre,
    required this.sku,
    required this.unidadMedida,
    required this.cantidad,
    required this.precioUnitario,
    required this.costoUnitario,
    required this.tasaIva,
    this.descuento = const Money.cero(),
    required this.stockDisponible,
  });

  final String productoUuid;
  final String nombre;
  final String sku;
  final String unidadMedida;
  final Cantidad cantidad;
  final Money precioUnitario;
  final Money costoUnitario;
  final TasaIva tasaIva;
  final Money descuento;

  /// Stock que había al añadir la línea. Sirve para avisar de sobreventa; no
  /// para impedirla: si el cliente ya se lleva el producto, la venta se
  /// registra igual.
  final Cantidad stockDisponible;

  LineaCalculada get calculo => calcularLinea(
        precioUnitario: precioUnitario,
        cantidad: cantidad,
        descuento: descuento,
        tasaIva: tasaIva,
      );

  Money get total => calculo.total;
  bool get excedeStock => cantidad > stockDisponible;

  LineaCarrito copyWith({Cantidad? cantidad, Money? precioUnitario, Money? descuento}) =>
      LineaCarrito(
        productoUuid: productoUuid,
        nombre: nombre,
        sku: sku,
        unidadMedida: unidadMedida,
        cantidad: cantidad ?? this.cantidad,
        precioUnitario: precioUnitario ?? this.precioUnitario,
        costoUnitario: costoUnitario,
        tasaIva: tasaIva,
        descuento: descuento ?? this.descuento,
        stockDisponible: stockDisponible,
      );

  LineaParaVender aVenta() => LineaParaVender(
        productoUuid: productoUuid,
        descripcion: nombre,
        sku: sku,
        cantidad: cantidad,
        precioUnitario: precioUnitario,
        costoUnitario: costoUnitario,
        tasaIva: tasaIva,
        descuento: descuento,
      );
}

class CarritoEstado {
  const CarritoEstado({
    this.lineas = const [],
    this.clienteNombre,
    this.clienteDocumento,
    this.metodoPago = 'EFECTIVO',
    this.notas,
    this.ultimaAgregada,
  });

  final List<LineaCarrito> lineas;
  final String? clienteNombre;
  final String? clienteDocumento;
  final String metodoPago;
  final String? notas;

  /// UUID de la última línea tocada, para resaltarla un instante en la lista.
  final String? ultimaAgregada;

  bool get vacio => lineas.isEmpty;

  /// Número de artículos (suma de cantidades, redondeada hacia arriba para las
  /// fraccionarias: 0,750 kg cuenta como 1 artículo en el contador).
  int get articulos => lineas.fold(
        0,
        (a, l) => a + (l.cantidad.milesimas / 1000).ceil(),
      );

  Money get subtotal => Money.sumar(lineas.map((l) => l.calculo.base));
  Money get impuesto => Money.sumar(lineas.map((l) => l.calculo.impuesto));
  Money get descuento => Money.sumar(lineas.map((l) => l.calculo.descuento));
  Money get total => Money.sumar(lineas.map((l) => l.calculo.total));

  bool get hayExcesoDeStock => lineas.any((l) => l.excedeStock);

  CarritoEstado copyWith({
    List<LineaCarrito>? lineas,
    String? clienteNombre,
    String? clienteDocumento,
    String? metodoPago,
    String? notas,
    String? ultimaAgregada,
    bool limpiarUltima = false,
  }) =>
      CarritoEstado(
        lineas: lineas ?? this.lineas,
        clienteNombre: clienteNombre ?? this.clienteNombre,
        clienteDocumento: clienteDocumento ?? this.clienteDocumento,
        metodoPago: metodoPago ?? this.metodoPago,
        notas: notas ?? this.notas,
        ultimaAgregada: limpiarUltima ? null : (ultimaAgregada ?? this.ultimaAgregada),
      );
}

class CarritoNotifier extends Notifier<CarritoEstado> {
  @override
  CarritoEstado build() => const CarritoEstado();

  /// Añade un producto. Si ya está en el carrito, incrementa su cantidad en vez
  /// de crear una segunda línea: escanear el mismo artículo tres veces debe dar
  /// «×3», no tres filas iguales.
  void agregar(ProductoConCategoria producto, {Cantidad? cantidad}) {
    final aSumar = cantidad ?? Cantidad.unidades(1);
    final indice = state.lineas.indexWhere((l) => l.productoUuid == producto.uuid);

    if (indice >= 0) {
      final actual = state.lineas[indice];
      final nuevas = [...state.lineas];
      nuevas[indice] = actual.copyWith(cantidad: actual.cantidad + aSumar);
      state = state.copyWith(lineas: nuevas, ultimaAgregada: producto.uuid);
      return;
    }

    state = state.copyWith(
      lineas: [
        ...state.lineas,
        LineaCarrito(
          productoUuid: producto.uuid,
          nombre: producto.nombre,
          sku: producto.sku,
          unidadMedida: producto.producto.unidadMedida,
          cantidad: aSumar,
          precioUnitario: producto.precioVenta,
          costoUnitario: producto.precioCompra,
          tasaIva: producto.tasaIva,
          stockDisponible: producto.stock,
        ),
      ],
      ultimaAgregada: producto.uuid,
    );
  }

  void cambiarCantidad(String productoUuid, Cantidad cantidad) {
    if (cantidad.milesimas <= 0) return quitar(productoUuid);
    state = state.copyWith(
      lineas: [
        for (final l in state.lineas)
          l.productoUuid == productoUuid ? l.copyWith(cantidad: cantidad) : l,
      ],
    );
  }

  void incrementar(String productoUuid) {
    final linea = state.lineas.firstWhere((l) => l.productoUuid == productoUuid);
    cambiarCantidad(productoUuid, linea.cantidad + Cantidad.unidades(1));
  }

  void decrementar(String productoUuid) {
    final linea = state.lineas.firstWhere((l) => l.productoUuid == productoUuid);
    cambiarCantidad(productoUuid, linea.cantidad - Cantidad.unidades(1));
  }

  void cambiarPrecio(String productoUuid, Money precio) {
    state = state.copyWith(
      lineas: [
        for (final l in state.lineas)
          l.productoUuid == productoUuid ? l.copyWith(precioUnitario: precio) : l,
      ],
    );
  }

  void aplicarDescuento(String productoUuid, Money descuento) {
    state = state.copyWith(
      lineas: [
        for (final l in state.lineas)
          l.productoUuid == productoUuid ? l.copyWith(descuento: descuento) : l,
      ],
    );
  }

  void quitar(String productoUuid) {
    state = state.copyWith(
      lineas: state.lineas.where((l) => l.productoUuid != productoUuid).toList(),
      limpiarUltima: true,
    );
  }

  /// Deshacer del último escaneo: quita la línea si tenía una unidad, o resta
  /// una si tenía varias. Es lo que espera quien pulsa «Deshacer» tras leer un
  /// código por error.
  void deshacerUltimo() {
    final uuid = state.ultimaAgregada;
    if (uuid == null) return;
    final indice = state.lineas.indexWhere((l) => l.productoUuid == uuid);
    if (indice < 0) return;

    final linea = state.lineas[indice];
    if (linea.cantidad <= Cantidad.unidades(1)) {
      quitar(uuid);
    } else {
      cambiarCantidad(uuid, linea.cantidad - Cantidad.unidades(1));
    }
    state = state.copyWith(limpiarUltima: true);
  }

  void fijarCliente({String? nombre, String? documento}) {
    state = state.copyWith(clienteNombre: nombre, clienteDocumento: documento);
  }

  void fijarMetodoPago(String metodo) => state = state.copyWith(metodoPago: metodo);
  void fijarNotas(String? notas) => state = state.copyWith(notas: notas);

  void vaciar() => state = const CarritoEstado();

  /// Cobra: escribe la venta en la base local y la encola. **No toca la red.**
  Future<VentaCompleta> cobrar({Money? montoRecibido}) async {
    if (state.vacio) {
      throw StateError('El carrito está vacío');
    }

    final dao = ref.read(ventasDaoProvider);
    final sesion = ref.read(sesionProvider).value;

    final venta = await dao.registrarVenta(
      lineas: state.lineas.map((l) => l.aVenta()).toList(),
      metodoPago: state.metodoPago,
      montoRecibido: montoRecibido,
      clienteNombre: state.clienteNombre,
      clienteDocumento: state.clienteDocumento,
      notas: state.notas,
      usuarioUuid: sesion?.usuarioUuid,
    );

    vaciar();
    // Intento inmediato de envío, con rebote. Si no hay red, la venta ya está a
    // salvo en SQLite y saldrá sola cuando vuelva.
    ref.read(syncEngineProvider).solicitar();

    return venta;
  }
}

final carritoProvider =
    NotifierProvider<CarritoNotifier, CarritoEstado>(CarritoNotifier.new);
