import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class VendedorRevisionScreen extends StatelessWidget {
  const VendedorRevisionScreen({super.key});

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
            child: _buildProgress(3),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Text(
                'Revisión Final',
                style: GoogleFonts.dmSans(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFFD81B60),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                'Confirma que toda la información sea correcta antes de enviar tu solicitud.',
                style: GoogleFonts.dmSans(fontSize: 15, color: Colors.black54),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 32),

            // CARD 1: Perfil de la tienda
            _buildStoreProfileCard(),
            const SizedBox(height: 18),

            // CARD 2: Documentación
            _buildDocumentationCard(),
            const SizedBox(height: 18),

            // CARD 3: Contacto
            _buildContactCard(),
            const SizedBox(height: 24),

            // Checkbox de Términos
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.black.withOpacity(0.05)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: Checkbox(
                      value: false,
                      onChanged: (val) {},
                      activeColor: const Color(0xFFD81B60),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Acepto los Términos y Condiciones',
                          style: GoogleFonts.dmSans(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Confirmo que soy el representante legal y la información proporcionada es verídica.',
                          style: GoogleFonts.dmSans(
                            fontSize: 12,
                            color: Colors.black45,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 36),

            // Botón de Enviar Deshabilitado/Estilizado
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(
                    0xFFE2E8F0,
                  ), // Color azulado grisáceo claro de la img
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Enviar Solicitud',
                      style: GoogleFonts.dmSans(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black38,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.send_outlined,
                      size: 16,
                      color: Colors.black38,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),
            Center(
              child: Text(
                'Tu solicitud será revisada por nuestro equipo en un plazo de 48 a 72 horas hábiles.',
                textAlign: TextAlign.center,
                style: GoogleFonts.dmSans(
                  fontSize: 12,
                  color: Colors.black45,
                  height: 1.4,
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildStoreProfileCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Stack(
        children: [
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            child: Container(
              width: 4,
              decoration: const BoxDecoration(
                color: Color(0xFFD81B60),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'PERFIL DE LA TIENDA',
                      style: GoogleFonts.dmSans(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: const Color(0xFFD81B60),
                        letterSpacing: 0.5,
                      ),
                    ),
                    const Icon(
                      Icons.edit_outlined,
                      size: 18,
                      color: Colors.black45,
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  'Nombre de la Tienda',
                  style: GoogleFonts.dmSans(
                    fontSize: 11,
                    color: Colors.black45,
                  ),
                ),
                Text(
                  'Artesanías del Valle Oaxaqueño',
                  style: GoogleFonts.dmSans(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'RFC / Identificación Fiscal',
                  style: GoogleFonts.dmSans(
                    fontSize: 11,
                    color: Colors.black45,
                  ),
                ),
                Text(
                  'AVO920815-XX1',
                  style: GoogleFonts.dmSans(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.edit_outlined,
                        size: 12,
                        color: Colors.black54,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Textiles & Bordados',
                        style: GoogleFonts.dmSans(
                          fontSize: 12,
                          color: Colors.black54,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentationCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'DOCUMENTACIÓN',
                style: GoogleFonts.dmSans(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: const Color(0xFFD81B60),
                  letterSpacing: 0.5,
                ),
              ),
              const Icon(Icons.edit_outlined, size: 18, color: Colors.black45),
            ],
          ),
          const SizedBox(height: 16),
          _buildDocRow(Icons.badge_outlined, 'Identificación Oficial'),
          const SizedBox(height: 16),
          _buildDocRow(Icons.receipt_long_outlined, 'Comprobante de Domicilio'),
          const SizedBox(height: 16),
          _buildDocRow(Icons.description_outlined, 'Constancia Fiscal'),
        ],
      ),
    );
  }

  Widget _buildDocRow(IconData icon, String label) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFE6F7F5),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: const Color(0xFF2DD4BF), size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.dmSans(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
        ),
        Row(
          children: [
            const Icon(
              Icons.check_circle_outline,
              color: Color(0xFF2DD4BF),
              size: 16,
            ),
            const SizedBox(width: 4),
            Text(
              'CARGADO',
              style: GoogleFonts.dmSans(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF2DD4BF),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildContactCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'CONTACTO',
                style: GoogleFonts.dmSans(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: const Color(0xFFD81B60),
                  letterSpacing: 0.5,
                ),
              ),
              const Icon(Icons.edit_outlined, size: 18, color: Colors.black45),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFFD81B60),
                    width: 1.5,
                  ),
                  image: const DecorationImage(
                    image: NetworkImage(
                      'https://images.unsplash.com/photo-1544005313-94ddf0286df2?q=80&w=150',
                    ),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Elena Jiménez',
                    style: GoogleFonts.dmSans(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'elena.j@ixemoda.mx',
                    style: GoogleFonts.dmSans(
                      fontSize: 12,
                      color: Colors.black45,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
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
}
