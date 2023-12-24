// ignore_for_file: use_build_context_synchronously

import 'dart:convert';
import 'dart:io';

import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../../ui/widgets/cstm_snackbar.dart';
import '../../utils/config/config.dart';
import '../models/user_model.dart';
import '../models/worker_model.dart';
import '../providers/currentuser_provider.dart';

class UserService {
  Future<void> uploadKYC({
    required BuildContext context,
    required String dob,
    required String gender,
    required File citizenship,
    required File? paymentQr,
    required String? job,
  }) async {
    if (Provider.of<CurrentUser>(context, listen: false)
        .user
        .address!
        .isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        CstmSnackBar(
          text: 'Please set your location!',
          type: 'error',
        ),
      );
      return;
    } else {
      String id = Provider.of<CurrentUser>(context, listen: false).user.id;

      final cloudinary = CloudinaryPublic('bookabahun', 'ch37wxpt');

      final citizenResult = await cloudinary.uploadFile(
        CloudinaryFile.fromFile(
          citizenship.path,
          folder: 'users/$id/citizenship',
        ),
      );

      final citizenRegBody = {
        'id': id,
        'picUrl': citizenResult.secureUrl,
        'purpose': 'Citizenship',
      };

      try {
        final response = await http.post(
          Uri.parse(uploadPictureApi),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(citizenRegBody),
        );
        print(response.statusCode);

        if (response.statusCode != 200) {
          ScaffoldMessenger.of(context).showSnackBar(
            CstmSnackBar(
              text: response.body,
              type: 'error',
            ),
          );
          return;
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          CstmSnackBar(
            text: e.toString(),
            type: 'error',
          ),
        );
      }

      if (paymentQr != null) {
        final paymentQrResult = await cloudinary.uploadFile(
          CloudinaryFile.fromFile(
            paymentQr.path,
            folder: 'users/$id/paymentQR',
          ),
        );

        final paymentQrRegBody = {
          'id': id,
          'picUrl': paymentQrResult.secureUrl,
          'purpose': 'PaymentQR',
        };

        try {
          final response = await http.post(
            Uri.parse(uploadPictureApi),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(paymentQrRegBody),
          );

          if (response.statusCode != 200) {
            ScaffoldMessenger.of(context).showSnackBar(
              CstmSnackBar(
                text: response.body,
                type: 'error',
              ),
            );
            return;
          }
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            CstmSnackBar(
              text: e.toString(),
              type: 'error',
            ),
          );
        }
      }

      try {
        final regBody = {
          'id': id,
          'dob': dob,
          'gender': gender,
          'job': job,
          'latitude':
              Provider.of<CurrentUser>(context, listen: false).user.latitude,
          'longitude':
              Provider.of<CurrentUser>(context, listen: false).user.longitude,
          'address':
              Provider.of<CurrentUser>(context, listen: false).user.address,
        };

        final response = await http.patch(
          Uri.parse('$uploadKYCApi/$id'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(regBody),
        );

        if (response.statusCode == 200) {
          var jsonResponse = jsonDecode(response.body);
          ScaffoldMessenger.of(context).showSnackBar(
            CstmSnackBar(
              text: 'KYC Updated.',
              type: 'success',
            ),
          );
          UserModel userInfo = UserModel.fromJson(jsonResponse["user"]);
          context.read<CurrentUser>().setUser(userInfo);

          if (jsonResponse["worker"] != null) {
            WorkerModel workerInfo =
                WorkerModel.fromJson(jsonResponse["worker"]);
            context.read<CurrentUser>().setWorker(workerInfo);
          }
        } else {
          print(response.body);
          ScaffoldMessenger.of(context).showSnackBar(
            CstmSnackBar(
              text: response.body,
              type: 'error',
            ),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          CstmSnackBar(
            text: e.toString(),
            type: 'error',
          ),
        );
      }
    }
  }
}
