import 'package:flutter/material.dart';
import 'package:weather/consts/app_colors.dart';
import 'package:weather/controller/weather_screen_controller.dart';
import 'package:weather/model/observacion_meteo.dart';

class ClimaWidget extends StatelessWidget {
  final WeatherScreenController controlador;

  const ClimaWidget({
    super.key,
    required this.controlador,
  });

  @override
  Widget build(BuildContext context) {
    return _construirSeccionClima();
  }

  Widget _construirFilaClima(String etiqueta, String valor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Text(
            etiqueta,
            style: const TextStyle(
              fontSize: 16.0,
              fontWeight: FontWeight.w500,
            ),
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

Widget _construirSeccionClima() {
  final ObservacionMeteo clima = controlador.observacionMeteo!;
  return SingleChildScrollView(
    padding: const EdgeInsets.all(24.0),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const Text(
          'Indicadores Climáticos Actuales',
          style: TextStyle(
            fontSize: 20.0,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16.0),

        _construirFilaClima(
          'ID Observación',
          clima.idObservacion.toString(),
        ),

        _construirFilaClima(
          'Temperatura',
          '${clima.temperatura.toStringAsFixed(1)} ºC',
        ),

        _construirFilaClima(
          'Humedad',
          '${clima.humedad}%',
        ),

        _construirFilaClima(
          'UV',
          '${clima.ultravioleta}',
        ),
      ],
    ),
  );
  }
}
