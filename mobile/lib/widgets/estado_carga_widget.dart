import 'package:flutter/material.dart';
import 'package:weather/consts/app_colors.dart';


class EstadoCargaWidget extends StatelessWidget {

  const EstadoCargaWidget({
    super.key,
  });


  @override
  Widget build(BuildContext context) {

    return const Center(

      child: Column(

        mainAxisAlignment:
        MainAxisAlignment.center,

        children: [

          CircularProgressIndicator(),

          SizedBox(height:16),

          Text(
            'Cargando datos meteorológicos...',
            style: TextStyle(
              fontSize:16,
              color:AppColors.gris,
            ),
          ),

        ],
      ),
    );
  }
}