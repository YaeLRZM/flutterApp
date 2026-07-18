import '../models/cupon.dart';

/// Cupones mock por tienda. En Laravel vendrá de `GET /api/cupones` o
/// vendrá incluido en la respuesta del artículo/tienda.
final List<Cupon> mockCupones = [
  Cupon(
    id: 1,
    tiendaId: 1,
    codigo: 'OAX15',
    porcentajeDescuento: 15,
    limiteUso: 100,
    fechaExpiracion: DateTime.now().add(const Duration(days: 10)),
    compraMinima: 300,
  ),
  Cupon(
    id: 2,
    tiendaId: 2,
    codigo: 'BARRO10',
    porcentajeDescuento: 10,
    limiteUso: 50,
    fechaExpiracion: DateTime.now().add(const Duration(days: 5)),
    compraMinima: 200,
  ),
];
