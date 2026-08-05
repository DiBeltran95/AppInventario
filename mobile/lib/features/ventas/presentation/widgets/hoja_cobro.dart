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
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
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
                      style: context.textos.displaySmall
                          ?.copyWith(color: context.colores.primary),
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
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
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

              const SizedBox(height: 24),
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
          Text(
            valor.format(),
            style: context.textos.headlineSmall?.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}
