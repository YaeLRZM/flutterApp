/// Configuración central de fuente de datos.
///
/// Mientras `kUseMockData` sea `true`, todos los `services/*` regresan
/// datos de prueba (carpeta `mock/`) en vez de llamar a la API de Laravel.
///
/// Cuando el backend esté listo, basta con:
///   1. Cambiar este valor a `false`.
///   2. Completar los métodos marcados con `// TODO: API` dentro de
///      cada archivo en `services/` (ahí ya está el "contrato" definido:
///      qué recibe y qué debe regresar cada método).
///
/// No hace falta tocar ninguna vista: las vistas solo conocen los
/// `services`, nunca de dónde vienen los datos.
/// Módulos secundarios (carrito, cupones, reseñas, etc.) aún pueden usar mock.
/// Catálogo principal (artículos + categorías) usa API real vía flags abajo.
const bool kUseMockData = true;

/// Bypass: [ArticuloService] usa Laravel aunque [kUseMockData] sea true.
const bool kUseRealArticulosApi = true;

/// Bypass: [CategoriaService] usa Laravel aunque [kUseMockData] sea true.
const bool kUseRealCategoriasApi = true;

/// Máximo de publicaciones que se muestran en el feed principal antes de
/// cortar y ofrecer el botón "Ver categorías".
const int kMaxArticulosHome = 25;

/// Máximo de artículos que se muestran al entrar al detalle de una
/// categoría (CategoryDetailView).
const int kMaxArticulosCategoria = 50;

/// Reglas de envío del carrito.
/// TODO: API -> esto debería venir de una tabla de configuración /
/// políticas de envío, no como constantes en la app.
const double kCostoEnvioNacional = 150.0;
const double kEnvioGratisDesde = 3000.0;

/// Máximo de categorías visibles en el menú horizontal antes de mostrar
/// el chip "Ver más".
const int kMaxCategoriasMenu = 10;
