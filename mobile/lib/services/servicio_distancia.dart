import 'dart:math';
import 'package:logger/logger.dart';

class ServicioDistancia {
  static final Logger _logger = Logger();

  double calcularDistancia({
    required double latitudOrigen,
    required double longitudOrigen,
    required double latitudDestino,
    required double longitudDestino,
  }) {

    const radioTierra = 6371;

    final diferenciaLat =
    _gradosARadianes(latitudDestino - latitudOrigen);

    final diferenciaLon =
    _gradosARadianes(longitudDestino - longitudOrigen);


    final a =
        sin(diferenciaLat / 2) *
            sin(diferenciaLat / 2) +
            cos(_gradosARadianes(latitudOrigen)) *
                cos(_gradosARadianes(latitudDestino)) *
                sin(diferenciaLon / 2) *
                sin(diferenciaLon / 2);


    final c = 2 * atan2(sqrt(a), sqrt(1 - a));

    final distancia = radioTierra * c;

    _logger.i(
        'ORIGEN: $latitudOrigen, $longitudOrigen'
    );

    return distancia;
  }


  double _gradosARadianes(double grados) {
    return grados * pi / 180;
  }
}