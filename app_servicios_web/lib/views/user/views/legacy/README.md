# Legacy (fuera de flujo)

Pantallas **no enlazadas** desde `UserLayout`, `VendedorLayout` ni desde el flujo de compra actual.

| Archivo | Motivo |
|---------|--------|
| `compra_exitosa_view.dart` | Mock con folio `#IXE` y “pedido”. Reemplazada por `PaymentSuccessView` + `DetallePedidoView`. |
| `ajustes_perfil_view.dart` | Perfil fake (Mariana Gómez). Reemplazada por `MenuConfigView` con `/api/me`. |

**No importar** desde rutas activas. Conservadas solo como referencia histórica.

Reglas de UI del proyecto (anti-regresión): `lib/widgets/UI_RULES.md`.
