import 'package:flutter/material.dart';

/// Galería de imágenes del detalle de producto: imagen principal grande
/// con flechas + puntos de paginación, y una fila de miniaturas debajo.
///
/// Recibe una lista de "imágenes" (por ahora identificadores mock); el
/// día que haya URLs reales solo hay que cambiar el `Container` gris de
/// `_buildImageBox` por `Image.network(url, fit: BoxFit.cover)`.
class ProductImageGallery extends StatefulWidget {
  final List<String> imagenes;

  const ProductImageGallery({super.key, required this.imagenes});

  @override
  State<ProductImageGallery> createState() => _ProductImageGalleryState();
}

class _ProductImageGalleryState extends State<ProductImageGallery> {
  late final PageController _controller;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _controller = PageController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _next() {
    if (_currentPage < widget.imagenes.length - 1) {
      setState(() => _currentPage++);
      _controller.animateToPage(
        _currentPage,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    }
  }

  void _prev() {
    if (_currentPage > 0) {
      setState(() => _currentPage--);
      _controller.animateToPage(
        _currentPage,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.imagenes.isEmpty) {
      return Container(
        height: 350,
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(16),
        ),
      );
    }

    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: SizedBox(
                height: 350,
                width: double.infinity,
                child: PageView.builder(
                  controller: _controller,
                  itemCount: widget.imagenes.length,
                  onPageChanged: (i) => setState(() => _currentPage = i),
                  itemBuilder: (context, index) {
                    // TODO: API -> Image.network(widget.imagenes[index])
                    return Container(color: Colors.grey[300]);
                  },
                ),
              ),
            ),
            if (widget.imagenes.length > 1) ...[
              Positioned(
                left: 10,
                child: CircleAvatar(
                  backgroundColor: Colors.white.withOpacity(0.5),
                  child: IconButton(
                    icon: const Icon(Icons.chevron_left, color: Colors.white),
                    onPressed: _prev,
                  ),
                ),
              ),
              Positioned(
                right: 10,
                child: CircleAvatar(
                  backgroundColor: Colors.white.withOpacity(0.5),
                  child: IconButton(
                    icon: const Icon(Icons.chevron_right, color: Colors.white),
                    onPressed: _next,
                  ),
                ),
              ),
              Positioned(
                bottom: 16,
                child: Row(
                  children: List.generate(widget.imagenes.length, (i) {
                    final bool active = i == _currentPage;
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: 20,
                      height: 4,
                      decoration: BoxDecoration(
                        color: active ? Colors.white : Colors.white54,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    );
                  }),
                ),
              ),
            ],
          ],
        ),
        if (widget.imagenes.length > 1) ...[
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(widget.imagenes.length, (i) {
              final bool selected = i == _currentPage;
              return GestureDetector(
                onTap: () {
                  setState(() => _currentPage = i);
                  _controller.animateToPage(
                    i,
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeOut,
                  );
                },
                child: Container(
                  width: 75,
                  height: 75,
                  decoration: BoxDecoration(
                    color: Colors.grey[400],
                    borderRadius: BorderRadius.circular(12),
                    border: selected
                        ? Border.all(color: const Color(0xFFD81B60), width: 2)
                        : null,
                  ),
                ),
              );
            }),
          ),
        ],
      ],
    );
  }
}
