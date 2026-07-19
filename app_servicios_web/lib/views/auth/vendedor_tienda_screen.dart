import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'vendedor_revision_screen.dart';
import 'vendedor_identidad_screen.dart';

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
        backgroundColor: const Color(0xFFF8F5F2),
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Color(0xFFD81B60),
            size: 20,
          ),
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
            child: _buildProgress(2),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Column(
                children: [
                  Text(
                    'Configura tu espacio',
                    style: GoogleFonts.dmSans(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF0F2C59),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Define la identidad de tu tienda artesanal para que el mundo te conozca.',
                    style: GoogleFonts.dmSans(
                      fontSize: 15,
                      color: Colors.black54,
                      height: 1.3,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 110,
                    height: 110,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFFD81B60).withOpacity(0.2),
                        width: 1,
                      ),
                      image: const DecorationImage(
                        image: NetworkImage(
                          'https://images.unsplash.com/photo-1513519245088-0e12902e5a38?q=80&w=200',
                        ),
                        fit: BoxFit.cover,
                        opacity: 0.6,
                      ),
                    ),
                  ),
                  Container(
                    width: 50,
                    height: 50,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.storefront_outlined,
                      size: 28,
                      color: Color(0xFFD81B60),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            _buildTextField(
              'Nombre de la Tienda',
              _tiendaController,
              hint: 'Ej. Arte del Valle',
              icon: Icons.badge_outlined,
            ),
            const SizedBox(height: 24),
            _buildTextField(
              'RFC (Persona Moral)',
              _rfcController,
              hint: 'ABC123456XYZ',
              icon: Icons.assignment_ind_outlined,
              extraInfo:
                  'Requerido para la facturación de comisiones y envíos.',
            ),
            const SizedBox(height: 24),
            Text(
              'Descripción de tu arte',
              style: GoogleFonts.dmSans(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFFD81B60).withOpacity(0.15),
                ),
              ),
              child: TextField(
                controller: _descripcionController,
                maxLines: 4,
                style: GoogleFonts.dmSans(fontSize: 15),
                decoration: InputDecoration(
                  hintText:
                      'Cuéntanos la historia detrás de tus creaciones y los materiales que utilizas...',
                  hintStyle: GoogleFonts.dmSans(
                    color: Colors.black38,
                    fontSize: 14,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(16),
                ),
              ),
            ),
            const SizedBox(height: 20),
            _buildInfoBanner(),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const VendedorRevisionScreen(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD81B60),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Siguiente',
                      style: GoogleFonts.dmSans(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: Colors.white,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
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

  Widget _buildTextField(
    String label,
    TextEditingController controller, {
    required String hint,
    required IconData icon,
    String? extraInfo,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.dmSans(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: const Color(0xFFD81B60).withOpacity(0.15),
            ),
          ),
          child: TextField(
            controller: controller,
            style: GoogleFonts.dmSans(fontSize: 15),
            decoration: InputDecoration(
              prefixIcon: Padding(
                padding: const EdgeInsets.only(left: 16.0, right: 12.0),
                child: Icon(icon, color: Colors.black45),
              ),
              prefixIconConstraints: const BoxConstraints(minWidth: 40),
              hintText: hint,
              hintStyle: GoogleFonts.dmSans(
                color: Colors.black38,
                fontSize: 15,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                vertical: 16,
                horizontal: 20,
              ),
            ),
          ),
        ),
        if (extraInfo != null) ...[
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(left: 14.0),
            child: Text(
              extraInfo,
              style: GoogleFonts.dmSans(fontSize: 11, color: Colors.black45),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildInfoBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFD81B60).withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, color: Color(0xFFD81B60), size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Tu descripción ayuda a los coleccionistas a valorar la técnica tradicional de Oaxaca. Sé específico sobre tus procesos.',
              style: GoogleFonts.dmSans(
                fontSize: 13,
                color: const Color(0xFFD81B60),
                fontWeight: FontWeight.w500,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
