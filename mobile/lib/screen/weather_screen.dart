import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:provider/provider.dart';
import 'package:weather/consts/app_colors.dart';
import 'package:weather/controller/weather_screen_controller.dart';
import 'package:weather/widgets/my_menu.dart';
import 'package:weather/screen/farmacia_screen.dart';
import 'package:weather/widgets/widget_mapa.dart';
import 'package:weather/widgets/clima_widget.dart';
import 'package:weather/widgets/estado_carga_widget.dart';
import 'package:weather/widgets/estado_error_widget.dart';
import 'package:weather/widgets/estado_vacio_widget.dart';

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
                return const EstadoCargaWidget();
              }

              // Estado de error
              if (controlador.mensajeError != null) {

                return EstadoErrorWidget(

                  mensaje:
                  controlador.mensajeError!,

                  onReintentar:
                  controlador.reintentar,

                );
              }

              // Estado vacío (sin datos)
              if (!controlador.tieneDatos) {
                return const EstadoVacioWidget();
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
                  Expanded(
                    flex: 1,
                    child: const ClimaWidget(),
                  ),
                ],
              );
            },
      ),
    );
  }
}
