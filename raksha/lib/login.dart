// ignore_for_file: non_constant_identifier_names, use_build_context_synchronously, duplicate_ignore, sort_child_properties_last
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:raksha/helper_functions.dart';
import 'package:raksha/homepage.dart';
import 'package:raksha/mytextfield.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';

// Global key to access the login form state
final loginFormKey = GlobalKey<_LoginSignupModalState>();

class LoginSignupModal extends StatefulWidget {
  const LoginSignupModal({super.key});

  @override
  _LoginSignupModalState createState() => _LoginSignupModalState();
}

class _LoginSignupModalState extends State<LoginSignupModal> {
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  TextEditingController usernameController = TextEditingController();
  TextEditingController confirmpwController = TextEditingController();
  bool isLogin = true;

  // Add this reset method
  void resetLoginForm() {
    // Clear all text controllers
    emailController.clear();
    passwordController.clear();
    usernameController.clear();
    confirmpwController.clear();

    // Reset to login mode if not already
    if (!isLogin) {
      setState(() {
        isLogin = true;
      });
    }

    // Force a rebuild to ensure all widgets are visible
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void initState() {
    super.initState();
    // Reset form on initialization
    resetLoginForm();
  }

  // Add these getter methods for responsive sizing
  double get _screenWidth => MediaQuery.of(context).size.width;
  double get _screenHeight => MediaQuery.of(context).size.height;

  // Responsive font sizes
  double get _titleFontSize => _screenWidth * 0.05;
  double get _buttonFontSize => _screenWidth * 0.045;
  double get _textFontSize => _screenWidth * 0.04;

  // Responsive sizes
  double get _buttonHeight => _screenHeight * 0.06;
  double get _buttonWidth => _screenWidth * 0.8;
  double get _toggleWidth => _screenWidth * 0.6;
  double get _spacing => _screenHeight * 0.015;

  // Email validation using regex pattern
  bool isValidEmail(String email) {
    final RegExp emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(email);
  }

  void login() async {
    showDialog(
      context: context,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      // Check if email is verified
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null && !user.emailVerified) {
        Navigator.pop(context); // Close loading dialog

        // Show verification alert
        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Email Not Verified'),
            content: const Text(
                'Please verify your email to continue. Check your inbox for a verification link.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () async {
                  try {
                    await user.sendEmailVerification();
                    Navigator.pop(context);
                    displayMessageToUser('Verification email sent!', context);
                  } catch (e) {
                    Navigator.pop(context);
                    displayMessageToUser(
                        'Error sending verification email: ${e.toString()}',
                        context);
                  }
                },
                child: const Text('Resend Link'),
              ),
            ],
          ),
        );

        // Sign out user since they're not verified
        await FirebaseAuth.instance.signOut();
        return;
      }

      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HomePage()),
        );
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) Navigator.pop(context);
      displayMessageToUser(e.code, context);
    }
  }

  void registerUser() async {
    // Validate email format first
    if (!isValidEmail(emailController.text.trim())) {
      displayMessageToUser("Please enter a valid email address", context);
      return;
    }

    //show loading circle
    showDialog(
      context: context,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    //make sure passwords match
    if (passwordController.text != confirmpwController.text) {
      //pop loading circle
      Navigator.pop(context);

      //show error message
      displayMessageToUser("Password don't match", context);
    }
    //if passwords do match
    else {
      // try creating account
      try {
        //create the user
        UserCredential? userCredential = await FirebaseAuth.instance
            .createUserWithEmailAndPassword(
                email: emailController.text, password: passwordController.text);

        // Send email verification
        await userCredential.user?.sendEmailVerification();

        //create a user document and collect them in firestore
        Future<void> createUserDocument(UserCredential? UserCredential) async {
          if (UserCredential != null && UserCredential.user != null) {
            await FirebaseFirestore.instance
                .collection("Users")
                .doc(UserCredential.user!.email)
                .set({
              'email': UserCredential.user!.email,
              'username': usernameController.text,
              'emailVerified': false, // Add verification field
            });
          }
        }

        //create a user document and add to firestore
        await createUserDocument(userCredential);

        //pop loading circle
        if (context.mounted) Navigator.pop(context);

        // Show verification instructions
        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Email Verification Sent'),
            content: const Text(
              'A verification link has been sent to your email address. Please verify your email to complete registration.',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  setState(() => isLogin = true); // Switch to login screen
                },
                child: const Text('OK'),
              ),
            ],
          ),
        );

        // Sign out user until verified
        await FirebaseAuth.instance.signOut();
      } on FirebaseAuthException catch (e) {
        //pop the loading circle
        Navigator.pop(context);

        //display the message to user
        displayMessageToUser(e.code, context);
      }
    }
  }

  // Sign in with Google
  Future<void> signInWithGoogle() async {
    // Show loading indicator
    showDialog(
      context: context,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      // Begin interactive sign-in process
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();

      // If user cancels the sign-in flow
      if (googleUser == null) {
        Navigator.pop(context); // Close loading dialog
        return;
      }

      // Obtain auth details from the request
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the Google credential
      UserCredential userCredential =
          await FirebaseAuth.instance.signInWithCredential(credential);

      // Store user information in Firestore if it's a new user
      if (userCredential.additionalUserInfo?.isNewUser ?? false) {
        await FirebaseFirestore.instance
            .collection("Users")
            .doc(userCredential.user!.email)
            .set({
          'email': userCredential.user!.email,
          'username': userCredential.user!.displayName ??
              googleUser.displayName ??
              'Google User',
          'emailVerified': true,
          'authProvider': 'google',
          'photoURL': userCredential.user!.photoURL,
        });
      }

      // Close loading dialog and navigate to home
      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HomePage()),
        );
      }
    } catch (e) {
      // Close loading dialog
      if (mounted) Navigator.pop(context);
      // Show error message
      displayMessageToUser(
          "Error signing in with Google: ${e.toString()}", context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.only(
            top: _spacing,
            left: _spacing,
            right: _spacing,
            bottom: MediaQuery.of(context).viewInsets.bottom + _spacing,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              buildToggle(),
              SizedBox(height: _spacing * 1.5),
              isLogin ? buildLoginForm() : buildSignupForm(),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildToggle() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(_screenWidth * 0.05),
      ),
      child: Stack(
        children: [
          AnimatedAlign(
            duration: const Duration(milliseconds: 300),
            alignment: isLogin ? Alignment.centerLeft : Alignment.centerRight,
            child: Container(
              width: _toggleWidth * 0.5,
              height: _buttonHeight,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(_screenWidth * 0.05),
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () => setState(() => isLogin = true),
                  child: Text(
                    "Login",
                    style: TextStyle(
                      fontSize: _titleFontSize,
                      fontWeight: FontWeight.bold,
                      color: isLogin ? Colors.black : Colors.grey,
                      fontFamily: 'poppy',
                    ),
                  ),
                ),
              ),
              Expanded(
                child: TextButton(
                  onPressed: () => setState(() => isLogin = false),
                  child: Text(
                    "Sign up",
                    style: TextStyle(
                      fontSize: _titleFontSize,
                      fontWeight: FontWeight.bold,
                      color: isLogin ? Colors.grey : Colors.black,
                      fontFamily: 'poppy',
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      width: _toggleWidth,
      height: _buttonHeight,
    );
  }

  Widget buildLoginForm() {
    return Column(
      children: [
        Mytextfield(
          label: 'Email',
          obscureText: false,
          controller: emailController,
        ),
        SizedBox(height: _spacing),
        Mytextfield(
          label: 'Password',
          obscureText: true,
          controller: passwordController,
        ),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () {},
            child: Text(
              'Forgot Password?',
              style: TextStyle(
                color: Colors.blue,
                fontSize: _textFontSize * 0.8,
              ),
            ),
          ),
        ),
        SizedBox(height: _spacing),
        _buildButton(
          onPressed: login,
          text: "Login",
          isPrimary: true,
        ),
        SizedBox(height: _spacing),
        Text(
          '───── OR ─────',
          style: TextStyle(
            fontSize: _textFontSize,
            fontWeight: FontWeight.bold,
            fontFamily: 'poppy',
          ),
        ),
        SizedBox(height: _spacing),
        _buildSocialButton(
          onPressed: signInWithGoogle,
          text: "Login with Google",
          icon: FontAwesomeIcons.google,
          iconSize: _textFontSize,
        ),
        SizedBox(height: _spacing * 2),
      ],
    );
  }

  Widget buildSignupForm() {
    return Column(
      children: [
        Mytextfield(
          label: 'Username',
          obscureText: false,
          controller: usernameController,
        ),
        SizedBox(height: _spacing),
        Mytextfield(
          label: 'Email',
          obscureText: false,
          controller: emailController,
        ),
        SizedBox(height: _spacing),
        Mytextfield(
          label: 'Password',
          obscureText: true,
          controller: passwordController,
        ),
        SizedBox(height: _spacing),
        Mytextfield(
          label: 'Confirm Password',
          obscureText: true,
          controller: confirmpwController,
        ),
        SizedBox(height: _spacing),
        _buildButton(
          onPressed: registerUser,
          text: "Create Account",
          isPrimary: true,
        ),
        SizedBox(height: _spacing),
        Text(
          '───── OR ─────',
          style: TextStyle(
            fontSize: _textFontSize,
            fontWeight: FontWeight.bold,
            fontFamily: 'poppy',
          ),
        ),
        SizedBox(height: _spacing),
        _buildSocialButton(
          onPressed: signInWithGoogle,
          text: "Sign up with Google",
          icon: FontAwesomeIcons.google,
          iconSize: _textFontSize,
        ),
        SizedBox(height: _spacing * 2),
      ],
    );
  }

  Widget _buildButton({
    required VoidCallback onPressed,
    required String text,
    required bool isPrimary,
  }) {
    return SizedBox(
      width: _buttonWidth,
      height: _buttonHeight,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: isPrimary ? Colors.black : Colors.grey[300],
          foregroundColor: isPrimary ? Colors.white : Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_screenWidth * 0.02),
          ),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: _buttonFontSize,
            fontWeight: FontWeight.bold,
            fontFamily: 'poppy',
          ),
        ),
      ),
    );
  }

  Widget _buildSocialButton({
    required VoidCallback onPressed,
    required String text,
    required IconData icon,
    double? iconSize,
  }) {
    return SizedBox(
      width: _buttonWidth,
      height: _buttonHeight,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.grey[300],
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_screenWidth * 0.02),
          ),
        ),
        icon: Icon(icon, size: iconSize ?? _buttonHeight * 0.6),
        label: Text(
          text,
          style: TextStyle(
            fontSize: _buttonFontSize * 0.8,
            fontWeight: FontWeight.bold,
            fontFamily: 'poppylight',
          ),
        ),
      ),
    );
  }
}
