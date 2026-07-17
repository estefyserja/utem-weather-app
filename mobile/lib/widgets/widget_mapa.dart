import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import 'package:weather/consts/app_colors.dart';
import 'package:weather/model/coordenada.dart';
import 'package:weather/model/farmacia.dart';

class MapaClimaWidget extends StatelessWidget {
  final Coordenada coordenada;
  final Farmacia? farmacia;

  const MapaClimaWidget({
    super.key,
    required this.coordenada,
    required this.farmacia,
  });

  void _mostrarFarmacia(
      BuildContext context,
      Farmacia farmacia,
      ) {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(

            title: Row(
              children: const [
                Icon(
                  Icons.local_pharmacy,
                  color: Colors.green,
                ),
                SizedBox(width: 10),
                Text('Farmacia cercana'),
              ],
            ),

            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                Text(
                  farmacia.nombre,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),

                const SizedBox(height:10),

                Text(
                  'Dirección:\n${farmacia.direccion}',
                ),

                const SizedBox(height:10),

                Text(
                  'Horario:\n${farmacia.aperturaNormal} - ${farmacia.cierreNormal}',
                ),

                const SizedBox(height:10),

                Text(
                  farmacia.distancia != null
                      ? 'Distancia: ${farmacia.distancia!.toStringAsFixed(2)} km'
                      : '',
                ),

              ],
            ),

            actions:[
              TextButton(
                onPressed: (){
                  Navigator.pop(context);
                },
                child: const Text('Cerrar'),
              )
            ],

          ),
        );
      }

  @override
  Widget build(BuildContext context) {
    final LatLng puntoCentral = LatLng(
      coordenada.latitud,
      coordenada.longitud,
    );

    return FlutterMap(
      options: MapOptions(
        initialCenter: puntoCentral,
        initialZoom: 15,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.example.weather',
        ),
        MarkerLayer(
          markers: [
            Marker(
              point: puntoCentral,
              width: 40,
              height: 40,
              child: const Icon(
                Icons.location_pin,
                color: AppColors.rojo,
                size: 40,
              ),
            ),

            if (farmacia != null)
              Marker(
                point: LatLng(
                  farmacia!.latitud,
                  farmacia!.longitud,
                ),
                width: 50,
                height: 50,
                child: GestureDetector(
                  onTap: () {
                    _mostrarFarmacia(context, farmacia!);
                  },
                  child: const Icon(
                    Icons.local_pharmacy,
                    color: Colors.green,
                    size: 40,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}