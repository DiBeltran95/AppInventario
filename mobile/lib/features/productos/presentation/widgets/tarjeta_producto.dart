import 'dart:io';

import 'package:flutter/material.dart';

import '../../../../core/database/daos/productos_dao.dart';
import '../../../../core/theme/app_theme.dart';

/// Fila de producto en la lista del catálogo.
///
/// El stock va a la derecha y con color, porque es el dato que se consulta de
/// un vistazo; el precio queda subordinado. En una app de inventario, «¿cuánto
/// queda?» se pregunta diez veces más que «¿cuánto vale?».
class TarjetaProducto extends StatelessWidget {
  const TarjetaProducto({
    super.key,
    required this.item,
    required this.onTap,
    this.onLongPress,
    this.mostrarCosto = false,
  });

  final ProductoConCategoria item;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final bool mostrarCosto;

  @override
  Widget build(BuildContext context) {
    final dominio = context.dominio;
    final (colorStock, fondoStock) = item.agotado
        ? (dominio.peligro, dominio.peligroContenedor)
        : item.bajoStock
            ? (dominio.advertencia, dominio.advertenciaContenedor)
            : (dominio.exito, dominio.exitoContenedor);

    return Card(
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // La transición Hero comparte la miniatura con la ficha del
              // producto: el elemento se «expande» en vez de aparecer de golpe.
              Hero(
                tag: 'producto-${item.uuid}',
                child: _Miniatura(item: item),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      item.nombre,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.textos.titleSmall,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.sku +
                          (item.categoria != null ? ' · ${item.categoria!.nombre}' : ''),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.textos.bodySmall?.copyWith(
                        color: context.colores.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Text(
                          item.precioVenta.format(),
                          style: context.textos.titleSmall
                              ?.copyWith(color: context.colores.primary),
                        ),
                        if (mostrarCosto && item.precioCompra.esPositivo) ...[
                          const SizedBox(width: 8),
                          Text(
                            'costo ${item.precioCompra.format()}',
                            style: context.textos.labelSmall?.copyWith(
                              color: context.colores.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: fondoStock,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      item.stock.format(),
                      style: context.textos.titleMedium?.copyWith(color: colorStock),
                    ),
                    Text(
                      item.producto.unidadMedida.toLowerCase(),
                      style: context.textos.labelSmall?.copyWith(color: colorStock),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Miniatura extends StatelessWidget {
  const _Miniatura({required this.item});

  final ProductoConCategoria item;

  @override
  Widget build(BuildContext context) {
    final local = item.producto.imagenLocal;
    final remota = item.producto.imagenUrl;

    Widget marcador() => Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: _colorCategoria(context),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Center(
            child: Text(
              _iniciales(item.nombre),
              style: context.textos.titleMedium?.copyWith(
                color: context.colores.onSecondaryContainer,
              ),
            ),
          ),
        );

    // La foto local tiene prioridad sobre la remota: mientras la imagen recién
    // tomada no se ha subido, la del servidor todavía no existe.
    if (local != null && File(local).existsSync()) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Image.file(
          File(local),
          width: 52,
          height: 52,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => marcador(),
        ),
      );
    }

    if (remota != null && remota.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Image.network(
          remota,
          width: 52,
          height: 52,
          fit: BoxFit.cover,
          // Sin conexión, `Image.network` falla: se cae al marcador en vez de
          // dejar un hueco roto en la lista.
          errorBuilder: (_, _, _) => marcador(),
        ),
      );
    }

    return marcador();
  }

  Color _colorCategoria(BuildContext context) {
    final hex = item.categoria?.color;
    if (hex == null || !hex.startsWith('#') || hex.length != 7) {
      return context.colores.secondaryContainer;
    }
    final valor = int.tryParse(hex.substring(1), radix: 16);
    if (valor == null) return context.colores.secondaryContainer;
    // Se mezcla con la superficie para que un color chillón elegido en el
    // catálogo no arruine la legibilidad de la lista.
    return Color(0xFF000000 | valor).withValues(alpha: 0.22);
  }

  static String _iniciales(String nombre) {
    final partes = nombre.trim().split(RegExp(r'\s+'));
    if (partes.isEmpty || partes.first.isEmpty) return '?';
    if (partes.length == 1) {
      return partes.first.substring(0, partes.first.length.clamp(0, 2)).toUpperCase();
    }
    return (partes[0][0] + partes[1][0]).toUpperCase();
  }
}
