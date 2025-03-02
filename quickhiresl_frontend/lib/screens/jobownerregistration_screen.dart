import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'personalinformation_screen.dart';
import '../services/auth_service.dart';

class JobOwnerRegistrationScreen extends StatefulWidget {
  final String email;
  final String password;

  const JobOwnerRegistrationScreen({
    Key? key,
    required this.email,
    required this.password,
  }) : super(key: key);

  @override
  _JobOwnerRegistrationScreenState createState() =>
      _JobOwnerRegistrationScreenState();
}

class _JobOwnerRegistrationScreenState
    extends State<JobOwnerRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController shopNameController = TextEditingController();
  final TextEditingController shopLocationController = TextEditingController();
  final TextEditingController shopRegNoController = TextEditingController();
  final AuthService _authService = AuthService();
  bool _isLoading = false;

  /// Fetch current location
  Future<void> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Location services are disabled. Please enable them.')),
      );
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location permission denied.')),
        );
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Location permissions are permanently denied.')),
      );
      return;
    }

    final position = await Geolocator.getCurrentPosition();
    shopLocationController.text = "${position.latitude}, ${position.longitude}";
  }

  /// Submit form data to server
  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final loginResult = await _authService.login(widget.email, widget.password);
        if (!loginResult['success']) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(loginResult['error'] ?? 'Login failed')),
          );
          return;
        }

        final userId = await _authService.getUserId();
        if (userId == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('User ID not found. Please try again.')),
          );
          return;
        }

        final jobOwnerDetails = {
          'jobOwnerDetails': {
            'shopName': shopNameController.text,
            'shopLocation': shopLocationController.text,
            'shopRegisterNo': shopRegNoController.text,
          }
        };

        final response =
            await _authService.updateRole(userId, 'jobowner', details: jobOwnerDetails);
        if (response['success']) {
          final refreshResult =
              await _authService.login(widget.email, widget.password);
          if (refreshResult['success']) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => const PersonalInformationScreen(),
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Failed to refresh session. Please log in again.')),
            );
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to update role. Please try again.')),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// Header with back button and title
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Color(0xFF98C9C5),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.black),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Job Owners\nRegistration',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 10),
                    const Text(
                      'Please fill in your details',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.black87,
                      ),
                    ),
                ],
              ),
            ),

            /// Form Fields in the middle of the screen
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildTextField(shopNameController, "Shop Name"),
                      const SizedBox(height: 15),
                      _buildLocationField(),
                      const SizedBox(height: 15),
                      _buildTextField(shopRegNoController, "Shop Register No"),
                      const SizedBox(height: 30),

                      /// Next Button
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _submitForm,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          child: _isLoading
                              ? const CircularProgressIndicator(color: Colors.white)
                              : const Text(
                                  'Next',
                                  style: TextStyle(color: Colors.white, fontSize: 18),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Floating Label Text Field
  Widget _buildTextField(TextEditingController controller, String label) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.white,
        floatingLabelBehavior: FloatingLabelBehavior.auto,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide(color: Colors.grey.shade400),
        ),
      ),
      validator: (value) => value == null || value.isEmpty ? '$label is required' : null,
    );
  }

  /// Location Field with GPS Button
  Widget _buildLocationField() {
    return TextFormField(
      controller: shopLocationController,
      decoration: InputDecoration(
        labelText: "Shop Location",
        filled: true,
        fillColor: Colors.white,
        floatingLabelBehavior: FloatingLabelBehavior.auto,
        suffixIcon: IconButton(
          icon: const Icon(Icons.location_on, color: Colors.red),
          onPressed: _getCurrentLocation,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide(color: Colors.grey.shade400),
        ),
      ),
    );
  }
}











// import 'package:flutter/material.dart';
// import 'personalinformation_screen.dart';
// import '../services/auth_service.dart';

// class JobOwnerRegistrationScreen extends StatefulWidget {
//   final String email;
//   final String password;

//   const JobOwnerRegistrationScreen({
//     Key? key,
//     required this.email,
//     required this.password,
//   }) : super(key: key);

//   @override
//   _JobOwnerRegistrationScreenState createState() => _JobOwnerRegistrationScreenState();
// }

// class _JobOwnerRegistrationScreenState extends State<JobOwnerRegistrationScreen> {
//   final _formKey = GlobalKey<FormState>();
//   final TextEditingController shopNameController = TextEditingController();
//   final TextEditingController shopLocationController = TextEditingController();
//   final TextEditingController shopRegNoController = TextEditingController();
//   final AuthService _authService = AuthService();
//   bool _isLoading = false;

//   Future<void> _submitForm() async {
//     if (_formKey.currentState!.validate()) {
//       setState(() {
//         _isLoading = true;
//       });

//       try {
//         // First, login to get the token
//         final loginResult = await _authService.login(widget.email, widget.password);
        
//         if (!loginResult['success']) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             SnackBar(content: Text(loginResult['error'] ?? 'Login failed')),
//           );
//           return;
//         }

//         // Get the userId
//         final userId = await _authService.getUserId();
//         if (userId == null) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             const SnackBar(content: Text('User ID not found. Please try again.')),
//           );
//           return;
//         }

//         // Prepare job owner details
//         final jobOwnerDetails = {
//           'jobOwnerDetails': {
//             'shopName': shopNameController.text,
//             'shopLocation': shopLocationController.text,
//             'shopRegisterNo': shopRegNoController.text,
//           }
//         };

//         // Update role and details
//         final response = await _authService.updateRole(
//           userId,
//           'jobowner',
//           details: jobOwnerDetails,
//         );

//         if (response['success']) {
//           // After successful role update, refresh the token by logging in again
//           final refreshResult = await _authService.login(widget.email, widget.password);
          
//           if (refreshResult['success']) {
//             Navigator.pushReplacement(
//               context,
//               MaterialPageRoute(
//                 builder: (context) => const PersonalInformationScreen(),
//               ),
//             );
//           } else {
//             ScaffoldMessenger.of(context).showSnackBar(
//               const SnackBar(content: Text('Failed to refresh session. Please log in again.')),
//             );
//           }
//         } else {
//           ScaffoldMessenger.of(context).showSnackBar(
//             const SnackBar(content: Text('Failed to update role. Please try again.')),
//           );
//         }
//       } catch (e) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Error: $e')),
//         );
//       } finally {
//         setState(() {
//           _isLoading = false;
//         });
//       }
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.white,
//       body: SafeArea(
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Container(
//               width: double.infinity,
//               padding: const EdgeInsets.all(20),
//               decoration: const BoxDecoration(
//                 color: Color(0xFF98C9C5),
//                 borderRadius: BorderRadius.only(
//                   bottomLeft: Radius.circular(20),
//                   bottomRight: Radius.circular(20),
//                 ),
//               ),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Container(
//                     margin: const EdgeInsets.only(bottom: 30),
//                     decoration: BoxDecoration(
//                       shape: BoxShape.circle,
//                       border: Border.all(color: const Color.fromARGB(0, 0, 0, 0)),
//                       color: const Color.fromARGB(0, 255, 255, 255),
//                     ),
//                     child: IconButton(
//                       icon: const Icon(Icons.arrow_back, color: Colors.black),
//                       onPressed: () => Navigator.pop(context),
//                     ),
//                   ),
//                   const Text(
//                     'Job Owners\nRegistration',
//                     style: TextStyle(
//                       fontSize: 32,
//                       fontWeight: FontWeight.bold,
//                       color: Colors.black,
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//             Padding(
//               padding: const EdgeInsets.all(20),
//               child: Form(
//                 key: _formKey,
//                 child: Column(
//                   children: [
//                     _buildTextField(shopNameController, "Shop Name"),
//                     const SizedBox(height: 15),
//                     _buildTextField(shopLocationController, "Shop Location"),
//                     const SizedBox(height: 15),
//                     _buildTextField(shopRegNoController, "Shop Register No"),
//                     const SizedBox(height: 30),
//                     SizedBox(
//                       width: double.infinity,
//                       height: 50,
//                       child: ElevatedButton(
//                         onPressed: _isLoading ? null : _submitForm,
//                         style: ElevatedButton.styleFrom(
//                           backgroundColor: Colors.black,
//                           shape: RoundedRectangleBorder(
//                             borderRadius: BorderRadius.circular(30),
//                           ),
//                         ),
//                         child: _isLoading
//                             ? const CircularProgressIndicator(color: Colors.white)
//                             : const Text(
//                                 'Next',
//                                 style: TextStyle(
//                                   color: Colors.white,
//                                   fontSize: 18,
//                                 ),
//                               ),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildTextField(TextEditingController controller, String hintText) {
//     return TextFormField(
//       controller: controller,
//       decoration: InputDecoration(
//         hintText: hintText,
//         filled: true,
//         fillColor: Colors.white,
//         contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
//         border: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(30),
//           borderSide: BorderSide.none,
//         ),
//       ),
//       validator: (value) {
//         if (value == null || value.isEmpty) {
//           return '$hintText is required';
//         }
//         return null;
//       },
//     );
//   }
// }
