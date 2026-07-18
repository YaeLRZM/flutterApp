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
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Color(0xFFD81B60)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Ixé Moda', style: GoogleFonts.cormorantGaramond(fontSize: 22, fontWeight: FontWeight.w700, color: const Color(0xFFD81B60))),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Progress
            _buildProgress(1),
            const SizedBox(height: 30),

            Text('Validar Identidad', style: GoogleFonts.cormorantGaramond(fontSize: 28, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text(
              'Sube tus documentos oficiales para empezar a vender piezas únicas.',
              style: GoogleFonts.dmSans(fontSize: 15, color: Colors.black54),
            ),

            const SizedBox(height: 30),

            _buildTextField('Correo Electrónico', _emailController, Icons.email_outlined),
            const SizedBox(height: 20),

            _buildTextField('Código INE', _ineController, Icons.fingerprint, hint: 'Ingresa los 13 dígitos traseros'),

            const SizedBox(height: 30),

            // Foto Frontal
            _buildPhotoUpload('Foto Frontal INE', 'Toca para capturar el frente'),
            const SizedBox(height: 20),

            // Foto Trasera
            _buildPhotoUpload('Foto Trasera INE', 'Toca para capturar el reverso'),

            const SizedBox(height: 40),

            // Botón Continuar centrado
            Center(
              child: SizedBox(
                width: 220,
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
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  ),
                  child: const Text('Continuar', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
                ),
              ),
            ),
          ],
        ),
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