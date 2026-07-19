import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'vendedor_tienda_screen.dart'; // Importar la siguiente pantalla

class VendedorIdentidadScreen extends StatefulWidget {
  const VendedorIdentidadScreen({super.key});

  @override
  State<VendedorIdentidadScreen> createState() => _VendedorIdentidadScreenState();
}

class _VendedorIdentidadScreenState extends State<VendedorIdentidadScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _ineController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F5F2),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F5F2),
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFFD81B60), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Ixé Moda',
          style: GoogleFonts.cormorantGaramond(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: const Color(0xFFD81B60),
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(40),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: _buildProgress(1),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Validar Identidad',
              style: GoogleFonts.dmSans(fontSize: 26, fontWeight: FontWeight.bold, color: const Color(0xFF0F2C59)),
            ),
            const SizedBox(height: 8),
            Text(
              'Sube tus documentos oficiales para empezar a vender piezas únicas.',
              style: GoogleFonts.dmSans(fontSize: 15, color: Colors.black54, height: 1.3),
            ),
            const SizedBox(height: 32),
            _buildTextField('Correo Electrónico', _emailController, Icons.email_outlined, hint: 'ejemplo@correo.com'),
            const SizedBox(height: 24),
            _buildTextField('Código INE', _ineController, Icons.fingerprint, hint: 'Ingresa los 13 dígitos traseros'),
            const SizedBox(height: 32),
            _buildPhotoUpload('Foto Frontal INE', 'Toca para capturar el frente'),
            const SizedBox(height: 24),
            _buildPhotoUpload('Foto Trasera INE', 'Toca para capturar el reverso'),
            const SizedBox(height: 48),
            Center(
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const VendedorTiendaScreen()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD81B60),
                    elevation: 2,
                    shadowColor: const Color(0xFFD81B60).withOpacity(0.4),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Continuar', style: GoogleFonts.dmSans(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white)),
                      const SizedBox(width: 8),
                      const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.white),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildProgress(int current) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 60),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildStep(1, current),
          _buildLine(1 < current),
          _buildStep(2, current),
          _buildLine(2 < current),
          _buildStep(3, current),
        ],
      ),
    );
  }

  Widget _buildStep(int number, int current) {
    bool isActive = number == current;
    bool isDone = number < current;
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isActive 
            ? const Color(0xFFD81B60) 
            : (isDone ? const Color(0xFFD81B60) : Colors.grey.shade300),
      ),
      child: Center(
        child: Text(
          '$number',
          style: GoogleFonts.dmSans(
            color: isActive || isDone ? Colors.white : Colors.grey.shade600,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildLine(bool isDone) => Expanded(
    child: Container(
      height: 2, 
      color: isDone ? const Color(0xFFD81B60) : Colors.grey.shade300,
    ),
  );

  Widget _buildTextField(String label, TextEditingController controller, IconData icon, {String? hint}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87)),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: TextField(
            controller: controller,
            style: GoogleFonts.dmSans(fontSize: 15),
            decoration: InputDecoration(
              prefixIcon: Padding(
                padding: const EdgeInsets.only(left: 16.0, right: 12.0),
                child: Icon(icon, color: const Color(0xFFD81B60)),
              ),
              prefixIconConstraints: const BoxConstraints(minWidth: 40),
              hintText: hint,
              hintStyle: GoogleFonts.dmSans(color: Colors.black38, fontSize: 15),
              filled: true,
              fillColor: Colors.transparent,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPhotoUpload(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87)),
        const SizedBox(height: 10),
        CustomPaint(
          painter: DottedBorderPainter(color: const Color(0xFFD81B60).withOpacity(0.3)),
          child: Container(
            height: 160,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.add_a_photo_outlined, size: 38, color: Color(0xFFD81B60)),
                  const SizedBox(height: 12),
                  Text(subtitle, style: GoogleFonts.dmSans(color: Colors.black54, fontSize: 14)),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class DottedBorderPainter extends CustomPainter {
  final Color color;
  DottedBorderPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    
    const double dashWidth = 6;
    const double dashSpace = 4;
    final RRect rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      const Radius.circular(16),
    );
    
    final Path path = Path()..addRRect(rrect);
    final Path metricsPath = Path();
    
    for (final PathMetric metric in path.computeMetrics()) {
      double distance = 0.0;
      while (distance < metric.length) {
        metricsPath.addPath(
          metric.extractPath(distance, distance + dashWidth),
          Offset.zero,
        );
        distance += dashWidth + dashSpace;
      }
    }
    canvas.drawPath(metricsPath, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}