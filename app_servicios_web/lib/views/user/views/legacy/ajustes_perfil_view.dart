// LEGACY / FUERA DE FLUJO — no importar desde rutas activas.
// Conservado solo como referencia histórica. Usar MenuConfigView / DetallePedidoView.
// @deprecated
import 'package:flutter/material.dart';

class AjustesPerfilView extends StatelessWidget {
  const AjustesPerfilView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F5F2), // Blanco marfil
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- Cabecera del Perfil ---
              Center(
                child: Column(
                  children: [
                    Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 4),
                            color: Colors.grey.shade300,
                          ),
                          child: const Icon(
                            Icons.person,
                            size: 50,
                            color: Colors.white,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFD81B60),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: const Icon(
                            Icons.edit,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Mariana Gómez',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'mariana.gomez@ixemoda.com',
                      style: TextStyle(fontSize: 14, color: Colors.black54),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // --- Títulos de Sección ---
              const Text(
                'Ajustes de Perfil',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w400,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Información Personal',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.black45,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 24),

              // --- Formulario ---
              _buildCustomTextField(
                label: 'NOMBRE COMPLETO',
                initialValue: 'Mariana Gómez',
              ),
              const SizedBox(height: 20),

              _buildCustomTextField(
                label: 'CORREO ELECTRÓNICO',
                initialValue: 'mariana.gomez@ixemoda.com',
              ),
              const SizedBox(height: 20),

              _buildCustomTextField(
                label: 'TELÉFONO',
                initialValue: '+52 951 123 4567',
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 20),

              _buildCustomTextField(
                label: 'DIRECCIÓN DE ENVÍO',
                initialValue:
                    'Calle Macedonio Alcalá 123, Centro\nHistórico, Oaxaca de Juárez, Oax. CP\n68000',
                maxLines: 3,
              ),
              const SizedBox(height: 40),

              // --- Botón Guardar Cambios ---
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD81B60), // Rosa bugambilia
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'GUARDAR CAMBIOS',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  // Widget auxiliar para los campos de texto
  Widget _buildCustomTextField({
    required String label,
    required String initialValue,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: Colors.black54,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.015),
                blurRadius: 5,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextFormField(
            initialValue: initialValue,
            maxLines: maxLines,
            keyboardType: keyboardType,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black87,
              height: 1.4,
            ),
            decoration: InputDecoration(
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 16.0,
              ),
              isDense: true,
            ),
          ),
        ),
      ],
    );
  }
}
