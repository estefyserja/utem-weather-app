import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:provider/provider.dart';
import 'package:weather/controller/weather_screen_controller.dart';
import 'package:weather/screen/error_screen.dart';
import 'package:weather/screen/weather_screen.dart';
import 'package:weather/services/servicio_google.dart';
import 'package:weather/services/servicio_rest.dart';
import 'package:weather/services/servicio_ubicacion.dart';
import 'package:weather/consts/app_colors.dart';
import 'package:weather/services/servicio_distancia.dart';

/// Pantalla de inicio de sesión con autenticación vía Google.
///
/// Esta pantalla es el punto de entrada de la aplicación. Presenta una interfaz
/// atractiva con animaciones de entrada (desvanecimiento) y un logo con flotación
/// continua, mientras el usuario inicia sesión con su cuenta de Google.
///
/// ## Flujo de autenticación
/// 1. El usuario presiona el botón "Continuar con Google".
/// 2. Se muestra un indicador de carga y se invoca [ServicioGoogle.iniciarSesion].
/// 3. Según el resultado:
///    - **Éxito**: Se navega a [WeatherScreen] con todos los servicios inyectados
///      mediante [Provider] y [ChangeNotifierProvider].
///    - **Cancelación**: El usuario cierra el diálogo de Google; se oculta la carga.
///    - **Error**: Se captura la excepción y se navega a [ErrorScreen] con el mensaje.
///
/// ## Animaciones
/// - **Flotación**: El logo (nube con sol) se mueve verticalmente de forma continua
///   (sube y baja) en un ciclo de 3 segundos.
/// - **Desvanecimiento**: Todos los elementos (logo, títulos, botón y pie) aparecen
///   gradualmente durante 800 ms al cargar la pantalla.
///
/// ## Manejo de estado
/// - `_estaCargando`: Controla la visibilidad del indicador de progreso en el botón
///   y deshabilita el botón durante la autenticación.
/// - El estado se actualiza de forma segura verificando `mounted` antes de `setState`.
///
/// ## Ejemplo de uso
/// ```dart
/// // Desde cualquier parte de la app (ej: splash screen)
/// Navigator.pushReplacement(
///   context,
///   MaterialPageRoute(builder: (context) => const LoginScreen()),
/// );
/// ```
///
/// ## Notas de diseño
/// - El fondo utiliza un degradado lineal naranja (identidad UTEM) con una
///   superposición radial blanca para dar profundidad.
/// - Los colores están centralizados en [AppColors].
/// - Se usa [SingleChildScrollView] con `NeverScrollableScrollPhysics` para
///   evitar desplazamiento innecesario.
/// - El botón de Google tiene un diseño elevado con sombra y esquinas redondeadas.
///
/// ## Mejoras futuras
/// - Implementar un mecanismo de reintento en caso de error de red.
/// - Agregar un splash screen previo para precargar recursos.
/// - Soportar otros métodos de autenticación (email/contraseña).
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  // Logger configurado con formato legible para desarrollo.
  // PrettyPrinter incluye método, línea y tiempo de ejecución.
  static final Logger _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 2,
      errorMethodCount: 8,
      lineLength: 80,
      colors: true,
      printEmojis: true,
      dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
    ),
  );

  static const String _nombreClase = 'PantallaLogin';
  final ServicioGoogle _servicioGoogle = ServicioGoogle();

  late final AnimationController _controladorFlotacion;
  late final AnimationController _controladorDesvanecimiento;
  late final Animation<Offset> _animacionFlotacion;
  late final Animation<double> _animacionDesvanecimiento;

  bool _estaCargando = false;

  @override
  void initState() {
    super.initState();
    _logger.i('[$_nombreClase] Inicializando pantalla de login');
    _inicializarAnimaciones();
  }

  /// Configura las animaciones de flotación y desvanecimiento.
  ///
  /// - **Flotación**: Movimiento vertical continuo del logo (ida y vuelta)
  ///   mediante un [AnimationController] que se repite infinitamente.
  /// - **Desvanecimiento**: Entrada gradual de todos los elementos al cargar
  ///   la pantalla mediante un [AnimationController] que se ejecuta una sola vez.
  ///
  /// Ambas animaciones usan curvas [Curves.easeInOut] y [Curves.easeOut] para
  /// un movimiento suave y natural.
  void _inicializarAnimaciones() {
    // Controlador de flotación: 3 segundos por ciclo, se repite infinitamente.
    _controladorFlotacion = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);

    _animacionFlotacion =
        Tween<Offset>(begin: Offset.zero, end: const Offset(0, -0.015)).animate(
          CurvedAnimation(
            parent: _controladorFlotacion,
            curve: Curves.easeInOut,
          ),
        );

    // Controlador de desvanecimiento: 800ms, se ejecuta una sola vez al inicio.
    _controladorDesvanecimiento = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _animacionDesvanecimiento = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controladorDesvanecimiento,
        curve: Curves.easeOut,
      ),
    );

    _controladorDesvanecimiento.forward();
    _logger.d('[$_nombreClase] Animaciones inicializadas correctamente');
  }

  @override
  void dispose() {
    _logger.d('[$_nombreClase] Liberando recursos de animación');
    _controladorFlotacion.dispose();
    _controladorDesvanecimiento.dispose();
    super.dispose();
  }

  /// Maneja el flujo completo de autenticación con Google.
  ///
  /// Este método es invocado al presionar el botón de login. Gestiona el estado
  /// de carga y diferencia tres escenarios:
  ///
  /// 1. **Éxito (`ok == true`)**: Navega a [WeatherScreen] inyectando todos los
  ///    servicios necesarios mediante [Provider] y [ChangeNotifierProvider].
  ///    La navegación usa `pushReplacement` para eliminar la pantalla de login
  ///    de la pila.
  /// 2. **Cancelación (`ok == false`)**: El usuario cerró el diálogo de selección
  ///    de cuenta de Google. Se oculta el indicador de carga sin navegar.
  /// 3. **Error (excepción)**: Captura cualquier error, lo registra y navega a
  ///    [ErrorScreen] mostrando el mensaje de la excepción.
  ///
  /// Se verifica `mounted` antes de cualquier operación de navegación o cambio
  /// de estado para evitar errores en widgets desmontados.
  Future<void> _manejarLoginGoogle() async {
    _logger.i('[$_nombreClase] Iniciando proceso de autenticación con Google');
    _establecerEstadoCarga(true);

    try {
      final bool ok = await _servicioGoogle.iniciarSesion();

      if (!mounted) {
        return;
      }

      if (ok) {
        _logger.i('[$_nombreClase] Autenticación exitosa');
        Navigator.of(context).pushReplacement(
          MaterialPageRoute<WeatherScreen>(
            builder: (BuildContext context) => Provider<ServicioRest>(
              create: (_) => ServicioRest(),
              child: Provider<ServicioUbicacion>(
                create: (_) => ServicioUbicacion(),
                child: Provider<ServicioGoogle>(
                  create: (_) => _servicioGoogle,
                  child: ChangeNotifierProvider<WeatherScreenController>(
                    create: (BuildContext context) => WeatherScreenController(
                      servicioRest: context.read<ServicioRest>(),
                      servicioUbicacion: context.read<ServicioUbicacion>(),
                      servicioGoogle: _servicioGoogle,
                      servicioDistancia: ServicioDistancia(),
                    ),
                    child: const WeatherScreen(),
                  ),
                ),
              ),
            ),
          ),
        );
      } else {
        _logger.w('[$_nombreClase] Autenticación fallida o cancelada');
        _establecerEstadoCarga(false);
      }
    } catch (error, stackTrace) {
      _logger.e(
        '[$_nombreClase] Error durante autenticación con Google',
        error: error,
        stackTrace: stackTrace,
      );
      if (mounted) {
        _establecerEstadoCarga(false);
        Navigator.of(context).pushReplacement(
          MaterialPageRoute<ErrorScreen>(
            builder: (BuildContext context) =>
                ErrorScreen(mensajeError: 'Error: ${error.toString()}'),
          ),
        );
      }
    }
  }

  /// Actualiza el estado de carga de forma segura.
  ///
  /// Verifica que el widget esté montado antes de llamar a `setState`,
  /// evitando errores cuando la navegación ocurre durante una operación
  /// asíncrona y el widget ya se ha desmontado.
  ///
  /// Parámetro [cargando]: `true` para mostrar el indicador de carga y
  /// deshabilitar el botón, `false` para volver al estado normal.
  void _establecerEstadoCarga(bool cargando) {
    if (!mounted) {
      return;
    }
    setState(() {
      _estaCargando = cargando;
    });
    _logger.d('[$_nombreClase] Estado de carga actualizado: $cargando');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: _construirGradienteFondo(),
        child: Stack(
          children: <Widget>[
            _construirSobreposicionGradienteRadial(),
            SafeArea(
              child: Column(
                children: <Widget>[
                  Expanded(child: _construirContenidoPrincipal()),
                  _construirPie(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Gradiente lineal de fondo con tonos naranjos (identidad visual UTEM).
  ///
  /// Utiliza los colores primarios definidos en [AppColors] y un degradado
  /// que va desde claro a oscuro, dando sensación de profundidad.
  BoxDecoration _construirGradienteFondo() {
    return const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment(0.42, -0.91),
        end: Alignment(-0.42, 0.91),
        colors: <Color>[
          AppColors.naranjaPrimarioClaro,
          AppColors.naranjaPrimario,
          AppColors.naranjaPrimarioMedio,
          AppColors.naranjaPrimarioOscuro,
        ],
        stops: <double>[0.0, 0.25, 0.5, 1.0],
      ),
    );
  }

  /// Capa decorativa con gradiente radial para dar profundidad visual.
  ///
  /// Añade un efecto de luz desde la parte superior izquierda, realzando
  /// la sensación de relieve y atractivo visual.
  Widget _construirSobreposicionGradienteRadial() {
    return Container(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: const Alignment(0.2, 0.5),
          radius: 0.8,
          colors: <Color>[AppColors.blancoClaro, Colors.transparent],
        ),
      ),
    );
  }

  /// Contenido principal: logo, títulos y botón de login.
  ///
  /// Se usa [SingleChildScrollView] con `NeverScrollableScrollPhysics` para
  /// evitar desplazamiento, ya que el contenido está centrado y cabe en
  /// la mayoría de pantallas.
  Widget _construirContenidoPrincipal() {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          const SizedBox(height: 24),
          _construirLogoAnimado(),
          const SizedBox(height: 32),
          _construirTitulo(),
          const SizedBox(height: 8),
          _construirSubtitulo(),
          const SizedBox(height: 48),
          _construirBotonLogin(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  /// Logo con animación combinada: flotación continua + desvanecimiento inicial.
  ///
  /// El logo es un [SlideTransition] que aplica la flotación vertical y un
  /// [FadeTransition] para la entrada gradual. Además, incluye una etiqueta
  /// semántica para accesibilidad.
  Widget _construirLogoAnimado() {
    return Semantics(
      label: 'Logo de Clima UTEM',
      child: SlideTransition(
        position: _animacionFlotacion,
        child: FadeTransition(
          opacity: _animacionDesvanecimiento,
          child: _construirLogoClimatico(),
        ),
      ),
    );
  }

  /// Iconografía del logo: nube con sol superpuesto.
  ///
  /// Representa el concepto meteorológico de la aplicación, combinando
  /// los iconos de `Icons.cloud` y `Icons.sunny` con colores blanco y
  /// dorado [AppColors.oroSol].
  Widget _construirLogoClimatico() {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: AppColors.negroClaro,
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          const Icon(Icons.cloud, size: 100, color: AppColors.blanco),
          Positioned(
            top: 8,
            right: 8,
            child: Icon(Icons.sunny, size: 48, color: AppColors.oroSol),
          ),
        ],
      ),
    );
  }

  /// Título principal "Clima UTEM" con animación de desvanecimiento.
  Widget _construirTitulo() {
    return FadeTransition(
      opacity: _animacionDesvanecimiento,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Text(
          'Clima UTEM',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.displayLarge,
        ),
      ),
    );
  }

  /// Subtítulo "Clima en tu ubicación" con animación de desvanecimiento.
  Widget _construirSubtitulo() {
    return FadeTransition(
      opacity: _animacionDesvanecimiento,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Text(
          'Clima en tu ubicación',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      ),
    );
  }

  /// Botón de login envuelto en un [FadeTransition] para la entrada gradual.
  Widget _construirBotonLogin() {
    return FadeTransition(
      opacity: _animacionDesvanecimiento,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: _construirBotonLoginGoogle(),
      ),
    );
  }

  /// Botón de inicio de sesión con Google.
  ///
  /// Muestra un indicador de carga ([CircularProgressIndicator]) cuando
  /// `_estaCargando` es `true`, y deshabilita el `onTap` para evitar
  /// múltiples pulsaciones. En estado normal, muestra el icono de Google
  /// y el texto "Continuar con Google".
  ///
  /// El botón tiene un fondo blanco, esquinas redondeadas (12 px) y una
  /// sombra sutil para dar elevación.
  Widget _construirBotonLoginGoogle() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _estaCargando ? null : _manejarLoginGoogle,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          decoration: BoxDecoration(
            color: AppColors.blanco,
            borderRadius: BorderRadius.circular(12),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: AppColors.negroMedio,
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              if (_estaCargando)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                _construirIconoGoogle(),
              const SizedBox(width: 12),
              Text(
                _estaCargando ? 'Iniciando sesión...' : 'Continuar con Google',
                style: TextStyle(color: AppColors.naranjaPrimario),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Icono de Google utilizando el glifo `Icons.g_mobiledata`.
  ///
  /// Se colorea con [AppColors.azulGoogle] para mantener la identidad visual
  /// del botón de Google.
  Widget _construirIconoGoogle() {
    return const Icon(
      Icons.g_mobiledata,
      size: 20,
      color: AppColors.azulGoogle,
    );
  }

  /// Pie de página con texto de términos y condiciones.
  ///
  /// Aparece con la misma animación de desvanecimiento y utiliza un estilo
  /// de texto pequeño y semi-transparente ([AppColors.blancoClarisimo]).
  Widget _construirPie() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: FadeTransition(
        opacity: _animacionDesvanecimiento,
        child: Text(
          'Al continuar aceptas nuestros términos de servicio',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppColors.blancoClarisimo,
            fontSize: 12,
            fontWeight: FontWeight.w400,
          ),
        ),
      ),
    );
  }
}
