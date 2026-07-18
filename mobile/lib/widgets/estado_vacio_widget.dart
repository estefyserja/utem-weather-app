import 'package:flutter/material.dart';
import 'package:weather/consts/app_colors.dart';


class EstadoVacioWidget extends StatelessWidget {

  const EstadoVacioWidget({
    super.key,
  });


  @override
  Widget build(BuildContext context) {

    return const Center(

      child: Column(

        mainAxisAlignment:
        MainAxisAlignment.center,

        children: [

          Icon(
            Icons.cloud_off,
            size:64,
            color:AppColors.gris,
          ),


          SizedBox(
            height:16,
          ),


          Text(

            'No hay datos meteorológicos disponibles',

            style: TextStyle(
              fontSize:16,
              color:AppColors.gris,
            ),

            textAlign:
            TextAlign.center,
          ),

        ],
      ),
    );
  }
}