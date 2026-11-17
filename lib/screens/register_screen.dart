
import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:rive/rive.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  bool _obscurePass = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;

  // Controladores de la animacion Rive
  StateMachineController? _controller;
  SMIBool? _isChecking;
  SMIBool? _isHandsUp;
  SMITrigger? _trigSuccess;
  SMITrigger? _trigFail;
  SMINumber? _numLook;

  Timer? _typingDebounce;

  // FocusNodes
  final _nameFocus = FocusNode();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();
  final _confirmPasswordFocus = FocusNode();

  // Controladores de texto
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();

  // Errores de validacion
  String? nameError;
  String? emailError;
  String? passError;
  String? confirmPassError;

  // Validar correo
  bool isValidEmail(String email) {
    final re = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
    return re.hasMatch(email);
  }

  // Validar contraseña
  bool isValidPassword(String pass) {
    return pass.length >= 6;
  }

  // Traducir errores de Firebase
  String _mapFirebaseError(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'Este correo ya está registrado.';

      case 'invalid-email':
        return 'El correo electrónico no es válido.';

      case 'weak-password':
        return 'La contraseña es demasiado débil.';

      case 'operation-not-allowed':
        return 'El registro por correo no está habilitado en Firebase.';

      case 'network-request-failed':
        return 'Sin conexión a internet. Verifica tu red.';

      default:
        return 'Error al crear la cuenta: ${e.code}';
    }
  }

  // Animacion cuando se escribe el nombre o correo
  void _updateLook(String value) {
    if (_isChecking == null) return;

    _isChecking!.change(true);

    final look = (value.length / 60.0 * 100.0)
        .clamp(0.0, 100.0);

    _numLook?.value = look;

    _typingDebounce?.cancel();

    _typingDebounce = Timer(
      const Duration(seconds: 3),
      () {
        if (!mounted) return;
        _isChecking?.change(false);
      },
    );
  }

  // Crear cuenta
  Future<void> _onRegister() async {
    if (_isLoading) return;

    final name = _nameCtrl.text.trim();
    final email = _emailCtrl.text.trim();
    final pass = _passCtrl.text;
    final confirmPass = _confirmPassCtrl.text;

    // Validaciones
    final nError = name.length >= 3
        ? null
        : 'Ingresa tu nombre (mínimo 3 caracteres)';

    final eError = isValidEmail(email)
        ? null
        : 'Correo electrónico inválido';

    final pError = isValidPassword(pass)
        ? null
        : 'La contraseña debe tener al menos 6 caracteres';

    final cError = confirmPass.isNotEmpty && confirmPass == pass
        ? null
        : 'Las contraseñas no coinciden';

    setState(() {
      nameError = nError;
      emailError = eError;
      passError = pError;
      confirmPassError = cError;
    });

    FocusScope.of(context).unfocus();

    _typingDebounce?.cancel();
    _isChecking?.change(false);
    _isHandsUp?.change(false);
    _numLook?.value = 50.0;

    // Si hay errores, el osito reacciona
    if (nError != null ||
        eError != null ||
        pError != null ||
        cError != null) {
      _trigFail?.fire();
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Crear usuario en Firebase Authentication
      final credential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: pass,
      );

      final user = credential.user;

      if (user != null) {
        // Guardar nombre en el perfil de Firebase
        await user.updateDisplayName(name);
        await user.reload();
      }

      // El osito celebra el registro exitoso
      _trigSuccess?.fire();

      await Future.delayed(
        const Duration(milliseconds: 1500),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('¡Cuenta creada correctamente! 🎉'),
            backgroundColor: Colors.green,
          ),
        );

        Navigator.of(context).pop();
      }
    } on FirebaseAuthException catch (e) {
      _trigFail?.fire();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_mapFirebaseError(e)),
          backgroundColor: Colors.redAccent,
        ),
      );
    } catch (e) {
      _trigFail?.fire();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error inesperado: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void initState() {
    super.initState();

    // Nombre y correo: el osito sigue la escritura
    void handleTextFocus(FocusNode node) {
      node.addListener(() {
        if (node.hasFocus) {
          _isHandsUp?.change(false);
          _isChecking?.change(true);
          _numLook?.value = 50.0;
        }
      });
    }

    handleTextFocus(_nameFocus);
    handleTextFocus(_emailFocus);

    // Contraseña: el osito se cubre los ojos
    _passwordFocus.addListener(() {
      _isHandsUp?.change(
        _passwordFocus.hasFocus && _obscurePass,
      );
    });

    // Confirmacion: misma animacion
    _confirmPasswordFocus.addListener(() {
      _isHandsUp?.change(
        _confirmPasswordFocus.hasFocus && _obscureConfirm,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Crear cuenta'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                // Animacion del osito
                SizedBox(
                  width: size.width,
                  height: 200,
                  child: RiveAnimation.asset(
                    'assets/login-bear.riv',
                    stateMachines: const ['Login Machine'],
                    onInit: (artboard) {
                      _controller =
                          StateMachineController.fromArtboard(
                        artboard,
                        'Login Machine',
                      );

                      if (_controller == null) return;

                      artboard.addController(_controller!);

                      _isChecking =
                          _controller!.findSMI('isChecking');

                      _isHandsUp =
                          _controller!.findSMI('isHandsUp');

                      _trigSuccess =
                          _controller!.findSMI('trigSuccess');

                      _trigFail =
                          _controller!.findSMI('trigFail');

                      _numLook =
                          _controller!.findSMI('numLook');
                    },
                  ),
                ),

                const SizedBox(height: 8),

                // Nombre
                TextField(
                  controller: _nameCtrl,
                  focusNode: _nameFocus,
                  enabled: !_isLoading,
                  textCapitalization: TextCapitalization.words,
                  onChanged: _updateLook,
                  decoration: InputDecoration(
                    errorText: nameError,
                    hintText: 'Full Name',
                    prefixIcon: const Icon(Icons.person),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                // Correo
                TextField(
                  controller: _emailCtrl,
                  focusNode: _emailFocus,
                  enabled: !_isLoading,
                  keyboardType: TextInputType.emailAddress,
                  onChanged: _updateLook,
                  decoration: InputDecoration(
                    errorText: emailError,
                    hintText: 'Email',
                    prefixIcon: const Icon(Icons.email),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                // Contraseña
                TextField(
                  controller: _passCtrl,
                  focusNode: _passwordFocus,
                  enabled: !_isLoading,
                  obscureText: _obscurePass,
                  onChanged: (_) {
                    _isHandsUp?.change(_obscurePass);
                  },
                  decoration: InputDecoration(
                    errorText: passError,
                    hintText: 'Password',
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePass
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePass = !_obscurePass;
                        });

                        if (_passwordFocus.hasFocus) {
                          _isHandsUp?.change(_obscurePass);
                        }
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                // Confirmar contraseña
                TextField(
                  controller: _confirmPassCtrl,
                  focusNode: _confirmPasswordFocus,
                  enabled: !_isLoading,
                  obscureText: _obscureConfirm,
                  onChanged: (_) {
                    _isHandsUp?.change(_obscureConfirm);
                  },
                  decoration: InputDecoration(
                    errorText: confirmPassError,
                    hintText: 'Confirm Password',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirm
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscureConfirm = !_obscureConfirm;
                        });

                        if (_confirmPasswordFocus.hasFocus) {
                          _isHandsUp?.change(_obscureConfirm);
                        }
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Boton de registro
                MaterialButton(
                  minWidth: size.width,
                  height: 50,
                  color: Colors.pinkAccent,
                  disabledColor: Colors.pinkAccent.withValues(
                    alpha: 0.6,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  onPressed: _isLoading ? null : _onRegister,
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : const Text(
                          'Sign up',
                          style: TextStyle(color: Colors.white),
                        ),
                ),

                const SizedBox(height: 10),

                // Regresar al login
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Already have an account?'),
                    TextButton(
                      onPressed: _isLoading
                          ? null
                          : () => Navigator.of(context).pop(),
                      child: const Text(
                        'Login',
                        style: TextStyle(
                          color: Colors.black,
                          decoration: TextDecoration.underline,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmPassCtrl.dispose();

    _nameFocus.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _confirmPasswordFocus.dispose();

    _typingDebounce?.cancel();
    _controller?.dispose();

    super.dispose();
  }
}
