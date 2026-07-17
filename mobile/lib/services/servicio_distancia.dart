import 'dart:math';

class ServicioDistancia {

  double calcularDistancia({
    required double latitudOrigen,
    required double longitudOrigen,
    required double latitudDestino,
    required double longitudDestino,
  }) {

    const radioTierra = 6371; // kilómetros

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


    return radioTierra * c;
  }


  double _gradosARadianes(double grados) {
    return grados * pi / 180;
  }
}