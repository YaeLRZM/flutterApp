import 'package:flutter/foundation.dart';
import '../config/data_config.dart';

/// Guarda el carrito de compras mientras la app está abierta:
/// `articuloId -> cantidad`.
///
/// Es un singleton (`CarritoService.instance`), igual que
/// `FavoritosService`, para que `ProductDetailView`, `FavoritesView` y
/// `CartView` compartan el mismo estado sin pasarse callbacks.
///
/// TODO: API -> Persistir en el backend en vez de memoria:
///   - GET    /api/carrito                       (cargar al iniciar sesión)
///   - POST   /api/carrito/{articuloId}           (agregar / sumar cantidad)
///   - PATCH  /api/carrito/{articuloId}           (actualizar cantidad)
///   - DELETE /api/carrito/{articuloId}           (quitar)
/// `_cantidades` podría llenarse desde `cargarDesdeApi()` en vez de
/// empezar vacío.
class CarritoService extends ChangeNotifier {
  CarritoService._();
  static final CarritoService instance = CarritoService._();

  final Map<int, int> _cantidades = {};

  /// Copia inmutable: articuloId -> cantidad.
  Map<int, int> get cantidades => Map.unmodifiable(_cantidades);

  int get totalArticulos =>
      _cantidades.values.fold<int>(0, (acc, c) => acc + c);

  bool contiene(int articuloId) => _cantidades.containsKey(articuloId);

  int cantidadDe(int articuloId) => _cantidades[articuloId] ?? 0;

  void agregar(int articuloId, {int cantidad = 1}) {
    _cantidades[articuloId] = (_cantidades[articuloId] ?? 0) + cantidad;
    notifyListeners();

    if (!kUseMockData) {
      // TODO: API -> POST /api/carrito/{articuloId}
    }
  }

  void actualizarCantidad(int articuloId, int nuevaCantidad) {
    if (nuevaCantidad <= 0) {
      _cantidades.remove(articuloId);
    } else {
      _cantidades[articuloId] = nuevaCantidad;
    }
    notifyListeners();

    if (!kUseMockData) {
      // TODO: API -> PATCH/DELETE /api/carrito/{articuloId}
    }
  }

  void quitar(int articuloId) {
    _cantidades.remove(articuloId);
    notifyListeners();

    if (!kUseMockData) {
      // TODO: API -> DELETE /api/carrito/{articuloId}
    }
  }

  void vaciar() {
    _cantidades.clear();
    notifyListeners();
  }
}
