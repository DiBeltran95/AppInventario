import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/money/money.dart';
import '../../../../core/theme/app_theme.dart';

/// Resultado del cobro: cómo pagó el cliente y con cuánto.
class ResultadoCobro {
  const ResultadoCobro({required this.metodo, this.recibido});

  final String metodo;

  /// Sólo tiene sentido en efectivo; en tarjeta el importe es exacto.
  final Money? recibido;
}

/// Cómo salió el usuario de la hoja de cobro.
///
/// Hace falta distinguir «me arrepentí» de «quiero añadir otro producto»: en el
/// mostrador, lo segundo pasa constantemente —el cliente ve algo más junto a la
/// caja cuando ya estás cobrando— y dejarlo sin salida obligaba a cancelar la
/// venta entera.
enum SalidaCobro {
  /// Volver al carrito y dejarlo como está.
  volverAlCarrito,

  /// Volver al carrito Y abrir el escáner para seguir añadiendo.
  seguirAgregando,
}

/// Hoja de cobro.
///
/// El cálculo de vueltas es lo único que de verdad ocurre aquí. Los botones de
/// importe redondo (5.000, 10.000, 20.000…) existen porque el cliente casi
/// nunca paga con el importe exacto, y teclearlo entero en cada venta es el
/// paso más lento del mostrador.
class HojaCobro extends StatefulWidget {
  const HojaCobro({super.key, required this.total});

  final Money total;

  @override
  State<HojaCobro> createState() => _HojaCobroState();
}

class _HojaCobroState extends State<HojaCobro> {
  final _recibido = TextEditingController();
  String _metodo = 'EFECTIVO';

  static const _metodos = [
    (codigo: 'EFECTIVO', etiqueta: 'Efectivo', icono: Icons.payments_outlined),
    (codigo: 'TARJETA', etiqueta: 'Tarjeta', icono: Icons.credit_card_rounded),
    (codigo: 'TRANSFERENCIA', etiqueta: 'Transfer.', icono: Icons.smartphone_rounded),
  ];

  @override
  void dispose() {
    _recibido.dispose();
    super.dispose();
  }

  Money get _montoRecibido {
    final limpio = _recibido.text.trim().replaceAll('.', '').replaceAll(',', '.');
    if (limpio.isEmpty) return const Money.cero();
    return Money.tryParse(limpio);
  }

  Money get _cambio {
    final recibido = _montoRecibido;
    if (recibido <= widget.total) return const Money.cero();
    return recibido - widget.total;
  }

  bool get _puedeCobrar {
    if (_metodo != 'EFECTIVO') return true;
    // Se permite cobrar sin teclear nada: significa «pagó justo».
    final recibido = _montoRecibido;
    return recibido.esCero || recibido >= widget.total;
  }

  /// Sugerencias de billete: el importe exacto y los siguientes redondos por
  /// encima del total. En COP los billetes útiles son de 5.000 hacia arriba.
  List<Money> get _sugerencias {
    final total = widget.total;
    final sugerencias = <Money>[total];

    for (final billete in [5000, 10000, 20000, 50000, 100000]) {
      final valor = Money.deUnidades(billete);
      if (valor > total) sugerencias.add(valor);
    }

    // Redondeo al siguiente múltiplo de 1.000 (p. ej. 12.400 → 13.000).
    final unidades = (total.centavos / 100).ceil();
    final redondo = ((unidades / 1000).ceil()) * 1000;
    final aproximado = Money.deUnidades(redondo);
    if (aproximado > total && !sugerencias.contains(aproximado)) {
      sugerencias.insert(1, aproximado);
    }

    return sugerencias.take(5).toList();
  }

  @override
  Widget build(BuildContext context) {
    final esEfectivo = _metodo == 'EFECTIVO';
    final cambio = _cambio;
    final falta = _montoRecibido.esCero
        ? const Money.cero()
        : (_montoRecibido < widget.total
              ? widget.total - _montoRecibido
              : const Money.cero());

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        // Tocar cualquier zona muerta de la hoja cierra el teclado. Antes no
        // había forma de bajarlo: había que desplazarse a ciegas buscando el
        // botón de confirmar, con el cliente esperando.
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => FocusScope.of(context).unfocus(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Salida explícita. El asa de arrastre no basta: con la hoja a
                      // pantalla casi completa y un scroll dentro, el gesto de bajar se
                      // lo come el scroll, y con el teclado abierto el asa queda fuera
                      // de alcance. Un botón visible siempre funciona.
                      Row(
                        children: [
                          IconButton(
                            onPressed: () =>
                                Navigator.pop(context, SalidaCobro.volverAlCarrito),
                            icon: const Icon(Icons.arrow_back_rounded),
                            tooltip: 'Volver al carrito',
                          ),
                          Expanded(
                            child: Text(
                              'Cobrar',
                              textAlign: TextAlign.center,
                              style: context.textos.titleMedium,
                            ),
                          ),
                          // Reserva el ancho del IconButton para que el título quede
                          // centrado de verdad.
                          const SizedBox(width: 48),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Center(
                        child: Column(
                          children: [
                            Text(
                              'Total a cobrar',
                              style: context.textos.labelLarge?.copyWith(
                                color: context.colores.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.total.format(),
                              style: context.textos.displaySmall?.copyWith(
                                color: context.colores.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      SegmentedButton<String>(
                        segments: [
                          for (final m in _metodos)
                            ButtonSegment(
                              value: m.codigo,
                              label: Text(m.etiqueta),
                              icon: Icon(m.icono),
                            ),
                        ],
                        selected: {_metodo},
                        onSelectionChanged: (s) => setState(() => _metodo = s.first),
                      ),

                      if (esEfectivo) ...[
                        const SizedBox(height: 20),
                        TextField(
                          controller: _recibido,
                          autofocus: true,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          // El teclado numérico de Android no trae tecla de aceptar por
                          // sí solo; con esto aparece «Listo» y se puede cerrar sin
                          // salir del campo.
                          textInputAction: TextInputAction.done,
                          onSubmitted: (_) => FocusScope.of(context).unfocus(),
                          onChanged: (_) => setState(() {}),
                          style: context.textos.headlineSmall,
                          decoration: const InputDecoration(
                            labelText: 'Con cuánto paga',
                            prefixText: r'$ ',
                            helperText: 'Déjalo vacío si paga justo',
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final sugerencia in _sugerencias)
                              ActionChip(
                                label: Text(sugerencia.format()),
                                onPressed: () {
                                  _recibido.text = sugerencia.formatSinSimbolo();
                                  HapticFeedback.selectionClick();
                                  setState(() {});
                                },
                              ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          child: falta.esPositivo
                              ? _Resaltado(
                                  key: const ValueKey('falta'),
                                  etiqueta: 'Falta',
                                  valor: falta,
                                  color: context.dominio.peligro,
                                  fondo: context.dominio.peligroContenedor,
                                )
                              : _Resaltado(
                                  key: const ValueKey('cambio'),
                                  etiqueta: 'Cambio a devolver',
                                  valor: cambio,
                                  color: context.dominio.exito,
                                  fondo: context.dominio.exitoContenedor,
                                ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              // Botonera FIJA. Al vivir fuera del scroll, queda siempre visible
              // justo encima del teclado: confirmar deja de exigir un gesto de
              // búsqueda.
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    FilledButton.icon(
                      onPressed: _puedeCobrar
                          ? () => Navigator.pop(
                              context,
                              ResultadoCobro(
                                metodo: _metodo,
                                recibido: esEfectivo && !_montoRecibido.esCero
                                    ? _montoRecibido
                                    : null,
                              ),
                            )
                          : null,
                      icon: const Icon(Icons.check_circle_outline_rounded),
                      label: const Text('Confirmar venta'),
                      style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(56)),
                    ),
                    const SizedBox(height: 10),
                    // El caso real que faltaba: ya estás cobrando y el cliente añade
                    // algo más. Antes había que cancelar el cobro a ciegas.
                    OutlinedButton.icon(
                      onPressed: () => Navigator.pop(context, SalidaCobro.seguirAgregando),
                      icon: const Icon(Icons.add_shopping_cart_rounded, size: 18),
                      label: const Text('Agregar otro producto'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                      ),
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

class _Resaltado extends StatelessWidget {
  const _Resaltado({
    super.key,
    required this.etiqueta,
    required this.valor,
    required this.color,
    required this.fondo,
  });

  final String etiqueta;
  final Money valor;
  final Color color;
  final Color fondo;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(color: fondo, borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: [
          Text(etiqueta, style: context.textos.titleSmall?.copyWith(color: color)),
          const Spacer(),
          Text(valor.format(), style: context.textos.headlineSmall?.copyWith(color: color)),
        ],
      ),
    );
  }
}
