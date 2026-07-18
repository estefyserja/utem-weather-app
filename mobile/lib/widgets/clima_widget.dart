import 'package:flutter/material.dart';
import 'package:weather/consts/app_colors.dart';
import 'package:weather/controller/weather_screen_controller.dart';
import 'package:weather/model/observacion_meteo.dart';
import 'package:provider/provider.dart';

class ClimaWidget extends StatelessWidget {
  const ClimaWidget({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Selector<WeatherScreenController, ObservacionMeteo?>(
      selector: (_, controlador) =>
      controlador.observacionMeteo,

      builder: (context, clima, child) {

        if (clima == null) {
          return const SizedBox();
        }

        return _construirSeccionClima(clima);
      },
    );
  }

  Widget _construirFilaClima(
      IconData icono,
      Color colorIcono,
      String etiqueta,
      String valor,
      ) {
    return Container(

      margin:
      const EdgeInsets.symmetric(vertical: 6),

      padding:
      const EdgeInsets.all(12),

      decoration:
      BoxDecoration(

        color:
        Colors.grey.shade100,

        borderRadius:
        BorderRadius.circular(12),

      ),


      child: Row(

        children: [

          Icon(
            icono,
            color: colorIcono,
            size: 30,
          ),


          const SizedBox(
            width: 15,
          ),


          Expanded(

            child: Text(

              etiqueta,

              style: const TextStyle(
                fontSize:16,
                fontWeight:FontWeight.w500,
              ),

            ),
          ),


          Text(

            valor,

            style: const TextStyle(
              fontSize:16,
              color:AppColors.azulAcentuado,
              fontWeight:FontWeight.w600,
            ),

          ),

        ],
      ),
    );
  }

  Widget _construirSeccionClima(ObservacionMeteo clima) {

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Card(
        elevation: 5,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),

        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment:
            CrossAxisAlignment.start,

            children: <Widget>[
              const Text(
                'Condiciones actuales',

                style: TextStyle(
                  fontSize: 22.0,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height:16),

              _construirFilaClima(
                Icons.numbers,
                Colors.blueGrey,
                'ID Observación',
                clima.idObservacion.toString(),
              ),

              _construirFilaClima(
                Icons.thermostat,
                Colors.red,
                'Temperatura',
                '${clima.temperatura.toStringAsFixed(1)} ºC',
              ),

              _construirFilaClima(
                Icons.water_drop,
                Colors.blue,
                'Humedad',
                '${clima.humedad}%',
              ),

              _construirFilaClima(
                Icons.wb_sunny,
                Colors.orange,
                'UV',
                '${clima.ultravioleta}',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
