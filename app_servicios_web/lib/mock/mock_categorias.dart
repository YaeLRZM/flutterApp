import '../models/categoria.dart';

/// Lista mock de categorías. En Laravel esto vendrá de `GET /api/categorias`.
/// Se dejan más de 10 a propósito para poder probar el corte + "Ver más"
/// del menú horizontal del Home.
///
/// "Todo" (id 1) es un agregador usado solo en el menú del Home
/// (`esGeneral: true`); la vista de Colecciones lo excluye.
final List<Categoria> mockCategorias = [
  const Categoria(id: 1, nombre: 'Todo', esGeneral: true),
  const Categoria(
    id: 2,
    nombre: 'Huipiles',
    descripcion:
        'Tejidos a mano que narran historias ancestrales con hilos de '
        'seda y algodón natural.',
    imagen: 'mock://categoria_huipiles',
    destacada: true,
  ),
  const Categoria(
    id: 3,
    nombre: 'Textiles',
    descripcion:
        'Rebozos, manteles y prendas tejidas en telar de cintura por '
        'manos maestras de los valles centrales.',
    imagen: 'mock://categoria_textiles',
  ),
  const Categoria(
    id: 4,
    nombre: 'Alebrijes',
    descripcion:
        'Figuras de fantasía talladas en madera de copal y pintadas a '
        'mano con colores vibrantes.',
    imagen: 'mock://categoria_alebrijes',
  ),
  const Categoria(
    id: 5,
    nombre: 'Calzado',
    descripcion:
        'Huaraches y sandalias de piel elaborados con técnicas '
        'transmitidas por generaciones.',
    imagen: 'mock://categoria_calzado',
  ),
  const Categoria(
    id: 6,
    nombre: 'Barro Negro',
    descripcion:
        'Piezas de cerámica pulida a mano, características de San '
        'Bartolo Coyotepec.',
    imagen: 'mock://categoria_barro_negro',
    destacada: true,
  ),
  const Categoria(
    id: 7,
    nombre: 'Joyería',
    descripcion: 'Orfebrería fina en plata y filigrana artesanal.',
    imagen: 'mock://categoria_joyeria',
  ),
  const Categoria(
    id: 8,
    nombre: 'Textiles de Lana',
    descripcion:
        'Tapetes y sarapes tejidos con lana virgen y tintes naturales.',
    imagen: 'mock://categoria_textiles_lana',
  ),
  const Categoria(
    id: 9,
    nombre: 'Rebozos',
    descripcion:
        'Rebozos de seda y algodón, un complemento indispensable de la '
        'indumentaria tradicional.',
    imagen: 'mock://categoria_rebozos',
  ),
  const Categoria(
    id: 10,
    nombre: 'Mezcal',
    descripcion:
        'Destilados artesanales de agave, elaborados en pequeños lotes '
        'familiares.',
    imagen: 'mock://categoria_mezcal',
  ),
  const Categoria(
    id: 11,
    nombre: 'Cestería',
    descripcion: 'Canastas y sombreros tejidos a mano con palma y carrizo.',
    imagen: 'mock://categoria_cesteria',
  ),
  const Categoria(
    id: 12,
    nombre: 'Talavera',
    descripcion: 'Cerámica pintada a mano con motivos tradicionales poblanos.',
    imagen: 'mock://categoria_talavera',
  ),
];
