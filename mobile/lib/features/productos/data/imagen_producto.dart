import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Persistencia de fotos de producto en el dispositivo.
///
/// `image_picker` entrega rutas del caché temporal del sistema: al reiniciar
/// la app o limpiar caché desaparecen. Se copian a Documents para que el
/// catálogo local siga mostrando la foto aunque aún no haya red para subirla.
class ImagenProducto {
  const ImagenProducto._();

  static Future<Directory> _directorio() async {
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(docs.path, 'productos'));
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  /// Copia [origen] a un archivo estable asociado al [productoUuid].
  /// Devuelve la ruta permanente, o `null` si el origen no existe.
  static Future<String?> persistir(String? origen, String productoUuid) async {
    if (origen == null || origen.isEmpty) return null;
    final fuente = File(origen);
    if (!await fuente.exists()) return null;

    final dir = await _directorio();
    final ext = p.extension(origen).toLowerCase();
    final sufijo = {'.jpg', '.jpeg', '.png', '.webp'}.contains(ext) ? ext : '.jpg';
    final destino = File(p.join(dir.path, '$productoUuid$sufijo'));

    if (p.equals(fuente.path, destino.path)) return destino.path;

    await fuente.copy(destino.path);
    return destino.path;
  }
}
