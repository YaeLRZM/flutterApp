import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'vendedor_revision_screen.dart';

class VendedorTiendaScreen extends StatefulWidget {
  const VendedorTiendaScreen({super.key});

  @override
  State<VendedorTiendaScreen> createState() => _VendedorTiendaScreenState();
}

class _VendedorTiendaScreenState extends State<VendedorTiendaScreen> {
  final TextEditingController _tiendaController = TextEditingController();
  final TextEditingController _rfcController = TextEditingController();
  final TextEditingController _descripcionController = TextEditingController();

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
            _buildProgress(2),
            const SizedBox(height: 30),

            Text('Configura tu espacio', style: GoogleFonts.cormorantGaramond(fontSize: 28, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text('Define la identidad de tu tienda artesanal para que el mundo te conozca.', style: GoogleFonts.dmSans(fontSize: 15.5, color: Colors.black54, height: 1.4)),

            const SizedBox(height: 32),

            Center(
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFD81B60), width: 3),
                  color: Colors.white,
                ),
                child: const Icon(Icons.storefront, size: 55, color: Color(0xFFD81B60)),
              ),
            ),

            const SizedBox(height: 32),

            _buildTextField('Nombre de la Tienda', _tiendaController, 'Ej. Arte del Valle'),
            const SizedBox(height: 20),
            _buildTextField('RFC (Persona Moral)', _rfcController, 'ABC123456XYZ'),
            const SizedBox(height: 20),

            Text('Descripción de tu arte', style: GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            TextField(
              controller: _descripcionController,
              maxLines: 6,
              decoration: InputDecoration(
                hintText: 'Cuéntanos la historia detrás de tus creaciones y los materiales que utilizas...',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
                contentPadding: const EdgeInsets.all(16),
              ),
            ),

            const SizedBox(height: 40),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFD81B60)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  ),
                  child: Text('Regresar', style: GoogleFonts.poppins(color: const Color(0xFFD81B60), fontWeight: FontWeight.w500)),
                ),
                const SizedBox(width: 20),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const VendedorRevisionScreen()));
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD81B60),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                  ),
                  child: const Text('Siguiente', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, String hint) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          ),
        ),
      ],
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