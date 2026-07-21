import 'carrito_service.dart';
import 'favoritos_service.dart';

/// Enlaza carrito/favoritos persistentes al usuario autenticado (o invitado).
class LocalSessionStore {
  LocalSessionStore._();

  static int? userIdFromMap(dynamic user) {
    if (user is! Map) return null;
    final id = user['id'];
    if (id is int) return id;
    return int.tryParse(id?.toString() ?? '');
  }

  /// Tras login/registro/restore de sesión.
  static Future<void> onAuthenticated({required int? userId}) async {
    await CarritoService.instance.bindUser(userId);
    await FavoritosService.instance.bindUser(userId);
  }

  /// Tras logout o sesión inválida.
  static Future<void> onGuest() async {
    await CarritoService.instance.bindUser(null);
    await FavoritosService.instance.bindUser(null);
  }

  static Future<void> ensureInitialized() async {
    if (!CarritoService.instance.isReady) {
      await CarritoService.instance.init();
    }
    if (!FavoritosService.instance.isReady) {
      await FavoritosService.instance.init();
    }
  }
}
