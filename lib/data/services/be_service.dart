import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart'; // Import flutter_dotenv
import 'package:http_parser/http_parser.dart'; // untuk MediaType
import 'package:mime/mime.dart'; // untuk detect MIME type

class BackendService {
  Future<List<Map<String, dynamic>>?> getListOfConnection(User user) async {
    try {
      // Siapkan data yang ingin dikirim ke backend
      Map<String, dynamic> userData = {'uid': user.uid};

      final String apiUrl = '${dotenv.env['API_URL']}/user/getListOfConnection';
      final Uri url = Uri.parse(apiUrl);

      // Mengirimkan POST request ke backend
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(userData),
      );

      // Debugging untuk response body
      print(response.body);

      // Cek status code dari response
      if (response.statusCode == 200) {
        log('Success sending data');

        // Decode body response yang berisi list objek
        final List<dynamic> decodedResponse = json.decode(response.body);

        // Cek apakah data yang diterima benar sesuai format yang diinginkan
        if (decodedResponse is List) {
          // Jika list, konversikan ke list of map
          return decodedResponse.map((e) => e as Map<String, dynamic>).toList();
        } else {
          log('Data format tidak sesuai');
          return null;
        }
      } else {
        log('Failed to send data: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      log("Error sending data to backend: $e");
      return null;
    }
  }

  Future<Map<String, dynamic>?> sendConnectionAddedNotification(
    User user,
    String toEmail,
  ) async {
    try {
      // Siapkan data yang ingin dikirim ke backend
      Map<String, dynamic> userData = {
        'uid': user.uid,
        'to': toEmail,
        'from': user.email,
      };

      final String apiUrl =
          '${dotenv.env['API_URL']}/user/handleAddedConnection';
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

  Future<Map<String, dynamic>?> sendDeletedConnection(
    User user,
    String toEmail,
  ) async {
    try {
      // Siapkan data yang ingin dikirim ke backend
      Map<String, dynamic> userData = {'uid': user.uid, 'toEmail': toEmail};

      final String apiUrl =
          '${dotenv.env['API_URL']}/user/handleDeleteConnection';
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

  Future<Map<String, dynamic>?> sendPhotoToBeScanned(
    User user,
    File imageFile,
  ) async {
    try {
      final String apiUrl =
          '${dotenv.env['API_URL']}/user/sendScannedPhotoResult';
      final Uri url = Uri.parse(apiUrl);

      final mimeType = lookupMimeType(imageFile.path);
      final mimeSplit = mimeType!.split('/');

      var request =
          http.MultipartRequest('POST', url)
            ..fields['uid'] = user.uid
            ..files.add(
              await http.MultipartFile.fromPath(
                'photo', // <- nama field yang harus sama dengan upload.single('photo') di BE
                imageFile.path,
                contentType: MediaType(mimeSplit[0], mimeSplit[1]),
              ),
            );

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      if (response.statusCode == 200) {
        final scanResult = json.decode(response.body);
        return scanResult;
      } else {
        print('Upload failed: ${response.statusCode}');
      }
    } catch (e) {
      print('Error during upload: $e');
    }
    return null;
  }

  Future<String?> sendIsDrinkStatusIsTrue(User user, String date) async {
    try {
      Map<String, dynamic> data = {'uid': user.uid, 'date': date};

      final String apiUrl =
          '${dotenv.env['API_URL']}/user/changeDrinkStatusToTrue';
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

  Future<List<dynamic>?> getMealRecommendation(User user) async {
    try {
      Map<String, dynamic> data = {'uid': user.uid};

      final String apiUrl =
          '${dotenv.env['API_URL']}/user/getMealRecommendation';
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

  Future<List<dynamic>?> uploadPhotoAndFoodComponent(
    User user,
    String mealTime,
    List<dynamic> foodComponent,
    File photoFile,
  ) async {
    try {
      final String apiUrl =
          '${dotenv.env['API_URL']}/user/uploadPhotoAndFoodComponent';
      final Uri url = Uri.parse(apiUrl);

      final mimeType = lookupMimeType(photoFile.path);
      final mimeSplit = mimeType?.split('/') ?? ['image', 'jpeg']; // default

      final request =
          http.MultipartRequest('POST', url)
            ..fields['uid'] = user.uid
            ..fields['mealTime'] = mealTime
            ..fields['foodComponent'] = jsonEncode({'makanan': foodComponent})
            ..files.add(
              await http.MultipartFile.fromPath(
                'photo', // <== ini harus sesuai dengan upload.single('photo')
                photoFile.path,
                contentType: MediaType(mimeSplit[0], mimeSplit[1]),
              ),
            );

      final response = await request.send();

      if (response.statusCode == 200) {
        final responseData = await response.stream.bytesToString();
        log('Upload success: $responseData');
        return json.decode(responseData);
      } else {
        final error = await response.stream.bytesToString();
        log('Upload failed: $error');
      }
    } catch (err) {
      log('Upload error: $err');
    }

    return null;
  }

  Future<Map<String, dynamic>?> getDataOnSpecificMonth(
    User user,
    String year_month,
  ) async {
    try {
      Map<String, dynamic> data = {'uid': user.uid, "year_month": year_month};

      final String apiUrl =
          '${dotenv.env['API_URL']}/user/getDataOnSpecificMonth';
      final Uri url = Uri.parse(apiUrl);

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(data),
      );

      if (response.statusCode == 200) {
        log('Month Success sending data');
      } else {
        log('Month Failed to send data: ${response.statusCode}');
      }
      print(response.body);
      return json.decode(response.body);
    } catch (err) {
      log("Month Error sending data to backend: $err");
    }
  }

  Future<Map<String, dynamic>?> getDataOnSpecificDate(
    User user,
    String year_month_date,
  ) async {
    try {
      Map<String, dynamic> data = {
        'uid': user.uid,
        "year_month_date": year_month_date,
      };

      final String apiUrl =
          '${dotenv.env['API_URL']}/user/getDataOnSpecificDate';
      final Uri url = Uri.parse(apiUrl);

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(data),
      );

      if (response.statusCode == 200) {
        log('Date Success sending data');
      } else {
        log('Date Failed to send data: ${response.statusCode}');
      }
      return json.decode(response.body);
    } catch (err) {
      log("Date Error sending data to backend: $err");
    }
  }

  Future<Map<String, dynamic>?> sendGerdTriggerInformation(
    User user,
    // current year_month_date
    String year_month_date,
  ) async {
    try {
      Map<String, dynamic> data = {'uid': user.uid, "date": year_month_date};

      final String apiUrl =
          '${dotenv.env['API_URL']}/user/sendGerdTriggererInformation';
      final Uri url = Uri.parse(apiUrl);

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(data),
      );

      if (response.statusCode == 200) {
        log('Success sending gerd trigger data');
      } else {
        log('Failed to send gerd trigger data : ${response.statusCode}');
      }
      print("test ${response.body}");
      return json.decode(response.body);
    } catch (err) {
      log("Date Error sending data to backend: $err");
    }
  }

  Future<String?> sendDailyGerdReport(
    User user,
    String date,
    int gerdCount,
  ) async {
    try {
      Map<String, dynamic> questionData = {
        'uid': user.uid,
        'date': date,
        'gerdCount': gerdCount,
      };
      final String apiUrl = '${dotenv.env['API_URL']}/user/sendDailyGerdReport';
      final Uri url = Uri.parse(apiUrl);

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(questionData),
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

  Future<Map<String, dynamic>?> chatBotResponse(
    User user,
    String question,
  ) async {
    try {
      Map<String, dynamic> questionData = {
        'uid': user.uid,
        'question': question,
      };
      final String apiUrl = '${dotenv.env['API_URL']}/user/chatbotResponse';
      final Uri url = Uri.parse(apiUrl);

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(questionData),
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

  Future<List<dynamic>?> loadNearbyRestaurant(
    User user,
    String mealName,
    String position, //latitude longitude
  ) async {
    try {
      Map<String, dynamic> questionData = {
        'uid': user.uid,
        'mealName': mealName,
        'position': position,
      };
      final String apiUrl =
          '${dotenv.env['API_URL']}/user/getRestaurantRecommendation';
      final Uri url = Uri.parse(apiUrl);
      print('test');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(questionData),
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

  Future<List<dynamic>?> loadNotificationInApps(User user) async {
    try {
      Map<String, dynamic> questionData = {'uid': user.uid};
      final String apiUrl =
          '${dotenv.env['API_URL']}/user/getListOfNotification';
      final Uri url = Uri.parse(apiUrl);

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(questionData),
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

  Future<Map<String, dynamic>?> getChatHistory(User user) async {
    try {
      Map<String, dynamic> questionData = {'uid': user.uid};
      final String apiUrl = '${dotenv.env['API_URL']}/user/getChatHistory';
      final Uri url = Uri.parse(apiUrl);

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(questionData),
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

  Future<Map<String, dynamic>?> getBadgeInformation(User user) async {
    try {
      Map<String, dynamic> badgeData = {'uid': user.uid};
      final String apiUrl = '${dotenv.env['API_URL']}/user/sendBadgeData';
      final Uri url = Uri.parse(apiUrl);

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(badgeData),
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
}
