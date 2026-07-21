import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api_service.dart';

class FormaPagoItem {
  final int id;
  final String nombre;

  const FormaPagoItem({required this.id, required this.nombre});

  factory FormaPagoItem.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    return FormaPagoItem(
      id: id is int ? id : int.tryParse(id?.toString() ?? '') ?? 0,
      nombre: (json['nombre'] ?? 'Sin nombre').toString(),
    );
  }
}

class FormaPagoService {
  Future<List<FormaPagoItem>> fetchFormasPago() async {
    final response = await http
        .get(
          Uri.parse('${ApiService.baseUrl}/formas-pago'),
          headers: const {'Accept': 'application/json'},
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      throw Exception(
        'No se pudieron cargar las formas de pago (${response.statusCode})',
      );
    }

    final decoded = jsonDecode(response.body);
    final list = <FormaPagoItem>[];
    final raw = decoded is List
        ? decoded
        : (decoded is Map && decoded['data'] is List)
            ? decoded['data'] as List
            : const [];
    for (final e in raw) {
      if (e is Map) {
        list.add(FormaPagoItem.fromJson(Map<String, dynamic>.from(e)));
      }
    }
    return list;
  }
}
