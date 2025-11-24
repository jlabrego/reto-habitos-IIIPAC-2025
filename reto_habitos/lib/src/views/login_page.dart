import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:reto_habitos/src/models/users.dart';
import 'package:reto_habitos/src/providers/user_service.dart';
import 'package:reto_habitos/src/shared/utils.dart';
import 'package:reto_habitos/src/widgets/custom_Scaffold.dart';
import 'package:reto_habitos/src/widgets/custom_text_field.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey=GlobalKey<FormState>(); 
  final _emailController=TextEditingController();
  final _passwordController=TextEditingController();
  bool _obscurePassword=true;
  bool _isLoading=false;
  bool rememberPassword = false;

  @override
  void dispose(){
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

 void _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try{
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim()
        );

        if(mounted) {
          final user = FirebaseAuth.instance.currentUser;
          final userName = user?.displayName ?? 'Usuario';
          setState(() => _isLoading = false);
          Utils.showSnackBar(context: context, title: 'Bienvenido $userName');
          context.push('/habits');
        } 

      } on FirebaseAuthException catch(e) {
          
          String message = 'Error desconocido';

          if(e.code=='user-not-found'){
            message='No existe una cuenta con ese correo';
          } else if(e.code=='wrong-password'){
            message='La contraseña es incorrecta';
          } else if(e.code=='invalid-email'){
            message = 'El formato de correo no es válido';
          } else if(e.code=='user-disabled'){
            message='Esta cuenta ha sido deshabilitada';
          } 

          if(mounted){
            setState(() => _isLoading = false);
            Utils.showSnackBar(context: context, title: message);
          }

        } catch(e){
          if(mounted){
            setState(() => _isLoading = false);
            Utils.showSnackBar(context: context, title: 'Hubo un error: $e');
          }
        }
    }
  }

  Future<UserCredential?> _handleGoogleSignIn() async {
    // Trigger the authentication flow
    final GoogleSignIn signIn = GoogleSignIn.instance;

    await signIn.initialize();

    // Obtain the auth details from the request
    final GoogleSignInAccount googleAuth = await signIn.authenticate();

    // Create a new credential
    final credential = GoogleAuthProvider.credential(
      idToken: googleAuth.authentication.idToken,
    );

    //GUARDAR USUARIO EN FIRESTORE DESPUÉS DE GOOGLE SIGN-IN
    final UserCredential userCredential = 
      await FirebaseAuth.instance.signInWithCredential(credential);
  if (userCredential.user != null) {
    final userService = UserService();
    final newUser = AppUser(
      id: userCredential.user!.uid,
      email: userCredential.user!.email!,
      name: userCredential.user!.displayName ?? 'Usuario Google',
      createdAt: DateTime.now(),
    );
    await userService.createOrUpdateAppUser(newUser);
  }
  
  return userCredential;
  }

  @override
  Widget build(BuildContext context) {
    return CustomScaffold(
      child: Column(
        children: [
          const Expanded(
            flex: 1,
            child: SizedBox(
              height: 10, 
            )
          ),
          Expanded(
            flex: 7,
            child: Container(
              padding: const EdgeInsets.fromLTRB(25.0, 50.0, 25.0, 20.0),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(40.0),
                  topRight: Radius.circular(40.0),
                ),
              ),
              child:  SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        'Bienvenido de nuevo',
                        style: TextStyle(
                          fontSize: 30.0,
                          fontWeight: FontWeight.w900,
                          color: Colors.deepPurple,
                        ),
                      ),
                
                      //Campo de correo electronico
                      CustomTextField(
                        label: 'Correo electronico',
                        hint: 'example@gmail.com',
                        keyboardType: TextInputType.emailAddress,
                        controller: _emailController,
                        prefixIcon: Icons.email_outlined,
                        validator: (value){
                          if(value==null || value.isEmpty){
                            return 'Por favor ingresa tu correo';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20,),
                
                      //Campo de la contraseña
                      CustomTextField(
                        label: 'Contraseña',
                        hint: '**********',
                        obscureText:_obscurePassword,
                        controller: _passwordController,
                        prefixIcon: Icons.lock_outlined,
                        suffixIcon: _obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        onSuffixIconTap: (){
                          setState(() => _obscurePassword = !_obscurePassword);
                        },
                        validator: (value){
                          if(value==null || value.isEmpty){
                            return 'Por favor ingresa tu contraseña';
                          }
                          if(value.length < 6){
                            return 'La contraseña debe tener al menos 6 carácteres';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 5,),
                
                      //Recordar contraseña 
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Checkbox(
                                value: rememberPassword, 
                                onChanged: (bool? value){
                                  setState(() {
                                    rememberPassword = value!;
                                  });
                                },
                                activeColor: Colors.deepPurple,
                                ),
                                const Text(
                                  'Recordar contraseña',
                                  style: TextStyle(
                                    color: Colors.black45,
                                  ),
                                )
                            ],
                          ),
                          GestureDetector(
                            child: Text(
                              'Olvide mi contraseña',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.deepPurple,
                              ),
                              ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20,),
                
                      //Boton de inicio de sesión
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _handleLogin,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.deepPurple
                          ),
                           child: _isLoading
                            ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation(Colors.white),
                              strokeWidth: 2,
                              ),
                            )
                            : const Text(
                              'Iniciar Sesión',
                              style: TextStyle(
                              color: Colors.white
                            ),
                           ),
                          ),
                      ),
                      const SizedBox(height: 20),
                      //Divisor
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              height: 1,
                              color: const Color(0xFFE5E7EB),
                            ),
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 12),
                            child: Text(
                              'O',
                              style: TextStyle(
                              color: Color(0xFF6B7280),
                              fontSize: 12,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Container(
                            height: 1,
                            color: const Color(0xFFE5E7EB),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Botón de Google Sign-In
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: OutlinedButton(
                          onPressed: () async {
                            final user = await _handleGoogleSignIn();

                            if (user != null && context.mounted) {
                            context.push('/habits');
                            }
                          },
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(
                            color: Color(0xFFE5E7EB),
                            width: 1,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Image(image: AssetImage('assets/google.png')),
                            Image.asset('assets/images/google.png', width: 25, height: 25),
                            const SizedBox(width: 12),
                            Expanded(
                              child: const Text(
                                'Continuar con Google',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF1F2937),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    ],
                  )
                ),
              ),
            )
          )
        ],
      ),
    );
  }
}
