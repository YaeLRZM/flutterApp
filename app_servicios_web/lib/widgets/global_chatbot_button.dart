import 'package:flutter/material.dart';

import 'chatbot_sheet.dart';

class GlobalChatbotButton extends StatelessWidget {
  const GlobalChatbotButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 20, // Ajusta este valor para que no choque con tu bottom bar
      right: 16,
      child: FloatingActionButton(
        // Añadimos un heroTag único porque Flutter marca error si hay dos FABs sin etiqueta
        heroTag: 'chatbot_btn',
        onPressed: () => ChatbotSheet.open(context),
        backgroundColor: const Color(0xFFD81B60), // Tu rosa bugambilia
        elevation: 6,
        shape: const CircleBorder(),
        child: const Icon(
          Icons.auto_awesome, // El ícono de destellos
          color: Colors.white,
          size: 28,
        ),
      ),
    );
  }
}
