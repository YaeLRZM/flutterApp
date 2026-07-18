import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class VendedorRevisionScreen extends StatelessWidget {
  const VendedorRevisionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F5F2),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios, color: Color(0xFFD81B60)), onPressed: () => Navigator.pop(context)),
        title: Text('Ixé Moda', style: GoogleFonts.cormorantGaramond(fontSize: 22, fontWeight: FontWeight.w700, color: const Color(0xFFD81B60))),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProgress(3),
            const SizedBox(height: 30),

            Text('Revisión Final', style: GoogleFonts.cormorantGaramond(fontSize: 28, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text('Confirma que toda la información sea correcta antes de enviar tu solicitud.', style: GoogleFonts.dmSans(fontSize: 15.5, color: Colors.black54)),

            const SizedBox(height: 32),

            // Aquí puedes expandir con más tarjetas según necesites
            _buildReviewSection('Perfil de la Tienda', 'Nombre: Arte del Valle\nRFC: AVO920815XX1'),
            const SizedBox(height: 20),
            _buildReviewSection('Documentación', 'Identificación Oficial ✓\nComprobante de Domicilio ✓\nConstancia Fiscal ✓'),

            const SizedBox(height: 30),

            CheckboxListTile(
              value: true,
              onChanged: (val) {},
              title: const Text('Acepto los Términos y Condiciones'),
              activeColor: const Color(0xFFD81B60),
              controlAffinity: ListTileControlAffinity.leading,
            ),

            const SizedBox(height: 40),

            Center(
              child: SizedBox(
                width: 260,
                height: 58,
                child: ElevatedButton(
                  onPressed: () {
                    // Lógica de envío
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD81B60),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  ),
                  child: const Text('Enviar Solicitud', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
                ),
              ),
            ),

            const SizedBox(height: 20),
            const Center(
              child: Text(
                'Tu solicitud será revisada por nuestro equipo en un plazo de 48 a 72 horas hábiles.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Colors.black54),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewSection(String title, String content) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: GoogleFonts.dmSans(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 10),
          Text(content, style: GoogleFonts.dmSans(height: 1.5)),
        ],
      ),
    );
  }

  Widget _buildProgress(int current) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildStep(1, current),
        _buildLine(),
        _buildStep(2, current),
        _buildLine(),
        _buildStep(3, current),
      ],
    );
  }

  Widget _buildStep(int number, int current) {
    bool isActive = number == current;
    return CircleAvatar(
      radius: 14,
      backgroundColor: isActive ? const Color(0xFFD81B60) : Colors.grey.shade300,
      child: Text('$number', style: TextStyle(color: isActive ? Colors.white : Colors.grey.shade600, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildLine() => Expanded(child: Container(height: 2, color: Colors.grey.shade300));

  Widget _buildTextField(String label, TextEditingController controller, IconData icon, {String? hint}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: Colors.black54),
            hintText: hint,
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
          ),
        ),
      ],
    );
  }

  Widget _buildPhotoUpload(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        Container(
          height: 160,
          decoration: BoxDecoration(
            color: const Color(0xFFFFE4E9),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFD81B60).withOpacity(0.3), style: BorderStyle.solid, width: 1.5),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.camera_alt, size: 40, color: const Color(0xFFD81B60)),
                const SizedBox(height: 8),
                Text(subtitle, style: GoogleFonts.dmSans(color: Colors.black54)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}