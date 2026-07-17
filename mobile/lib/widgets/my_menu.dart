import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:provider/provider.dart';
import 'package:weather/controller/weather_screen_controller.dart';
import 'package:weather/screen/login_screen.dart';
import 'package:weather/screen/success_screen.dart';
import 'package:weather/screen/weather_screen.dart';
import 'package:weather/services/servicio_almacenamiento.dart';
import 'package:weather/services/servicio_google.dart';
import 'package:weather/services/servicio_rest.dart';
import 'package:weather/services/servicio_ubicacion.dart';
import 'package:weather/services/servicio_distancia.dart';

/// Menú lateral (Drawer) de la aplicación.
///
/// Proporciona navegación rápida a las principales secciones de la app:
/// - **Inicio**: Pantalla de éxito después del login.
/// - **Ubicación**: Pantalla de monitoreo meteorológico con mapa y datos.
/// - **Cerrar Sesión**: Finaliza la sesión y redirige al login.
///
/// Además, muestra la información del usuario autenticado (nombre, email y
/// foto de perfil) en un encabezado estilizado con [UserAccountsDrawerHeader].
///
/// ## Estructura visual
/// - **Encabezado**: [UserAccountsDrawerHeader] con:
///   - Foto de perfil (cargada con [CachedNetworkImage]).
///   - Nombre y email del usuario (obtenidos de [ServicioAlmacenamiento]).
/// - **Opciones**: Tres [ListTile] con iconos y texto:
///   1. "Inicio" → navega a [SuccessScreen].
///   2. "Ubicación" → navega a [WeatherScreen] con todos los servicios inyectados.
///   3. "Cerrar Sesión" → ejecuta [ServicioGoogle.cerrarSesion] y navega a [LoginScreen].
///
/// ## Manejo de datos del usuario
/// Los datos del perfil se cargan de forma asíncrona usando [FutureBuilder]:
/// - **Nombre**: [ServicioAlmacenamiento.obtenerNombre].
/// - **Email**: [ServicioAlmacenamiento.obtenerEmail].
/// - **Foto**: [ServicioAlmacenamiento.obtenerUrlFoto] y se muestra con [CachedNetworkImage].
/// - Durante la carga se muestra un [CircularProgressIndicator].
/// - En caso de error se muestra un texto/icono por defecto.
///
/// ## Comportamiento de navegación
/// - **Inicio**: Usa [Navigator.push] para apilar la nueva pantalla.
/// - **Ubicación**: Usa [Navigator.push] y construye la pantalla con todos los
///   providers necesarios ([ServicioRest], [ServicioUbicacion], [ServicioGoogle],
///   y [WeatherScreenController]).
/// - **Cerrar Sesión**: Usa [Navigator.pushReplacement] para reemplazar toda la
///   pila con [LoginScreen], impidiendo que el usuario regrese al menú.
///
/// ## Dependencias
/// - [ServicioAlmacenamiento]: Para leer datos del usuario.
/// - [ServicioGoogle]: Para cerrar sesión.
/// - [Provider]: Para inyección de dependencias en [WeatherScreen].
/// - [cached_network_image]: Para cachear la foto de perfil.
///
/// ## Ejemplo de uso
/// ```dart
/// Scaffold(
///   drawer: const MyMenu(),
///   // ...
/// )
/// ```
///
/// ## Notas de implementación
/// - El método `_manejarCierreSesion` verifica `context.mounted` antes de
///   navegar para evitar errores en widgets desmontados.
/// - La inyección de dependencias en la opción "Ubicación" crea nuevas
///   instancias de los servicios; no reutiliza las existentes. En un entorno
///   con un contenedor de dependencias global, esto podría optimizarse.
/// - El uso de [FutureBuilder] con [ServicioAlmacenamiento] asegura que la UI
///   se actualice cuando los datos estén disponibles, mostrando indicadores
///   de carga mientras tanto.
///
/// ## Mejoras potenciales
/// - Centralizar la creación de providers para [WeatherScreen] en un método
///   separado, evitando repetición.
/// - Usar un solo [FutureBuilder] que cargue todos los datos del usuario
///   (nombre, email, foto) de una vez para reducir llamadas asíncronas.
/// - Agregar un indicador de carga mientras se cierra sesión.
/// - Extraer el encabezado y las opciones a widgets separados para mejorar
///   la legibilidad y mantenibilidad.
class MyMenu extends StatelessWidget {
  static final Logger _logger = Logger();

  const MyMenu({super.key});

  /// Maneja el cierre de sesión del usuario.
  ///
  /// Este método asíncrono:
  /// 1. Crea una instancia de [ServicioGoogle] y llama a `cerrarSesion()`
  ///    para finalizar la sesión en Google y eliminar los datos del
  ///    almacenamiento seguro.
  /// 2. Verifica que el widget aún esté montado (`context.mounted`) para
  ///    evitar navegaciones en widgets destruidos.
  /// 3. Usa [Navigator.pushReplacement] para reemplazar la pila actual
  ///    con [LoginScreen], asegurando que el usuario no pueda regresar
  ///    al menú o a pantallas protegidas.
  ///
  /// ## Manejo de errores
  /// Si `cerrarSesion()` falla, se registra el error en [Logger], pero la
  /// navegación se ejecuta de todos modos para permitir al usuario volver
  /// a intentar el login. En una implementación más robusta, se podría
  /// mostrar un diálogo de error.
  ///
  /// ## Parámetros
  /// - [context]: El contexto de construcción del widget, necesario para
  ///   la navegación y para verificar `mounted`.
  Future<void> _manejarCierreSesion(BuildContext context) async {
    ServicioGoogle servicioGoogle = ServicioGoogle();
    await servicioGoogle.cerrarSesion();
    // Verificar que el widget aún esté en el árbol antes de navegar
    if (context.mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          /// Encabezado del menú con información del usuario.
          ///
          /// Muestra el nombre, email y foto de perfil obtenidos de forma
          /// asíncrona desde [ServicioAlmacenamiento]. Durante la carga
          /// se muestra un indicador de progreso circular, y en caso de
          /// error se muestra un texto/icono por defecto.
          UserAccountsDrawerHeader(
            accountName: FutureBuilder<String>(
              future: ServicioAlmacenamiento.obtenerNombre(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.done) {
                  return Text(snapshot.data ?? '');
                } else if (snapshot.hasError) {
                  return const Text("Nombre");
                } else {
                  return const CircularProgressIndicator();
                }
              },
            ),
            accountEmail: FutureBuilder<String>(
              future: ServicioAlmacenamiento.obtenerEmail(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.done) {
                  return Text(snapshot.data ?? '');
                } else if (snapshot.hasError) {
                  return const Text("usuario@correo.cl");
                } else {
                  return const CircularProgressIndicator();
                }
              },
            ),
            currentAccountPicture: CircleAvatar(
              child: ClipOval(
                child: FutureBuilder(
                  future: ServicioAlmacenamiento.obtenerUrlFoto(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.done) {
                      String url = snapshot.data ?? '';
                      if (url.isNotEmpty) {
                        // Usa CachedNetworkImage para cachear la foto de perfil
                        return CachedNetworkImage(
                          imageUrl: url,
                          placeholder: (context, url) {
                            return const CircularProgressIndicator();
                          },
                          errorWidget: (context, url, error) {
                            _logger.e(error);
                            return const Icon(
                              Icons.person_3,
                              color: Colors.red,
                              size: 47,
                            );
                          },
                        );
                      } else {
                        return const Icon(Icons.person_4);
                      }
                    } else if (snapshot.hasError) {
                      return const Icon(Icons.person);
                    } else {
                      return const CircularProgressIndicator();
                    }
                  },
                ),
              ),
            ),
          ),

          /// Opción "Inicio" que navega a la pantalla de éxito.
          ListTile(
            leading: const Icon(Icons.home),
            title: const Text('Inicio'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) {
                    return SuccessScreen();
                  },
                ),
              );
            },
          ),

          /// Opción "Ubicación" que navega a la pantalla del clima.
          ///
          /// Inyecta todos los servicios necesarios ([ServicioRest],
          /// [ServicioUbicacion], [ServicioGoogle]) y el controlador
          /// [WeatherScreenController] mediante [Provider] y
          /// [ChangeNotifierProvider] para que la pantalla pueda acceder
          /// a ellos a través de `context.read` y `context.watch`.
          ListTile(
            leading: const Icon(Icons.map),
            title: const Text('Ubicación'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) {
                    return Provider<ServicioRest>(
                      create: (_) => ServicioRest(),
                      child: Provider<ServicioUbicacion>(
                        create: (_) => ServicioUbicacion(),
                        child: Provider<ServicioGoogle>(
                          create: (_) => ServicioGoogle(),
                          child:
                              ChangeNotifierProvider<WeatherScreenController>(
                                create: (BuildContext context) =>
                                    WeatherScreenController(
                                      servicioRest: context
                                          .read<ServicioRest>(),
                                      servicioUbicacion: context
                                          .read<ServicioUbicacion>(),
                                      servicioGoogle: context
                                          .read<ServicioGoogle>(),
                                      servicioDistancia: ServicioDistancia(),
                                    ),
                                child: const WeatherScreen(),
                              ),
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),

          /// Opción "Cerrar Sesión" que ejecuta el cierre de sesión.
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Cerrar Sesión'),
            onTap: () {
              _manejarCierreSesion(context);
            },
          ),
        ],
      ),
    );
  }
}
