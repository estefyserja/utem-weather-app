import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:provider/provider.dart';
import 'package:weather/consts/app_colors.dart';
import 'package:weather/controller/weather_screen_controller.dart';
import 'package:weather/model/observacion_meteo.dart';
import 'package:weather/widgets/my_menu.dart';
import 'package:weather/screen/farmacia_screen.dart';
import 'package:weather/widgets/widget_mapa.dart';

/// Pantalla principal de monitoreo meteorológico.
///
/// Esta pantalla es el núcleo de la aplicación, mostrando la ubicación del
/// usuario en un mapa interactivo y los indicadores climáticos actuales.
/// Gestiona los estados de carga, error y datos exitosos utilizando el
/// patrón `Consumer` de Provider para reaccionar a los cambios del
/// [WeatherScreenController].
///
/// ## Estados de visualización
/// 1. **Carga**: Muestra un indicador de progreso circular y un mensaje
///    "Cargando datos meteorológicos...".
/// 2. **Error**: Muestra un icono de error, el mensaje descriptivo y un
///    botón "Reintentar" que invoca [WeatherScreenController.reintentar].
/// 3. **Vacío**: Se muestra cuando no hay datos disponibles después de la
///    carga (por ejemplo, si la respuesta del servidor está vacía).
/// 4. **Exitoso**: Presenta el mapa con la ubicación actual y una sección
///    con los indicadores climáticos (temperatura, humedad, UV, etc.).
///
/// ## Estructura visual
/// - **AppBar**: Barra superior con el título "Monitoreo Meteorológico"
///   centrado.
/// - **Drawer**: Menú lateral personalizado ([MyMenu]) que proporciona
///   opciones de navegación o configuración.
/// - **Mapa**: Ocupa la mitad superior de la pantalla, mostrando un mapa
///   de OpenStreetMap con un marcador (pin rojo) en la ubicación actual.
/// - **Datos climáticos**: Ocupa la mitad inferior, mostrando en una lista
///   vertical los indicadores: ID de observación, temperatura, humedad y
///   radiación UV.
///
/// ## Flujo de inicialización
/// La pantalla se inicializa en `initState` usando `addPostFrameCallback`
/// para llamar a `inicializarDatos()` del controlador después del primer
/// frame. Esto asegura que el contexto de Provider esté disponible.
///
/// ## Dependencias
/// - [WeatherScreenController]: Controlador que expone el estado y la lógica.
/// - [MyMenu]: Widget del menú lateral.
/// - [FlutterMap]: Biblioteca para mostrar mapas interactivos.
/// - [AppColors]: Paleta de colores centralizada.
///
/// ## Ejemplo de uso
/// ```dart
/// // Navegar a la pantalla principal (normalmente después del login)
/// Navigator.pushReplacement(
///   context,
///   MaterialPageRoute(
///     builder: (context) => ChangeNotifierProvider(
///       create: (_) => WeatherScreenController(...),
///       child: const WeatherScreen(),
///     ),
///   ),
/// );
/// ```
///
/// ## Notas de diseño
/// - El mapa usa `FlutterMap` con la capa de teselas de OpenStreetMap
///   (`https://tile.openstreetmap.org/{z}/{x}/{y}.png`).
/// - El marcador de ubicación es un icono `Icons.location_pin` de color rojo.
/// - La sección de clima usa `SingleChildScrollView` para soportar pantallas
///   pequeñas y orientaciones verticales.
/// - Los valores se formatean de la siguiente manera:
///   - Temperatura: 1 decimal (ej: "22.5 ºC").
///   - Humedad: sin decimales (ej: "65%").
///   - UV: sin formato especial (ej: "5").
/// - El color de los valores es [AppColors.azulAcentuado] para resaltar.
///
/// ## Posibles mejoras
/// - Agregar más indicadores climáticos (presión, velocidad del viento, etc.)
///   disponibles en [ObservacionMeteo].
/// - Permitir interacción con el mapa (zoom, arrastre) para explorar la zona.
/// - Implementar un botón para actualizar los datos manualmente.
/// - Añadir un indicador de la última actualización (fecha/hora).
/// - Extraer los widgets privados a componentes reutilizables para facilitar
///   pruebas y mantenimiento.
class WeatherScreen extends StatefulWidget {
  const WeatherScreen({super.key});

  @override
  State<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> {
  @override
  void initState() {
    super.initState();

    // Ejecutar inicialización después del primer frame para asegurar
    // que el contexto de Provider esté disponible.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<WeatherScreenController>().inicializarDatos();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Monitoreo Meteorológico'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.local_pharmacy),
            tooltip: 'Farmacia más cercana',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const FarmaciaScreen(),
                ),
              );
            },
          ),
        ],
      ),
      drawer: MyMenu(),
      body: Consumer<WeatherScreenController>(
        builder:
            (
              BuildContext context,
              WeatherScreenController controlador,
              Widget? child,
            ) {
              // Estado de carga
              if (controlador.estaCargando) {
                return _construirEstadoCarga();
              }

              // Estado de error
              if (controlador.mensajeError != null) {
                return _construirEstadoError(
                  controlador.mensajeError!,
                  controlador.reintentar,
                );
              }

              // Estado vacío (sin datos)
              if (!controlador.tieneDatos) {
                return _construirEstadoVacio();
              }

              // Estado exitoso con datos
              return Column(
                children: <Widget>[
                  Expanded(
                    child: MapaClimaWidget(
                      coordenada: controlador.coordenadaActual!,
                      farmacia: controlador.farmacia,
                    ),
                  ),
                  const Divider(
                    height: 1,
                    thickness: 2.0,
                    color: AppColors.naranjaPrimario,
                  ),
                  Expanded(flex: 1, child: _construirSeccionClima(controlador)),
                ],
              );
            },
      ),
    );
  }

  /// Construye el widget de estado de carga.
  ///
  /// Muestra un [CircularProgressIndicator] centrado con un mensaje
  /// informativo debajo. El color del texto es [AppColors.gris].
  Widget _construirEstadoCarga() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          CircularProgressIndicator(),
          SizedBox(height: 16.0),
          Text(
            'Cargando datos meteorológicos...',
            style: TextStyle(fontSize: 16.0, color: AppColors.gris),
          ),
        ],
      ),
    );
  }

  /// Construye el widget de estado de error.
  ///
  /// Muestra un icono de error (Icons.error_outline) en rojo, el mensaje
  /// de error en texto rojo y un botón "Reintentar" que ejecuta la
  /// función [onReintentar].
  ///
  /// - [mensaje]: Texto descriptivo del error ocurrido.
  /// - [onReintentar]: Función callback para reintentar la carga.
  Widget _construirEstadoError(String mensaje, VoidCallback onReintentar) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Icon(Icons.error_outline, size: 64.0, color: AppColors.rojo),
            const SizedBox(height: 16.0),
            Text(
              mensaje,
              style: const TextStyle(
                fontSize: 16.0,
                fontWeight: FontWeight.w500,
                color: AppColors.rojo,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24.0),
            ElevatedButton.icon(
              onPressed: onReintentar,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24.0,
                  vertical: 12.0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Construye el widget de estado vacío.
  ///
  /// Se muestra cuando no hay datos disponibles después de la carga,
  /// por ejemplo si el controlador tiene `tieneDatos == false`.
  /// Muestra un icono de nube tachada (Icons.cloud_off) y un mensaje
  /// "No hay datos meteorológicos disponibles".
  Widget _construirEstadoVacio() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Icon(Icons.cloud_off, size: 64.0, color: AppColors.gris),
          SizedBox(height: 16.0),
          Text(
            'No hay datos meteorológicos disponibles',
            style: TextStyle(fontSize: 16.0, color: AppColors.gris),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Construye la sección del mapa con la ubicación actual.
  ///
  /// Utiliza [FlutterMap] con una capa de teselas de OpenStreetMap y
  /// un marcador (pin rojo) en la coordenada del usuario.
  ///
  /// - [controlador]: Controlador que contiene la coordenada actual.
  ///   Asume que [controlador.coordenadaActual] no es null.
  /// - El centro del mapa se establece en la coordenada actual con un
  ///   zoom inicial de 15.0.

  /// Construye una fila con etiqueta y valor para los datos climáticos.
  ///
  /// - [etiqueta]: Texto descriptivo del indicador (ej: "Temperatura").
  /// - [valor]: Valor formateado del indicador (ej: "18.5 ºC").
  ///
  /// La etiqueta usa un estilo de texto normal (negrita), mientras que
  /// el valor usa [AppColors.azulAcentuado] y negrita para resaltar.
  Widget _construirFilaClima(String etiqueta, String valor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Text(
            etiqueta,
            style: const TextStyle(fontSize: 16.0, fontWeight: FontWeight.w500),
          ),
          Text(
            valor,
            style: const TextStyle(
              fontSize: 16.0,
              color: AppColors.azulAcentuado,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  /// Construye la sección de indicadores climáticos.
  ///
  /// Muestra un título y una lista de filas con los datos de la
  /// observación meteorológica actual.
  ///
  /// - [controlador]: Controlador que contiene la observación.
  ///   Asume que [controlador.observacionMeteo] no es null.
  /// - Los indicadores mostrados son:
  ///   - ID de observación (texto)
  ///   - Temperatura (con 1 decimal, en ºC)
  ///   - Humedad (sin decimales, en %)
  ///   - Radiación UV (sin formato)
  ///
  /// El widget está envuelto en [SingleChildScrollView] para permitir
  /// el desplazamiento vertical en pantallas pequeñas.
  Widget _construirSeccionClima(WeatherScreenController controlador) {
    final ObservacionMeteo clima = controlador.observacionMeteo!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text(
            'Indicadores Climáticos Actuales',
            style: TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16.0),
          _construirFilaClima('ID Observación', clima.idObservacion.toString()),
          _construirFilaClima(
            'Temperatura',
            '${clima.temperatura.toStringAsFixed(1)} ºC',
          ),
          _construirFilaClima('Humedad', '${clima.humedad.toString()}%'),
          _construirFilaClima('UV', '${clima.ultravioleta}'),
        ],
      ),
    );
  }
}
