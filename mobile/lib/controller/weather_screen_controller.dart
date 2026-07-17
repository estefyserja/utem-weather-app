import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';
import 'package:weather/model/coordenada.dart';
import 'package:weather/model/observacion_meteo.dart';
import 'package:weather/services/servicio_google.dart';
import 'package:weather/services/servicio_rest.dart';
import 'package:weather/services/servicio_ubicacion.dart';
import 'package:weather/model/farmacia.dart';
import 'package:weather/services/servicio_distancia.dart';
/// Controlador de la pantalla principal del clima.
///
/// Orquesta la obtención de ubicación, autenticación y consulta meteorológica.
/// Expone el estado de la UI mediante [ChangeNotifier] para que los widgets
/// reaccionen a cambios en carga, datos y errores.
///
/// ## Flujo de inicialización
/// 1. Obtiene un token de autenticación válido desde [ServicioGoogle].
/// 2. Solicita la ubicación actual del dispositivo mediante [ServicioUbicacion].
/// 3. Consulta la observación meteorológica cercana con [ServicioRest].
///
/// ## Estado expuesto
/// - [estaCargando]: Indica si está en proceso de carga.
/// - [mensajeError]: Contiene el último error ocurrido (null si no hay error).
/// - [observacionMeteo]: Datos meteorológicos obtenidos.
/// - [coordenadaActual]: Ubicación del dispositivo.
/// - [tieneDatos]: Indica si hay datos suficientes para mostrar la UI.
///
/// ## Manejo de errores
/// Todos los errores se capturan en [inicializarDatos] y se exponen a través
/// de [mensajeError]. El usuario puede reintentar con [reintentar] o limpiar
/// el error con [limpiarError]. La implementación usa excepciones genéricas
/// ([Exception]) en lugar de tipos personalizados, lo que simplifica el código
/// pero limita el manejo específico por tipo de error.
///
/// ## Ejemplo de uso en un widget
/// ```dart
/// class WeatherScreen extends StatefulWidget {
///   @override
///   _WeatherScreenState createState() => _WeatherScreenState();
/// }
///
/// class _WeatherScreenState extends State<WeatherScreen> {
///   late WeatherScreenController _controller;
///
///   @override
///   void initState() {
///     super.initState();
///     _controller = WeatherScreenController(
///       _servicioRest,
///       _servicioUbicacion,
///       _servicioGoogle,
///     )..addListener(() {
///         // Reconstruir cuando el estado cambie
///         setState(() {});
///       });
///     _controller.inicializarDatos();
///   }
///
///   @override
///   Widget build(BuildContext context) {
///     if (_controller.estaCargando) {
///       return const CircularProgressIndicator();
///     }
///     if (_controller.mensajeError != null) {
///       return Text('Error: ${_controller.mensajeError}');
///     }
///     if (_controller.tieneDatos) {
///       return WeatherDisplay(
///         observacion: _controller.observacionMeteo!,
///         ubicacion: _controller.coordenadaActual!,
///       );
///     }
///     return const Text('Sin datos');
///   }
///
///   @override
///   void dispose() {
///     _controller.dispose();
///     super.dispose();
///   }
/// }
/// ```
///
/// ## Notas
/// - El controlador debe ser [dispose]d para liberar recursos y cancelar
///   suscripciones.
/// - [notifyListeners] se invoca cada vez que cambia el estado, asegurando
///   que los widgets escuchadores se reconstruyan.
class WeatherScreenController extends ChangeNotifier {
  static final Logger _logger = Logger();

  final ServicioRest _servicioRest;
  final ServicioUbicacion _servicioUbicacion;
  final ServicioGoogle _servicioGoogle;
  final ServicioDistancia _servicioDistancia;

  Coordenada? _coordenadaActual;
  ObservacionMeteo? _observacionMeteo;
  String? _mensajeError;
  bool _estaCargando = false;
  Farmacia? _farmacia;

  WeatherScreenController({
    required this._servicioRest,
    required this._servicioUbicacion,
    required this._servicioGoogle,
    required this._servicioDistancia,
  });

  /// Indica si el controlador está realizando una operación de carga.
  ///
  /// Durante la carga, la UI debería mostrar un indicador de progreso
  /// y deshabilitar acciones que requieran datos.
  bool get estaCargando => _estaCargando;

  /// Mensaje de error actual, o `null` si no hay error.
  ///
  /// Este mensaje se muestra al usuario cuando ocurre un problema durante
  /// la inicialización o reintento.
  String? get mensajeError => _mensajeError;

  /// Datos meteorológicos obtenidos, o `null` si aún no se han cargado.
  ObservacionMeteo? get observacionMeteo => _observacionMeteo;

  /// Coordenadas de la ubicación actual del dispositivo, o `null` si no se
  /// han obtenido aún.
  Coordenada? get coordenadaActual => _coordenadaActual;

  /// Indica si hay datos suficientes para mostrar la pantalla principal.
  ///
  /// Retorna `true` si tanto la [observacionMeteo] como la [coordenadaActual]
  /// no son nulas. Esto garantiza que la UI pueda renderizar ambos elementos.
  bool get tieneDatos => _observacionMeteo != null && _coordenadaActual != null;

  // FARMACIA
  Farmacia? get farmacia => _farmacia;

  /// Inicializa los datos de la pantalla ejecutando el flujo completo.
  ///
  /// Establece [estaCargando] a `true`, obtiene token, ubicación y observación.
  /// En caso de error, captura la excepción, la registra y asigna su mensaje
  /// a [mensajeError]. Finalmente, restablece [estaCargando] a `false`
  /// y notifica a los listeners.
  ///
  /// Este método debe llamarse una vez al iniciar la pantalla. Para reintentos
  /// use [reintentar].
  Future<void> inicializarDatos() async {
    _estaCargando = true;
    _mensajeError = null;
    notifyListeners();

    try {
      final String idToken = await _obtenerTokenValido();
      _coordenadaActual = await _servicioUbicacion.obtenerUbicacionActual();
      final observacionFuture =
      _servicioRest.obtenerObservacionCercana(
        idToken: idToken,
        latitud: _coordenadaActual!.latitud,
        longitud: _coordenadaActual!.longitud,
      );

      final farmaciaFuture =
      _servicioRest.obtenerFarmaciaCercana(
        idToken: idToken,
        latitud: _coordenadaActual!.latitud,
        longitud: _coordenadaActual!.longitud,
      );

      final resultados = await Future.wait([
        observacionFuture,
        farmaciaFuture,
      ]);

      _observacionMeteo = resultados[0] as ObservacionMeteo;
      _farmacia = resultados[1] as Farmacia;

      _farmacia!.distancia =
          _servicioDistancia.calcularDistancia(
            latitudOrigen: _coordenadaActual!.latitud,
            longitudOrigen: _coordenadaActual!.longitud,
            latitudDestino: _farmacia!.latitud,
            longitudDestino: _farmacia!.longitud,
          );
      _logger.i(
        'Datos inicializados correctamente en '
        '${_coordenadaActual!.latitud}, ${_coordenadaActual!.longitud}',
      );
    } catch (error) {
      _manejarError(error);
    } finally {
      _estaCargando = false;
      notifyListeners();
    }
  }

  /// Reintenta la carga de datos desde cero.
  ///
  /// Útil cuando el usuario presiona un botón "Reintentar" tras un error.
  /// Este método invoca internamente [inicializarDatos], reiniciando todo
  /// el proceso.
  Future<void> reintentar() async {
    _logger.i('Reintentando carga de datos');
    await inicializarDatos();
  }

  /// Limpia el mensaje de error actual.
  ///
  /// Permite a la UI ocultar banners o diálogos de error sin necesidad de
  /// recargar los datos. Si no hay error, no hace nada.
  void limpiarError() {
    if (_mensajeError != null) {
      _mensajeError = null;
      notifyListeners();
    }
  }

  /// Obtiene y valida el token de autenticación.
  ///
  /// Llama a [_servicioGoogle.obtenerToken] y lanza una [Exception] si el
  /// token es nulo o vacío. Esto previene solicitudes al servicio REST que
  /// fallarían con un error 401.
  ///
  /// Retorna el token no vacío.
  ///
  /// Lanza [Exception] si no se obtiene un token válido.
  Future<String> _obtenerTokenValido() async {
    final String? token = await _servicioGoogle.obtenerToken();

    if (token == null || token.isEmpty) {
      _logger.w('Token de autenticación ausente o vacío');
      throw Exception('No se pudo obtener el token de autenticación');
    }

    return token;
  }

  /// Registra el error y establece el mensaje para la UI.
  ///
  /// Extrae el mensaje de la excepción de la siguiente manera:
  /// - Si [error] es una instancia de [Exception], intenta remover el prefijo
  ///   "Exception: " de su representación en cadena (obtenida con `toString()`)
  ///   para dejar solo el mensaje útil.
  /// - Si [error] no es una [Exception], usa `error.toString()` directamente.
  ///
  /// El mensaje resultante se asigna a [_mensajeError] y se registra con
  /// nivel `error` usando el logger.
  ///
  /// Esta implementación asume que las excepciones lanzadas por los servicios
  /// tienen un formato legible en su `toString()`. Si se usaran excepciones
  /// personalizadas, se podría mejorar extrayendo propiedades específicas.
  void _manejarError(Object error) {
    String mensajeExtraido;

    if (error is Exception) {
      final String errorString = error.toString();
      if (errorString.startsWith('Exception: ')) {
        mensajeExtraido = errorString.substring(11);
      } else {
        mensajeExtraido = errorString;
      }
    } else {
      mensajeExtraido = 'Error inesperado: ${error.toString()}';
    }

    _mensajeError = mensajeExtraido;
    _logger.e('Error durante inicialización', error: error);
  }

  @override
  void dispose() {
    _logger.i('Dispose del controlador de clima');
    super.dispose();
  }
}
