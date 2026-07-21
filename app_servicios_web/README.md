# app_servicios_web (Ixé Moda — Flutter)

Cliente Flutter del proyecto de servicios web.

## UI compartida y reglas

- Mini sistema de estados: `lib/widgets/app_ui.dart`
  (`AppLoadingView`, `AppErrorView`, `AppEmptyView`, `AppStatusBadge`, `AppProximaVersionView`, snackbars).
- **Reglas de UI (anti-regresión):** [`lib/widgets/UI_RULES.md`](lib/widgets/UI_RULES.md)
- Pantallas legacy aisladas: `lib/views/user/views/legacy/` (no importar en flujos activos).

## Principios breves

1. No inventar datos de negocio.
2. Sin backend real → “Próxima versión”.
3. Usar componentes `AppUi` para loading/error/empty/badges.
4. Copy alineada al backend: compra/venta; no pedido/envío/tracking/folio si no existen.

## Getting Started

```bash
flutter pub get
flutter run -d chrome
```

Ver también la documentación general de Flutter: https://docs.flutter.dev/
