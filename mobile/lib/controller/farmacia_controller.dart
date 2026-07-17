import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';
import 'package:weather/model/coordenada.dart';
import 'package:weather/model/farmacia.dart';
import 'package:weather/services/servicio_google.dart';
import 'package:weather/services/servicio_rest.dart';
import 'package:weather/services/servicio_ubicacion.dart';
import 'package:weather/services/servicio_distancia.dart';

class FarmaciaController extends ChangeNotifier {
  static final Logger _logger = Logger();

  final ServicioRest _servicioRest;
  final ServicioUbicacion _servicioUbicacion;
  final ServicioGoogle _servicioGoogle;
  final ServicioDistancia _servicioDistancia;

  Coordenada? _coordenadaActual;
  Farmacia? _farmacia;
  String? _mensajeError;
  bool _estaCargando = false;

  FarmaciaController({
    required this._servicioRest,
    required this._servicioUbicacion,
    required this._servicioGoogle,
    required this._servicioDistancia,
  });

  bool get estaCargando => _estaCargando;
  String? get mensajeError => _mensajeError;
  Farmacia? get farmacia => _farmacia;
  Coordenada? get coordenadaActual => _coordenadaActual;

  bool get tieneDatos => _farmacia != null;

  Future<void> inicializarDatos() async {
    _estaCargando = true;
    _mensajeError = null;
    notifyListeners();

    try {
      final token = await _obtenerToken();

      _coordenadaActual =
      await _servicioUbicacion.obtenerUbicacionActual();

      _farmacia = await _servicioRest.obtenerFarmaciaCercana(
        idToken: token,
        latitud: _coordenadaActual!.latitud,
        longitud: _coordenadaActual!.longitud,
      );

      final distancia =
      _servicioDistancia.calcularDistancia(
        latitudOrigen: _coordenadaActual!.latitud,
        longitudOrigen: _coordenadaActual!.longitud,
        latitudDestino: _farmacia!.latitud,
        longitudDestino: _farmacia!.longitud,
      );


      _farmacia!.distancia = distancia;

      _logger.i(
        'Farmacia encontrada: ${_farmacia!.nombre}',
      );
    } catch (e) {
      _mensajeError = e.toString().replaceFirst('Exception: ', '');
      _logger.e(
        'Error obteniendo farmacia',
        error: e,
      );
    } finally {
      _estaCargando = false;
      notifyListeners();
    }
  }

  Future<void> reintentar() async {
    await inicializarDatos();
  }

  void limpiarError() {
    _mensajeError = null;
    notifyListeners();
  }

  Future<String> _obtenerToken() async {
    final token = await _servicioGoogle.obtenerToken();

    if (token == null || token.isEmpty) {
      throw Exception('No se pudo obtener el token');
    }

    return token;
  }
}