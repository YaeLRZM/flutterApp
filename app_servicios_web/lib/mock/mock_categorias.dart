import '../models/categoria.dart';

/// FALLBACK AISLADO — no usar en flujo principal del catálogo.
/// El menú de categorías del Home/Colecciones usa `GET /api/categorias`
/// cuando `kUseRealCategoriasApi` es true.
///
/// Solo prendas/textiles de Oaxaca (sin barro, alebrijes, mezcal, etc.).
/// "Todo" (id 0) es agregador de UI; en API real lo inyecta CategoriaService.
final List<Categoria> mockCategorias = [
  const Categoria(id: 0, nombre: 'Todo', esGeneral: true),
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
    nombre: 'Blusas bordadas',
    descripcion: 'Blusas de manta y algodón con bordado tradicional oaxaqueño.',
    imagen: 'mock://categoria_blusas',
  ),
  const Categoria(
    id: 4,
    nombre: 'Rebozos',
    descripcion:
        'Rebozos de seda y algodón, un complemento de la indumentaria tradicional.',
    imagen: 'mock://categoria_rebozos',
  ),
  const Categoria(
    id: 5,
    nombre: 'Vestidos',
    descripcion: 'Vestidos y trajes con bordado oaxaqueño.',
    imagen: 'mock://categoria_vestidos',
  ),
  const Categoria(
    id: 6,
    nombre: 'Camisas artesanales',
    descripcion: 'Camisas de manta y lino con detalle artesanal.',
    imagen: 'mock://categoria_camisas',
  ),
  const Categoria(
    id: 7,
    nombre: 'Textiles',
    descripcion:
        'Manteles, caminos de mesa y textiles de telar de cintura.',
    imagen: 'mock://categoria_textiles',
  ),
];
