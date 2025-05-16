import 'dart:convert';
import 'dart:developer';
import 'dart:ffi';
import 'package:OhMyGERD/presentation/routes/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart'; // Import flutter_dotenv

class AuthService {
  final _auth = FirebaseAuth.instance;

  //aman
  Future<Map<String, dynamic>?> handleRegisterLoginWithGoogle() async {
    try {
      final googleUser = await GoogleSignIn().signIn();
      final googleAuth = await googleUser?.authentication;
      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth?.idToken,
        accessToken: googleAuth?.accessToken,
      );

      // Sign in to Firebase with the credentials
      UserCredential userCredential = await _auth.signInWithCredential(
        credential,
      );
      User? user = userCredential.user;

      if (user != null) {
        // Data yang akan dikirim untuk pendaftaran
        Map<String, dynamic> data = {
          'uid': user.uid,
          'name': user.displayName,
          'email': user.email,
          'profilePicture': user.photoURL,
          'providerId': 'google.com',
        };

        final String apiUrl = '${dotenv.env['API_URL']}/auth/register';
        final Uri url = Uri.parse(apiUrl);

        final response = await http.post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: json.encode(data),
        );

        if (response.statusCode == 200) {
          final responseData = json.decode(response.body);
          print("response data $responseData");
          if (responseData['isCreated'] == true) {
            print(responseData);
            print('User baru dibuat, arahkan ke halaman biodata');
            await createUserDataToBackend(user: user);
            final Map<String, dynamic> dataCredential = {
              "userCredential": userCredential,
              "route": "biodata",
            };
            return dataCredential;
          } else {
            print('User sudah ada, arahkan ke homepage');
            final Map<String, dynamic> dataCredential = {
              "userCredential": userCredential,
              "route": "home",
            };
            return dataCredential;
          }
        } else {
          print('Gagal register/login: ${response.statusCode}');
        }
      }
    } on FirebaseAuthException catch (err) {
      if (err.code == 'email-already-in-use') {
        print('Email sudah dipakai oleh akun lain.');
      } else {
        print('Error lain: ${err.message}');
      }
    } catch (error) {
      print(error.toString());
    }
    return null;
  }

  // //aman
  // Future<UserCredential?> registerWithGoogle() async {
  //   try {
  //     final googleUser = await GoogleSignIn().signIn();
  //     final googleAuth = await googleUser?.authentication;
  //     final credential = GoogleAuthProvider.credential(
  //       idToken: googleAuth?.idToken,
  //       accessToken: googleAuth?.accessToken,
  //     );
  //     // Sign in to Firebase with the credentials
  //     UserCredential userCredential = await _auth.signInWithCredential(
  //       credential,
  //     );
  //     User? user = userCredential.user;
  //     if (user != null) {
  //       await createUserDataToBackend(user: user);
  //     }
  //     return userCredential;
  //   } on FirebaseAuthException catch (err) {
  //     if (err.code == 'email-already-in-use') {
  //       print('Email sudah dipakai oleh akun lain.');
  //     } else {
  //       print('Error lain: ${err.message}');
  //     }
  //   } catch (error) {
  //     print(error.toString());
  //   }
  //   return null;
  // }

  // //agak aman untuk yang register (bener bener orang yg mbuat akun, bukan orang yg login )
  // Future<UserCredential?> loginWithGoogle(BuildContext context) async {
  //   try {
  //     final googleUser = await GoogleSignIn().signIn();
  //     final googleAuth = await googleUser?.authentication;
  //     final credential = GoogleAuthProvider.credential(
  //       idToken: googleAuth?.idToken,
  //       accessToken: googleAuth?.accessToken,
  //     );
  //     // Sign in to Firebase with the credentials
  //     UserCredential userCredential = await _auth.signInWithCredential(
  //       credential,
  //     );
  //     User? user = userCredential.user;
  //     if (user != null) {
  //       await createUserDataToBackend(user: user);
  //     }
  //     return userCredential;
  //   } catch (error) {
  //     print(error.toString());
  //   }
  //   return null;
  // }

  //aman
  Future<UserCredential?> registerWithoutGoogle(
    String name,
    String email,
    String password,
  ) async {
    try {
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);
      User? user = userCredential.user;
      if (user != null) {
        // Kirim data pengguna ke backend
        await createUserDataToBackend(user: user, name: name);
      }
      return userCredential;
    } on FirebaseAuthException catch (err) {
      if (err.code == 'email-already-in-use') {
        print('Email sudah dipakai oleh akun lain.');
      } else if (err.code == 'weak-password') {
        print('Password terlalu lemah.');
      } else {
        print('Error lain: ${err.message}');
      }
    } catch (error) {
      print(error.toString());
    }
    return null;
  }

  //blum aman
  Future<UserCredential?> loginWithoutGoogle(
    String email,
    String password,
    BuildContext context,
  ) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential;
    } catch (error) {
      print(error.toString());
    }
    return null;
  }

  Future<Map<String, dynamic>?> sendUserBiodata(
    User user,
    String birthDate,
    String gender,
    int weight,
    String diseases,
  ) async {
    try {
      // Siapkan data yang ingin dikirim ke backend
      Map<String, dynamic> userData = {
        'uid': user.uid,
        'birthDate': birthDate,
        'gender': gender,
        'weight': weight,
        'diseases': diseases,
      };
      final String apiUrl = '${dotenv.env['API_URL']}/auth/addBiodata';
      final Uri url = Uri.parse(apiUrl);
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(userData),
      );

      if (response.statusCode == 200) {
        log('Success sending data');
      } else {
        log('Failed to sdasend data: ${response.statusCode}');
      }
      return json.decode(response.body);
    } catch (e) {
      log("Addbiodata Error sending data to backend: $e");
    }
  }

  Future<Map<String, dynamic>?> getUserMealAndSnackTime(User user) async {
    try {
      // Siapkan data yang ingin dikirim ke backend
      Map<String, dynamic> userData = {'uid': user.uid};
      final String apiUrl =
          '${dotenv.env['API_URL']}/auth/getUserMealSnackTime';
      final Uri url = Uri.parse(apiUrl);
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(userData),
      );

      if (response.statusCode == 200) {
        log('Success sending data');
      } else {
        log('Failed to send data: ${response.statusCode}');
      }
      return json.decode(response.body);
    } catch (e) {
      log("Error sending data to backend: $e");
    }
  }

  Future<Map<String, dynamic>?> sendUserMealAndSnackTime(
    User user,
    String breakfastTime,
    String lunchTime,
    String dinnerTime,
    int snackIntensity,
    int reminderInterval,
    String maxSnackTime,
    String startSnackTime,
  ) async {
    try {
      // Siapkan data yang ingin dikirim ke backend
      Map<String, dynamic> userData = {
        'uid': user.uid,
        'breakfastTime': breakfastTime,
        'lunchTime': lunchTime,
        'dinnerTime': dinnerTime,
        'snackIntensity': snackIntensity,
        'reminderInterval': reminderInterval,
        'maxSnackTime': maxSnackTime,
        'startSnackTime': startSnackTime,
      };
      final String apiUrl = '${dotenv.env['API_URL']}/auth/addMealSnackTime';
      final Uri url = Uri.parse(apiUrl);
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(userData),
      );

      if (response.statusCode == 200) {
        log('Success sending data');
      } else {
        log('Failed to send data: ${response.statusCode}');
      }
      return json.decode(response.body);
    } catch (e) {
      log("Error sending data to backend: $e");
    }
  }

  Future<Map<String, dynamic>?> updateUserMealAndSnackTime(
    User user,
    Map<String, dynamic> data,
  ) async {
    try {
      // Siapkan data yang ingin dikirim ke backend
      Map<String, dynamic> userData = {'uid': user.uid, ...data};
      final String apiUrl = '${dotenv.env['API_URL']}/auth/updateMealSnackTime';
      final Uri url = Uri.parse(apiUrl);
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(userData),
      );

      if (response.statusCode == 200) {
        log('Success sending data');
      } else {
        log('Failed to send data: ${response.statusCode}');
      }
      return json.decode(response.body);
    } catch (e) {
      log("Error sending data to backend: $e");
    }
  }

  Future<Map<String, dynamic>?> sendFCMToken(User user, String fcmToken) async {
    try {
      Map<String, dynamic> fcmData = {'uid': user.uid, 'fcmToken': fcmToken};
      final String apiUrl = '${dotenv.env['API_URL']}/auth/sendFCMToken';
      final Uri url = Uri.parse(apiUrl);
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(fcmData),
      );

      if (response.statusCode == 200) {
        log('Success sending data');
      } else {
        log('Failed to send data: ${response.statusCode}');
      }
      return json.decode(response.body);
    } catch (err) {
      log("Error sending data to backend: $err");
    }
  }

  Future<bool?> verifyLatestFCMToken(User user, String fcmToken) async {
    try {
      Map<String, dynamic> fcmData = {'uid': user.uid, 'fcmToken': fcmToken};
      final String apiUrl =
          '${dotenv.env['API_URL']}/auth/verifyLatestFCMToken';
      final Uri url = Uri.parse(apiUrl);
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(fcmData),
      );
      print('ini response $response');
      if (response.statusCode == 200) {
        log('Success sending data');
      } else {
        log('Failed to send data: ${response.statusCode}');
      }
      return json.decode(response.body);
    } catch (err) {
      log("Error sending data to backend: $err");
    }
  }

  Future<String?> checkUserDataFromBackend({
    required User user,
    required BuildContext context,
  }) async {
    try {
      final String apiUrl = '${dotenv.env['API_URL']}/auth/login';
      final Uri url = Uri.parse(apiUrl);

      Map<String, String> userData = {'uid': user.uid};
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(userData),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        log(responseData['message']);

        if (responseData.containsKey("redirectTo")) {
          String redirectTo = responseData["redirectTo"];
          return redirectTo;
        }
      } else {
        log('Failed to send data: ${response.statusCode}');
      }
    } catch (e) {
      log("Error sending data to backend: $e");
    }
    return null;
  }

  Future<void> createUserDataToBackend({
    required User user,
    String? name,
  }) async {
    try {
      print('test');
      // Siapkan data yang ingin dikirim ke backend
      Map<String, String> userData = {
        'uid': user.uid,
        'name': name ?? user.displayName ?? 'Pengguna',
        'email': user.email ?? '',
        'profilePicture':
            user.photoURL ??
            "https://drive.google.com/uc?export=view&id=1-oEUxEx8VloOsPHnfi34tntp2c8mvAm9",
        // nek providerId nya password, brarti pake emailandpassword (non google)
        'providerId':
            user.providerData.isNotEmpty
                ? user.providerData.first.providerId
                : 'email',
      };
      // Endpoint API backend Anda
      final String apiUrl = '${dotenv.env['API_URL']}/auth/register';
      final Uri url = Uri.parse(apiUrl);
      // Kirim data menggunakan POST request
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(userData),
      );

      // Cek apakah request berhasil
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        log(responseData['message']);
      } else {
        log('Failed to send data: ${response.statusCode}');
      }
    } catch (e) {
      log("Error sending data to backend: $e");
    }
  }

  Future<Map<String, dynamic>?> getProfileData(User user) async {
    try {
      Map<String, dynamic> data = {'uid': user.uid};
      final String apiUrl = '${dotenv.env['API_URL']}/auth/getProfile';
      final Uri url = Uri.parse(apiUrl);

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(data),
      );

      if (response.statusCode == 200) {
        log('Success sending data');
      } else {
        log('Failed to send data: ${response.statusCode}');
      }
      return json.decode(response.body);
    } catch (err) {
      log("Error sending data to backend: $err");
    }
  }

  Future<Map<String, dynamic>?> updateProfileData(
    User user,
    Map<String, dynamic> fieldsToUpdate,
  ) async {
    try {
      Map<String, dynamic> requestBody = {
        'uid': user.uid,
        ...fieldsToUpdate, // hanya field yang diubah
      };
      final String apiUrl = '${dotenv.env['API_URL']}/auth/updateProfile';
      final Uri url = Uri.parse(apiUrl);

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(requestBody),
      );
      print(response.body);

      if (response.statusCode == 200) {
        log('Success sending data');
      } else {
        log('Failed to send data: ${response.statusCode}');
      }
      return json.decode(response.body);
    } catch (err) {
      log("Error sending data to backend: $err");
    }
  }

  Future<void> signout() async {
    try {
      await _auth.signOut();
      await GoogleSignIn().signOut();
    } catch (e) {
      log("Something went wrong : $e");
    }
  }
}
