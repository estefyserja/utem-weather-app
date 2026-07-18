import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:weather/consts/app_colors.dart';
import 'package:weather/screen/login_screen.dart';

import 'package:provider/provider.dart';
import 'package:weather/controller/weather_screen_controller.dart';
import 'package:weather/services/servicio_rest.dart';
import 'package:weather/services/servicio_ubicacion.dart';
import 'package:weather/services/servicio_google.dart';
import 'package:weather/services/servicio_distancia.dart';

/// Punto de entrada principal de la aplicación Clima UTEM.
///
/// Esta función se ejecuta al iniciar la aplicación y realiza las siguientes
/// tareas de inicialización:
/// 1. Asegura que el sistema de widgets de Flutter esté vinculado al entorno
///    nativo mediante [WidgetsFlutterBinding.ensureInitialized].
/// 2. Inicializa el SDK de Google Sign-In para que esté listo antes de que
///    la UI comience a renderizarse, evitando retrasos al mostrar el selector
///    de cuentas.
/// 3. Inicia la aplicación con [MyApp].
///
/// ## Orden de inicialización
/// La inicialización temprana de Google Sign-In es crucial para que el botón
/// de login responda rápidamente. Si no se inicializa aquí, la primera vez
/// que el usuario intente iniciar sesión se produciría un retraso visible.
///
/// ## Ejemplo
/// Este archivo no se usa directamente, sino que es el punto de entrada
/// definido en `android/app/src/main/...` y `ios/Runner/...`. No requiere
/// invocación manual.
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await GoogleSignIn.instance.initialize();
  runApp(
    MultiProvider(
      providers: [
        Provider(
          create: (_) => ServicioRest(),
        ),

        Provider(
          create: (_) => ServicioUbicacion(),
        ),

        Provider(
          create: (_) => ServicioGoogle(),
        ),

        Provider(
          create: (_) => ServicioDistancia(),
        ),

        ChangeNotifierProvider(
          create: (context) =>
              WeatherScreenController(
                servicioRest:
                context.read<ServicioRest>(),

                servicioUbicacion:
                context.read<ServicioUbicacion>(),

                servicioGoogle:
                context.read<ServicioGoogle>(),

                servicioDistancia:
                context.read<ServicioDistancia>(),
              ),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

/// Widget raíz de la aplicación Clima UTEM.
///
/// Esta clase configura el tema visual de toda la aplicación, define las
/// rutas iniciales y establece la pantalla de inicio (login). Utiliza
/// [MaterialApp] con las siguientes características:
///
/// ## Configuración de temas
/// - **Tema claro**: Generado a partir de un color semilla ([AppColors.semillaTemaClaro])
///   usando `ColorScheme.fromSeed`, con Material 3 habilitado.
/// - **Tema oscuro**: Definido manualmente con [ColorScheme.dark], usando
///   [AppColors.naranjaPrimario] como color primario y [AppColors.superficieOscura]
///   como color de superficie.
/// - **Tipografía**: Utiliza la fuente [Poppins](https://fonts.google.com/specimen/Poppins)
///   mediante el paquete `google_fonts`.
///
/// ## Estructura de navegación
/// - La pantalla inicial es [LoginScreen], que maneja la autenticación del usuario.
/// - No se definen rutas nombradas adicionales; toda la navegación se realiza
///   mediante `Navigator.push` y `pushReplacement` desde las pantallas.
///
/// ## Dependencias
/// - [google_fonts]: Para cargar la fuente Poppins.
/// - [AppColors]: Paleta de colores centralizada.
/// - [LoginScreen]: Pantalla de inicio de sesión.
///
/// ## Ejemplo de uso
/// ```dart
/// // La aplicación se inicia automáticamente desde main()
/// // No es necesario instanciar MyApp manualmente.
/// ```
///
/// ## Notas de implementación
/// - El tema oscuro se configura explícitamente como `darkTheme` para que la
///   aplicación pueda adaptarse al modo oscuro del sistema. El tema claro se
///   define como `theme` y se usa cuando el sistema está en modo claro.
/// - Se usa `useMaterial3: true` para habilitar el diseño Material 3, que
///   ofrece componentes más modernos y consistentes.
/// - La fuente Poppins se aplica globalmente mediante `fontFamily` en el tema,
///   asegurando que todos los textos la usen por defecto.
///
/// ## Mejoras potenciales
/// - Agregar un `NavigatorObserver` para registrar eventos de navegación.
/// - Definir rutas nombradas para las pantallas principales (login, home, error)
///   y usar un `onGenerateRoute` para un manejo más centralizado.
/// - Incluir un `ThemeMode` personalizado para forzar el modo claro u oscuro
///   según preferencias del usuario.
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Clima UTEM',
      // Tema oscuro (se activa cuando el sistema está en modo oscuro)
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: const ColorScheme.dark(
          primary: AppColors.naranjaPrimario,
          surface: AppColors.superficieOscura,
        ),
      ),
      // Tema claro (se activa cuando el sistema está en modo claro)
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: GoogleFonts.poppins().fontFamily,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.semillaTemaClaro,
        ),
      ),
      // Pantalla inicial
      home: const LoginScreen(),
    );
  }
}
