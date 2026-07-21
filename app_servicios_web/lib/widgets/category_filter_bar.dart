import 'package:flutter/material.dart';
import '../config/data_config.dart';
import '../models/categoria.dart';

class CategoryFilterBar extends StatelessWidget {
  final List<Categoria> categorias;
  final int selectedCategoriaId;
  final ValueChanged<int> onSelect;

  /// Se llama al tocar "Ver más". Por ahora, mientras no exista la vista
  /// de categorías, HomeView le pasa un callback que solo muestra un
  /// mensaje. TODO: NAV -> reemplazar por Navigator.push a CategoriasView.
  final VoidCallback onVerMas;

  const CategoryFilterBar({
    super.key,
    required this.categorias,
    required this.selectedCategoriaId,
    required this.onSelect,
    required this.onVerMas,
  });

  @override
  Widget build(BuildContext context) {
    final visibles = categorias.take(kMaxCategoriasMenu).toList();

    // Altura fija holgada: texto + subrayado (~3 px overflow antes con h=40).
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          ...visibles.map((categoria) {
            final bool isSelected = categoria.id == selectedCategoriaId;
            return Padding(
              padding: const EdgeInsets.only(right: 20),
              child: GestureDetector(
                onTap: () => onSelect(categoria.id),
                behavior: HitTestBehavior.opaque,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      categoria.nombre,
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.2,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.w500,
                        color: isSelected
                            ? const Color(0xFFD81B60)
                            : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      height: 2,
                      width: 20,
                      color: isSelected
                          ? const Color(0xFFD81B60)
                          : Colors.transparent,
                    ),
                  ],
                ),
              ),
            );
          }),
          GestureDetector(
            onTap: onVerMas,
            behavior: HitTestBehavior.opaque,
            child: const Padding(
              padding: EdgeInsets.only(right: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Ver más',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.black54,
                    ),
                  ),
                  Icon(Icons.chevron_right, size: 18, color: Colors.black54),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
