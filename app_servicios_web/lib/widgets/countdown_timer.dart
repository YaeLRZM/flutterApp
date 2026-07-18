import 'dart:async';
import 'package:flutter/material.dart';

/// Contador regresivo tipo "04 : 44 : 51".
///
/// TODO: API -> `duration` debería calcularse como
/// `promocion.fechaFin.difference(DateTime.now())` en vez de recibir un
/// valor fijo. La lógica de conteo (Timer) ya está lista, solo cambiaría
/// el valor inicial.
class CountdownTimer extends StatefulWidget {
  final Duration duration;

  const CountdownTimer({super.key, required this.duration});

  @override
  State<CountdownTimer> createState() => _CountdownTimerState();
}

class _CountdownTimerState extends State<CountdownTimer> {
  late Duration _remaining;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _remaining = widget.duration;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        if (_remaining.inSeconds <= 0) {
          _timer?.cancel();
        } else {
          _remaining = _remaining - const Duration(seconds: 1);
        }
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _two(int n) => n.toString().padLeft(2, '0');

  @override
  Widget build(BuildContext context) {
    final h = _two(_remaining.inHours);
    final m = _two(_remaining.inMinutes.remainder(60));
    final s = _two(_remaining.inSeconds.remainder(60));

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [_box(h), _sep(), _box(m), _sep(), _box(s)],
    );
  }

  Widget _box(String value) => Container(
    width: 26,
    height: 26,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: Colors.black87,
      borderRadius: BorderRadius.circular(4),
    ),
    child: Text(
      value,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 12,
        fontWeight: FontWeight.bold,
      ),
    ),
  );

  Widget _sep() => const Padding(
    padding: EdgeInsets.symmetric(horizontal: 3),
    child: Text(":", style: TextStyle(fontWeight: FontWeight.bold)),
  );
}
