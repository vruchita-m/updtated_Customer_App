import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:service_mitra/config/colors/colors.dart';
import 'package:service_mitra/config/routes/routes_name.dart';
import 'package:service_mitra/config/share_preferences/preferences.dart';
import '../../../constant/api/apis.dart';
import '../../../constant/utils.dart';

class ForgotPasswordOtpRepositry {
  ForgotPasswordOtpRepositry();

  Future<String> submitOTP({
    required String email,
    required String otp,
    required BuildContext context,
  }) async {
    final url = Uri.parse(AppConstants.verifyOTP);

    final headers = {
      'Content-Type': 'application/json',
      'accept': "application/json",
      'Authorization': 'Bearer ${Preference.getString(PrefKeys.token)}',
    };

    final body = jsonEncode({
      'email': email,
      'otp': otp,
    });

    debugPrint("Request URL: $url");
    debugPrint("Request Headers: $headers");
    debugPrint("Request Body: $body");

    try {
      final response = await http.post(url, headers: headers, body: body);
      debugPrint("Response Status Code: ${response.statusCode}");
      debugPrint("Response Body: ${response.body}");

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final String message =
            responseData["message"] ?? "OTP verified successfully";

        return message;
      } else if (response.statusCode == 401) {
        await Preference.clear();
        await Fluttertoast.showToast(
          msg: "Your account has been deleted.",
          gravity: ToastGravity.BOTTOM,
          backgroundColor: AppColors.colred,
          textColor: AppColors.whitecol,
        );
        await Navigator.pushNamedAndRemoveUntil(
          context,
          RoutesName.login,
          (route) => false,
        );
        throw Exception("Unauthorized");
      } else {
        debugPrint("check else goes");
        await ApiUtils.manageException(response, context);
        throw Exception('OTP failed');
      }
    } catch (e) {
      debugPrint("Error: $e");

      debugPrint("check catch ${e.toString()}");
      if (e is http.Response) {
        await ApiUtils.manageException(e, context);
      }
      throw Exception("OTP failed. Please try again.");
    }
  }
}
