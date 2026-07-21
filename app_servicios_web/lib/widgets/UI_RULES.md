# Reglas UI — Ixé Moda (Flutter)

Guía corta para **no reintroducir mocks engañosos**, estados UI duplicados ni copy inconsistente.
Complementa el mini sistema en `app_ui.dart`.

## 1. Honestidad de datos

- **No inventar datos** de negocio: métricas, reseñas, notificaciones, ventas, stock, nombres de usuario o tienda.
- Si no hay backend real para una pantalla, usar **“Próxima versión”** (snackbar `AppUi.showProximamente` o pantalla `AppProximaVersionView` / alias comprador).
- Preferir vacío honesto o error de API antes que rellenar con mocks “bonitos”.

## 2. Copy y semántica

- **Compra / venta** (modelo real `Venta`). Evitar **pedido / envío / tracking / guía / folio** si el backend no lo expone.
- No prometer pasarela, monedero, envíos ni bandeja de notificaciones.
- Pago actual = **simulado** → badge `AppStatusBadge.pagoSimulado()`, nunca folio inventado.
- Nombres de archivo históricos (ej. `detalle_pedido_view.dart`) no obligan copy de “pedido” en UI.

## 3. Componentes compartidos (`app_ui.dart`)

| Caso | Usar |
|------|------|
| Loading de pantalla / cuerpo principal | `AppLoadingView` |
| Error + reintentar | `AppErrorView` |
| Lista / sección vacía (simple) | `AppEmptyView` |
| Feature no implementada (pantalla) | `AppProximaVersionView` |
| Feature no implementada (tap) | `AppUi.showProximamente` |
| Éxito / error puntual de acción | `AppUi.showInfo` / `AppUi.showError` |
| Etiqueta de estado honesta | `AppStatusBadge` (próxima versión, pago simulado) |

- **No** badges falsos (conteos inventados, “nuevo” sin dato, notificaciones con número inventado).
- Loaders **inline** (botón, sheet, avatar pequeño) pueden seguir con `CircularProgressIndicator`; no duplicar pantallas full-page de loading/error a mano.

## 4. Legacy y mocks

- `lib/views/user/views/legacy/` está **fuera del flujo activo**. **No importar** desde layouts ni rutas vivas.
- `lib/mock/` y `kUseMockData` existen por módulos aún no migrados; **no** usar mocks para inventar UI de features “listas”.
- Artículos/categorías activos usan API real vía flags en `config/data_config.dart`.

## 5. Qué no hacer en PRs pequeños

- No nuevas features ni rediseños “de pasada”.
- No reabrir pantallas legacy en el menú.
- No copiar chips/badges/estados de loading custom si ya hay equivalente en `AppUi`.
- No mezclar copy de e-commerce clásico (pedido/envío) con el modelo actual (venta/compra sin logística).

## 6. Checklist rápido antes de merge

- [ ] ¿Los números/listas vienen de API o de estado local explícito (carrito/favoritos)?
- [ ] ¿Si no hay backend, dice “próxima versión”?
- [ ] ¿Loading/error/empty de pantalla usan `AppUi`?
- [ ] ¿Snack de “próxima versión” usa `AppUi.showProximamente`?
- [ ] ¿Sin imports a `legacy/`?
- [ ] ¿Sin badges o nombres inventados?

---

*Hardening ligero post-consolidación AppUi. Actualizar solo si cambian reglas de producto, no por estilo visual.*
