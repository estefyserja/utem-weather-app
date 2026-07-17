import 'package:dio/dio.dart';
import 'package:logger/logger.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import 'package:weather/model/observacion_meteo.dart';
import 'package:weather/model/farmacia.dart';

/// Servicio REST para consumir la API de observaciones meteorológicas.
///
/// Esta clase maneja todas las comunicaciones HTTP con el servidor backend,
/// incluyendo la autenticación mediante token, configuración de timeouts,
/// logging de peticiones/respuestas y mapeo de errores a mensajes amigables
/// para el usuario.
///
/// ## Características principales
/// - **Autenticación**: Incluye el token de autenticación en el header
///   `Authorization: Bearer <idToken>` para cada petición.
/// - **Timeouts**: Configuración de 17 segundos para conexión y 23 segundos
///   para recepción de datos, evitando bloqueos prolongados.
/// - **Logging**: Interceptor [PrettyDioLogger] para depuración en desarrollo,
///   mostrando cabeceras, cuerpos y respuestas de forma legible.
/// - **Mapeo de errores**: Traduce excepciones de `Dio` a mensajes de error
///   comprensibles para el usuario final.
/// - **Validación de parámetros**: Verifica que latitud y longitud estén
///   dentro de rangos válidos antes de realizar la petición.
///
/// ## Flujo de uso típico
/// 1. Se instancia la clase (el constructor configura el cliente HTTP).
/// 2. Se obtiene un `idToken` válido desde [ServicioGoogle].
/// 3. Se llama a [obtenerObservacionCercana] con las coordenadas del usuario.
/// 4. La respuesta se parsea automáticamente a un objeto [ObservacionMeteo].
/// 5. En caso de error, se lanza una [Exception] con un mensaje descriptivo.
/// 6. Al finalizar, se puede llamar a [cerrar] para liberar recursos.
///
/// ## Dependencias
/// - [dio]: Cliente HTTP robusto con soporte para interceptores.
/// - [pretty_dio_logger]: Para logging detallado en desarrollo.
/// - [logger]: Para registro de eventos y errores.
/// - [ObservacionMeteo]: Modelo de datos que se parsea desde la respuesta JSON.
///
/// ## Ejemplo de uso
/// ```dart
/// final servicio = ServicioRest();
/// final token = await servicioGoogle.obtenerToken();
/// final observacion = await servicio.obtenerObservacionCercana(
///   idToken: token!,
///   latitud: -33.4489,
///   longitud: -70.6693,
/// );
/// print('Temperatura: ${observacion.temperatura} °C');
/// servicio.cerrar();
/// ```
///
/// ## Manejo de errores
/// La clase distingue entre varios tipos de errores:
/// - **Timeouts**: Conexión o recepción exceden los límites configurados.
/// - **HTTP 4xx/5xx**: Errores del servidor con códigos específicos.
/// - **Sin respuesta**: El servidor no responde o la conexión falla.
/// - **Parseo**: La respuesta JSON no tiene el formato esperado.
/// - **Validación**: Coordenadas fuera de rango (latitud -90 a 90, longitud -180 a 180).
///
/// Todos estos errores se encapsulan en una [Exception] con un mensaje
/// orientado al usuario.
///
/// ## Notas de implementación
/// - El cliente HTTP se configura en el constructor y se mantiene como
///   `late final` para asegurar su inicialización.
/// - El interceptor `PrettyDioLogger` se añade para facilitar la depuración
///   durante el desarrollo; en producción podría desactivarse condicionalmente.
/// - El header `Authorization` se establece dinámicamente en cada petición
///   mediante `_clienteHttp.options.headers['Authorization']`.
/// - La validación de coordenadas previene peticiones innecesarias y
///   posibles errores del servidor.
///
/// ## Mejoras potenciales
/// - Implementar un mecanismo de reintentos automáticos en caso de fallos
///   transitorios (red, servidor).
/// - Añadir caché de respuestas para reducir peticiones repetidas.
/// - Soportar autenticación mediante refresh token para renovar sesiones.
/// - Desactivar el logger en entornos de producción para mejorar rendimiento.
class ServicioRest {
  static final String _baseUrl = 'https://api.sebastian.cl/cmutem';
  static final Logger _logger = Logger();
  late final Dio _clienteHttp;

  /// Crea una instancia del servicio REST con la configuración por defecto.
  ///
  /// El constructor configura:
  /// - **Base URL**: `https://api.sebastian.cl/cmutem`
  /// - **Timeouts**: 17 segundos para conexión, 23 segundos para recepción.
  /// - **Headers**: `Accept: application/json` y `Content-Type: application/json`.
  /// - **Interceptor**: [PrettyDioLogger] para logging detallado.
  ///
  /// ## Ejemplo:
  /// ```dart
  /// final servicio = ServicioRest();
  /// ```
  ServicioRest() {
    final BaseOptions opciones = BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: const Duration(seconds: 17),
      receiveTimeout: const Duration(seconds: 23),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
    );

    _clienteHttp = Dio(opciones);
    _clienteHttp.interceptors.add(
      PrettyDioLogger(
        requestHeader: true,
        requestBody: true,
        responseBody: true,
        responseHeader: false,
        error: true,
        compact: true,
        maxWidth: 90,
      ),
    );
  }

  /// Mapea excepciones de Dio a mensajes de usuario.
  ///
  /// Este método interno traduce los diferentes tipos de errores que puede
  /// lanzar Dio a mensajes comprensibles para el usuario final.
  ///
  /// ## Orden de verificación (crítico)
  /// 1. **Timeouts**: Se verifican primero porque no tienen respuesta asociada.
  /// 2. **Cancelación**: Cuando el usuario cancela la petición.
  /// 3. **Sin respuesta**: El servidor no responde o hay problemas de red.
  /// 4. **Códigos HTTP**: Se mapean según el código de estado:
  ///    - 400: Datos incorrectos.
  ///    - 401: Credenciales inválidas o expiradas.
  ///    - 403: Permisos insuficientes.
  ///    - 404: No hay observaciones cercanas.
  ///    - 5xx: Error interno del servidor.
  ///    - Otros: Error inesperado con código genérico.
  ///
  /// Retorna una [Exception] con el mensaje de error traducido.
  ///
  /// ## Registro de errores
  /// Todos los errores se registran con [Logger] para facilitar la depuración,
  /// usando diferentes niveles según la gravedad (error, warn).
  Exception _mapearExcepcion(DioException error) {
    // Primero verificar timeouts (no tienen response)
    if (error.type == DioExceptionType.connectionTimeout) {
      _logger.e('Timeout de conexión: ${error.message}');
      return Exception('No se pudo conectar con el servidor');
    }

    if (error.type == DioExceptionType.receiveTimeout) {
      _logger.e('Timeout de respuesta: ${error.message}');
      return Exception('El servidor tardó demasiado en responder');
    }

    if (error.type == DioExceptionType.cancel) {
      _logger.w('Petición cancelada');
      return Exception('La petición fue cancelada');
    }

    // Sin respuesta del servidor
    if (error.response == null) {
      _logger.e('Sin respuesta: ${error.message}');
      return Exception('No hay conexión con el servidor');
    }

    // Con respuesta - verificar códigos HTTP
    final int codigoEstado = error.response!.statusCode ?? 0;
    _logger.e('Error HTTP $codigoEstado: ${error.response?.data}');

    switch (codigoEstado) {
      case 400:
        return Exception('Los datos ingresados son incorrectos');
      case 401:
        return Exception('Las credenciales son incorrectas o han expirado');
      case 403:
        return Exception('No tiene permisos para acceder a este recurso');
      case 404:
        return Exception('No se encontraron datos para la ubicación indicada');
      case 500:
      case 502:
      case 503:
        return Exception('Error interno del servidor. Intente más tarde');
      default:
        return Exception('Error inesperado (código $codigoEstado)');
    }
  }

  /// Obtiene la observación meteorológica más cercana a las coordenadas dadas.
  ///
  /// Realiza una petición GET al endpoint `/v1/clima/{latitud}/{longitud}`
  /// y retorna los datos climáticos parseados como [ObservacionMeteo].
  ///
  /// ## Parámetros
  /// - [idToken]: Token de autenticación del usuario (obtenido de [ServicioGoogle]).
  ///   Se incluye en el header como `Authorization: Bearer <idToken>`.
  /// - [latitud]: Coordenada de latitud en grados decimales. Debe estar entre
  ///   -90.0 (Polo Sur) y 90.0 (Polo Norte).
  /// - [longitud]: Coordenada de longitud en grados decimales. Debe estar entre
  ///   -180.0 (Oeste) y 180.0 (Este).
  ///
  /// ## Retorna
  /// Un objeto [ObservacionMeteo] con todos los datos climáticos disponibles.
  ///
  /// ## Lanza
  /// - [Exception] si:
  ///   - La latitud o longitud están fuera de rango.
  ///   - La petición HTTP falla (timeout, error de red, etc.).
  ///   - El servidor responde con un código de error (4xx, 5xx).
  ///   - La respuesta está vacía o tiene un formato inesperado.
  ///   - El parseo del JSON a [ObservacionMeteo] falla.
  ///
  /// ## Ejemplo:
  /// ```dart
  /// final servicio = ServicioRest();
  /// try {
  ///   final observacion = await servicio.obtenerObservacionCercana(
  ///     idToken: 'eyJhbGciOiJSUzI1NiIs...',
  ///     latitud: -33.4489,
  ///     longitud: -70.6693,
  ///   );
  ///   print('Temperatura en Santiago: ${observacion.temperatura} °C');
  /// } on Exception catch (e) {
  ///   print('Error: $e');
  /// }
  /// ```
  ///
  /// ## Notas
  /// - Los timeouts están configurados en 17s para conexión y 23s para recepción.
  /// - El endpoint espera una respuesta JSON que coincida con la estructura
  ///   del [ObservacionMeteo.fromJson] factory.
  /// - Las coordenadas se validan antes de realizar la petición para evitar
  ///   errores innecesarios.
  Future<ObservacionMeteo> obtenerObservacionCercana({
    required String idToken,
    required double latitud,
    required double longitud,
  }) async {
    // Validación de parámetros
    if (latitud < -90 || latitud > 90) {
      throw Exception('Latitud inválida: debe estar entre -90 y 90');
    }
    if (longitud < -180 || longitud > 180) {
      throw Exception('Longitud inválida: debe estar entre -180 y 180');
    }

    final String ruta = '/v1/clima/$latitud/$longitud';

    try {
      // Configurar header de autenticación
      _clienteHttp.options.headers['Authorization'] = 'Bearer $idToken';

      _logger.i('Consultando observación en: $ruta');
      final Response<dynamic> respuesta = await _clienteHttp.get<dynamic>(ruta);

      // Validar estructura de respuesta
      if (respuesta.data == null) {
        throw Exception('La respuesta del servidor está vacía');
      }

      if (respuesta.data is! Map<String, dynamic>) {
        _logger.e(
          'Tipo de respuesta inesperado: ${respuesta.data.runtimeType}',
        );
        throw Exception('Formato de respuesta inesperado');
      }

      final Map<String, dynamic> json = respuesta.data as Map<String, dynamic>;

      try {
        return ObservacionMeteo.fromJson(json);
      } catch (e) {
        _logger.e('Error al parsear respuesta: $e');
        throw Exception('Error al procesar los datos de la observación');
      }
    } on DioException catch (e) {
      throw _mapearExcepcion(e);
    } catch (e) {
      _logger.e('Error inesperado: $e');
      rethrow;
    }
  }

  /// Obtiene la farmacia más cercana a las coordenadas dadas.
  ///
  /// Realiza una petición GET al endpoint
  /// `/v1/farmacias/{latitud}/{longitud}`.
  ///
  /// Retorna un objeto [Farmacia].
  Future<Farmacia> obtenerFarmaciaCercana({
    required String idToken,
    required double latitud,
    required double longitud,
  }) async {
    if (latitud < -90 || latitud > 90) {
      throw Exception('Latitud inválida: debe estar entre -90 y 90');
    }

    if (longitud < -180 || longitud > 180) {
      throw Exception('Longitud inválida: debe estar entre -180 y 180');
    }

    final String ruta = '/v1/farmacias/$latitud/$longitud';

    try {
      _clienteHttp.options.headers['Authorization'] = 'Bearer $idToken';

      _logger.i('Consultando farmacia en: $ruta');

      final Response<dynamic> respuesta =
      await _clienteHttp.get<dynamic>(ruta);

      if (respuesta.data == null) {
        throw Exception('La respuesta del servidor está vacía');
      }

      if (respuesta.data is! Map<String, dynamic>) {
        _logger.e(
          'Tipo de respuesta inesperado: ${respuesta.data.runtimeType}',
        );
        throw Exception('Formato de respuesta inesperado');
      }

      final Map<String, dynamic> json =
      respuesta.data as Map<String, dynamic>;

      try {
        return Farmacia.fromJson(json);
      } catch (e) {
        _logger.e('Error al parsear respuesta: $e');
        throw Exception('Error al procesar los datos de la farmacia');
      }
    } on DioException catch (e) {
      throw _mapearExcepcion(e);
    } catch (e) {
      _logger.e('Error inesperado: $e');
      rethrow;
    }
  }

  /// Cierra el cliente HTTP y libera recursos.
  ///
  /// Este método debe llamarse cuando el servicio ya no sea necesario,
  /// especialmente en aplicaciones con ciclos de vida largos o pruebas.
  /// Cierra todas las conexiones abiertas y libera la memoria asociada.
  ///
  /// ## Ejemplo:
  /// ```dart
  /// final servicio = ServicioRest();
  /// // ... usar el servicio ...
  /// servicio.cerrar(); // Liberar recursos
  /// ```
  ///
  /// ## Nota
  /// Después de cerrar el cliente, no se pueden realizar más peticiones
  /// con esta instancia. Si se necesita continuar usando el servicio,
  /// se debe crear una nueva instancia.
  void cerrar() {
    _clienteHttp.close(force: true);
    _logger.i('Cliente HTTP cerrado');
  }
}
