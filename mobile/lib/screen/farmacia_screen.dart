import 'package:flutter/material.dart';
import 'package:weather/controller/farmacia_controller.dart';
import 'package:weather/services/servicio_google.dart';
import 'package:weather/services/servicio_rest.dart';
import 'package:weather/services/servicio_ubicacion.dart';
import 'package:weather/services/servicio_distancia.dart';

class FarmaciaScreen extends StatefulWidget {
  const FarmaciaScreen({super.key});

  @override
  State<FarmaciaScreen> createState() => _FarmaciaScreenState();
}

class _FarmaciaScreenState extends State<FarmaciaScreen> {
  late final FarmaciaController _controller;

  @override
  void initState() {
    super.initState();

    _controller = FarmaciaController(
      servicioRest: ServicioRest(),
      servicioUbicacion: ServicioUbicacion(),
      servicioGoogle: ServicioGoogle(),
      servicioDistancia: ServicioDistancia(),
    );

    _controller.addListener(_actualizarPantalla);
    _controller.inicializarDatos();
  }

  void _actualizarPantalla() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_actualizarPantalla);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_controller.estaCargando) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_controller.mensajeError != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Farmacia más cercana'),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 60,
                  color: Colors.red,
                ),
                const SizedBox(height: 20),
                Text(
                  _controller.mensajeError!,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 25),
                ElevatedButton(
                  onPressed: _controller.reintentar,
                  child: const Text("Reintentar"),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final farmacia = _controller.farmacia;

    if (farmacia == null) {
      return const Scaffold(
        body: Center(
          child: Text('No se encontró una farmacia cercana'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Farmacia más cercana'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Card(
            elevation: 3,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  const Icon(
                    Icons.local_pharmacy,
                    size: 60,
                    color: Colors.green,
                  ),

                  const SizedBox(height: 20),

                  Text(
                    farmacia.nombre,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 15),

                  Text("Dirección: ${farmacia.direccion}"),

                  const SizedBox(height: 10),

                  Text("Horario: ${farmacia.aperturaNormal} - ${farmacia.cierreNormal}",),

                  const SizedBox(height: 10),

                  Text(
                    farmacia.distancia != null
                        ? "Distancia: ${farmacia.distancia!.toStringAsFixed(2)} km"
                        : "Calculando...",
                  )


                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}