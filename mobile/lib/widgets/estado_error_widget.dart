import 'package:flutter/material.dart';
import 'package:weather/consts/app_colors.dart';


class EstadoErrorWidget extends StatelessWidget {

  final String mensaje;
  final VoidCallback onReintentar;


  const EstadoErrorWidget({
    super.key,
    required this.mensaje,
    required this.onReintentar,
  });


  @override
  Widget build(BuildContext context) {

    return Center(

      child: Padding(

        padding: const EdgeInsets.all(24.0),

        child: Column(

          mainAxisAlignment:
          MainAxisAlignment.center,

          children: [

            const Icon(
              Icons.error_outline,
              size:64,
              color:AppColors.rojo,
            ),


            const SizedBox(
              height:16,
            ),


            Text(
              mensaje,

              style: const TextStyle(
                fontSize:16,
                fontWeight:FontWeight.w500,
                color:AppColors.rojo,
              ),

              textAlign:
              TextAlign.center,
            ),


            const SizedBox(
              height:24,
            ),


            ElevatedButton.icon(

              onPressed:
              onReintentar,

              icon:
              const Icon(Icons.refresh),

              label:
              const Text('Reintentar'),

              style:
              ElevatedButton.styleFrom(

                padding:
                const EdgeInsets.symmetric(
                  horizontal:24,
                  vertical:12,
                ),

              ),
            ),

          ],
        ),
      ),
    );
  }
}