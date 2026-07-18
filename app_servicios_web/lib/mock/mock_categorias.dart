import '../models/categoria.dart';

/// Lista mock de categorías. En Laravel esto vendrá de `GET /api/categorias`.
/// Se dejan más de 10 a propósito para poder probar el corte + "Ver más"
/// del menú horizontal.
final List<Categoria> mockCategorias = [
  const Categoria(id: 1, nombre: 'Todo'),
  const Categoria(id: 2, nombre: 'Huipiles'),
  const Categoria(id: 3, nombre: 'Textiles'),
  const Categoria(id: 4, nombre: 'Alebrijes'),
  const Categoria(id: 5, nombre: 'Calzado'),
  const Categoria(id: 6, nombre: 'Barro Negro'),
  const Categoria(id: 7, nombre: 'Joyería'),
  const Categoria(id: 8, nombre: 'Textiles de Lana'),
  const Categoria(id: 9, nombre: 'Rebozos'),
  const Categoria(id: 10, nombre: 'Mezcal'),
  const Categoria(id: 11, nombre: 'Cestería'),
  const Categoria(id: 12, nombre: 'Talavera'),
];
