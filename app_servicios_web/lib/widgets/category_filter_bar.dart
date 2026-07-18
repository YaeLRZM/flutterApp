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

    return SizedBox(
      height: 40,
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
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      categoria.nombre,
                      style: TextStyle(
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.w500,
                        color: isSelected
                            ? const Color(0xFFD81B60)
                            : Colors.black87,
                      ),
                    ),
                    if (isSelected)
                      Container(
                        margin: const EdgeInsets.only(top: 6),
                        height: 2,
                        width: 20,
                        color: const Color(0xFFD81B60),
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
