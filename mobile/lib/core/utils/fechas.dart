import 'package:intl/intl.dart';

import '../config/app_config.dart';

/// Fechas de negocio.
///
/// El servidor guarda en UTC y la tienda opera en `America/Bogota` (UTC-5). Si
/// «las ventas de hoy» se calcularan con la fecha UTC, el día de la tienda se
/// cortaría a las 7:00 p. m. y las ventas de la noche caerían en el día
/// siguiente. Por eso cada venta y cada movimiento llevan su `fechaLocal` como
/// texto 'AAAA-MM-DD' calculado en la zona del negocio.
class Fechas {
  const Fechas._();

  static final _iso = DateFormat('yyyy-MM-dd');
  static final _hora = DateFormat('HH:mm', 'es_CO');
  static final _fechaHora = DateFormat("d 'de' MMMM, HH:mm", 'es_CO');
  static final _fechaCorta = DateFormat('d MMM', 'es_CO');
  static final _fechaLarga = DateFormat("EEEE d 'de' MMMM 'de' y", 'es_CO');

  /// Día hábil ('AAAA-MM-DD') correspondiente a un instante.
  static String diaHabil([DateTime? instante]) {
    final utc = (instante ?? DateTime.now()).toUtc();
    return _iso.format(utc.add(AppConfig.desfaseNegocio));
  }

  static String hoy() => diaHabil();

  static String sumarDias(String diaIso, int dias) {
    final d = DateTime.parse('${diaIso}T00:00:00Z').add(Duration(days: dias));
    return _iso.format(d.toUtc());
  }

  /// Inicio de la semana (lunes) del día indicado.
  static String inicioSemana([String? dia]) {
    final base = DateTime.parse('${dia ?? hoy()}T00:00:00Z');
    return sumarDias(_iso.format(base), -(base.weekday - 1));
  }

  static String inicioMes([String? dia]) => '${(dia ?? hoy()).substring(0, 7)}-01';

  /// Convierte un instante UTC a la hora local del negocio, para mostrarlo.
  static DateTime aHoraNegocio(DateTime utc) => utc.toUtc().add(AppConfig.desfaseNegocio);

  static String formatHora(DateTime utc) => _hora.format(aHoraNegocio(utc));
  static String formatFechaHora(DateTime utc) => _fechaHora.format(aHoraNegocio(utc));
  static String formatFechaCorta(DateTime utc) => _fechaCorta.format(aHoraNegocio(utc));

  static String formatDiaIso(String diaIso) =>
      _fechaLarga.format(DateTime.parse('${diaIso}T12:00:00'));

  static String formatDiaCorto(String diaIso) =>
      _fechaCorta.format(DateTime.parse('${diaIso}T12:00:00'));

  /// «hace 3 min», «ayer», «14 mar». Para el chip de sincronización y las listas.
  static String relativo(DateTime? utc) {
    if (utc == null) return 'nunca';
    final diferencia = DateTime.now().toUtc().difference(utc.toUtc());
    if (diferencia.inSeconds < 45) return 'hace un momento';
    if (diferencia.inMinutes < 60) return 'hace ${diferencia.inMinutes} min';
    if (diferencia.inHours < 24) return 'hace ${diferencia.inHours} h';
    if (diferencia.inDays == 1) return 'ayer';
    if (diferencia.inDays < 7) return 'hace ${diferencia.inDays} días';
    return formatFechaCorta(utc);
  }
}
