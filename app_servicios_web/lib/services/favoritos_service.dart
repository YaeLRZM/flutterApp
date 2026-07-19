import 'package:flutter/foundation.dart';
import '../config/data_config.dart';

/// Guarda los favoritos del usuario mientras la app está abierta.
///
/// Es un singleton simple (`FavoritosService.instance`) para que
/// `HomeView` y `ProductDetailView` (y cualquier otra vista) compartan el
/// mismo estado sin pasar callbacks de un lado a otro.
///
/// TODO: API -> Persistir en el backend en vez de memoria:
///   - GET  /api/favoritos            (cargar al iniciar sesión)
///   - POST /api/favoritos/{articuloId}    (marcar)
///   - DELETE /api/favoritos/{articuloId}  (desmarcar)
/// El día que eso exista, `toggle()` debe llamar al endpoint y
/// `_favoritos` puede llenarse desde `cargarDesdeApi()` en vez de
/// empezar vacío.
class FavoritosService extends ChangeNotifier {
  FavoritosService._();
  static final FavoritosService instance = FavoritosService._();

  final Set<int> _favoritos = {};

  bool esFavorito(int articuloId) => _favoritos.contains(articuloId);

  /// Copia inmutable de los ids favoritos actuales, para que
  /// `FavoritesView` pueda pedirle sus artículos a `ArticuloService`.
  Set<int> get ids => Set.unmodifiable(_favoritos);

  void toggle(int articuloId) {
    if (_favoritos.contains(articuloId)) {
      _favoritos.remove(articuloId);
    } else {
      _favoritos.add(articuloId);
    }
    notifyListeners();

    if (!kUseMockData) {
      // TODO: API -> POST/DELETE /api/favoritos/{articuloId}
    }
  }
}
