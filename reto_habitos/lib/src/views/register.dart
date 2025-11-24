import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:reto_habitos/src/models/users.dart';
import 'package:reto_habitos/src/providers/user_service.dart';
import 'package:reto_habitos/src/widgets/custom_Scaffold.dart';
import 'package:reto_habitos/src/widgets/custom_text_field.dart';

class Register extends StatefulWidget {
  const Register({super.key});

  @override
  State<Register> createState() => _RegisterState();
}

class _RegisterState extends State<Register> {
  final _formKey=GlobalKey<FormState>(); 
  final _nameController=TextEditingController();
  final _emailController=TextEditingController();
  final _passwordController=TextEditingController();
  bool _obscurePassword=true;
  bool _isLoading=false;
  bool rememberPassword = false;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final userService=UserService();

  Future<void> _registerUser() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        // Crear usuario en Firebase
        UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

        // Actualizar el nombre del usuario
        await userCredential.user!.updateDisplayName(_nameController.text.trim());

        // ✅ NUEVO: Guardar usuario en Firestore
        final newUser = AppUser(
          id: userCredential.user!.uid,
          email: _emailController.text.trim(),
          name: _nameController.text.trim(),
          createdAt: DateTime.now(),
        );

        await userService.createOrUpdateAppUser(newUser);

        // Mostrar éxito y navegar 
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('¡Registro exitoso!')),
          );
          
          // Navegar a la pagina de habitos
          context.push('/login');
        }
      } on FirebaseAuthException catch (e) {
        // Manejar errores de Firebase 
        String message;
        if (e.code == 'weak-password') {
          message = 'La contraseña es demasiado débil.';
        } else if (e.code == 'email-already-in-use') {
          message = 'El correo electrónico ya está en uso.';
        } else {
          message = 'Error de registro: ${e.message}';
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(message)),
          );
        }
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
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
                        'Registrate para continuar',
                        style: TextStyle(
                          fontSize: 30.0,
                          fontWeight: FontWeight.w900,
                          color: Colors.deepPurple,
                        ),
                      ),
                
                      //Campo de correo electronico
                      CustomTextField(
                        label: 'Nombre y apellido',
                        keyboardType: TextInputType.text,
                        controller: _nameController,
                        prefixIcon: Icons.person,
                        validator: (value){
                          if(value==null || value.isEmpty){
                            return 'Por favor ingresa tu nombre';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20,),

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
                        ],
                      ),
                      const SizedBox(height: 20,),
                
                      //Boton de inicio de sesión
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _registerUser,
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
                              'Registrarse',
                              style: TextStyle(
                              color: Colors.white
                            ),
                           ),
                          ),
                      ),
                      const SizedBox(height: 20),
                     
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

