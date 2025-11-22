import 'package:flutter/material.dart';
import 'package:reto_habitos/src/widgets/custom_Scaffold.dart';
import 'package:reto_habitos/src/widgets/welcome_button.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});
  @override
  Widget build(BuildContext context) {
    return CustomScaffold(
      child: Column(
        children: [ 
          Flexible(
            flex: 8,
            child: Container(
             child: Center(
              child: RichText(
                textAlign: TextAlign.center,
                text: const TextSpan(
                  children: [
                    TextSpan(
                      text:'¡Bienvenido! \n',
                      style: TextStyle(
                        fontSize: 60,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    TextSpan(
                      text: '\n ¿Listo para tomar el control tus hábitos? \n Registrate o inicia sesión',
                      style: TextStyle(
                        fontSize: 15,
                      )
                    ),
                  ]
                ),
              ),
            ),
          ),
          ),
          const Flexible( 
            flex: 1,
            child: Align(
              alignment: Alignment.bottomRight,
              child: Row(
                children: [
                  Expanded(child:WelcomeButton(
                    buttonText: 'Registrarse',
                    onTap: '/register',
                    color: Colors.transparent,
                    textColor: Colors.white,
                  ) ,),
                  Expanded(child:WelcomeButton(
                    buttonText: 'Iniciar Sesion',
                    onTap: '/login',
                    color: Colors.white,
                    textColor: Colors.deepPurple,
                  ) ,),
                
               ],
              ),
            )
          ),
        ],
      )
      
    );



  }
}//Cierra la clase WelcomePage