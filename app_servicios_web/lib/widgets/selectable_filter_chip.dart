import 'package:flutter/material.dart';

/// Chip de filtro tipo "Precio ▾" que, al tocarlo, abre un bottom sheet
/// con opciones seleccionables. Es genérico: quien lo usa decide qué
/// opciones mostrar y qué hacer con la seleccionada.
class SelectableFilterChip extends StatelessWidget {
  final String label;
  final bool isActive;
  final List<String> opciones;
  final String? seleccionActual;
  final ValueChanged<String?> onSeleccionar;

  const SelectableFilterChip({
    super.key,
    required this.label,
    required this.opciones,
    required this.onSeleccionar,
    this.seleccionActual,
    this.isActive = false,
  });

  Future<void> _abrirOpciones(BuildContext context) async {
    final seleccion = await showModalBottomSheet<String?>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  label,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              ListTile(
                title: const Text('Todas'),
                trailing: seleccionActual == null
                    ? const Icon(Icons.check, color: Color(0xFFD81B60))
                    : null,
                onTap: () => Navigator.pop(context, null),
              ),
              for (final opcion in opciones)
                ListTile(
                  title: Text(opcion),
                  trailing: seleccionActual == opcion
                      ? const Icon(Icons.check, color: Color(0xFFD81B60))
                      : null,
                  onTap: () => Navigator.pop(context, opcion),
                ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );

    // `seleccion` es `null` tanto si escogió "Todas" como si cerró el
    // sheet sin elegir; para este caso ambos significan "sin filtro".
    onSeleccionar(seleccion);
  }

  @override
  Widget build(BuildContext context) {
    final bool activo = isActive || seleccionActual != null;
    final String texto = seleccionActual ?? label;

    return GestureDetector(
      onTap: () => _abrirOpciones(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: activo ? const Color(0xFFD81B60) : const Color(0xFFEef4fb),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              texto,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: activo ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.keyboard_arrow_down,
              size: 16,
              color: activo ? Colors.white : Colors.black87,
            ),
          ],
        ),
      ),
    );
  }
}
