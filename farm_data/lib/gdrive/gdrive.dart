import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:googleapis_auth/googleapis_auth.dart' as auth;
import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:googleapis/sheets/v4.dart' as sheets;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:path/path.dart' as p;

const _clientId =
    "455278327943-k1o8o9nm6bs41trsbppuoaof19c136eb.apps.googleusercontent.com";
const _scopes = ['https://www.googleapis.com/auth/drive.file'];

class SecureStorage {
  final storage = FlutterSecureStorage();

  //Save Credentials
  Future saveCredentials(AccessToken token, String refreshToken) async {
    print(token.expiry.toIso8601String());
    await storage.write(key: "type", value: token.type);
    await storage.write(key: "data", value: token.data);
    await storage.write(key: "expiry", value: token.expiry.toString());
    await storage.write(key: "refreshToken", value: refreshToken);
  }

  //Get Saved Credentials
  Future<Map<String, dynamic>?> getCredentials() async {
    var result = await storage.readAll();
    if (result.isEmpty) return null;
    return result;
  }

  //Clear Saved Credentials
  Future clear() {
    return storage.deleteAll();
  }
}

class GoogleDrive {
  static final GoogleDrive instance = GoogleDrive._internal();
  GoogleDrive._internal();
  final storage = SecureStorage();
  //Get Authenticated Http Client
  Future<http.Client> getHttpClient() async {
    //Get Credentials
    var credentials = await storage.getCredentials();
    if (credentials == null) {
      //Needs user authentication
      var authClient = await clientViaUserConsent(
        ClientId(_clientId),
        _scopes,
        (url) {
          //Open Url in Browser
          launch(url);
        },
      );
      //Save Credentials
      await storage.saveCredentials(
        authClient.credentials.accessToken,
        authClient.credentials.refreshToken!,
      );
      return authClient;
    } else {
      print(credentials["expiry"]);
      //Already authenticated
      return authenticatedClient(
        http.Client(),
        AccessCredentials(
          AccessToken(
            credentials["type"],
            credentials["data"],
            DateTime.tryParse(credentials["expiry"])!,
          ),
          credentials["refreshToken"],
          _scopes,
        ),
      );
    }
  }

  // check if the directory forlder is already available in drive , if available return its id
  // if not available create a folder in drive and return id
  //   if not able to create id then it means user authetication has failed
  Future<String?> _getFolderId(
    drive.DriveApi driveApi,
    String folderName,
  ) async {
    final mimeType = "application/vnd.google-apps.folder";

    try {
      final found = await driveApi.files.list(
        q: "mimeType = '$mimeType' and name = '$folderName'",
        $fields: "files(id, name)",
      );
      final files = found.files;
      if (files == null) {
        print("Sign-in first Error");
        return null;
      }

      // The folder already exists
      if (files.isNotEmpty) {
        return files.first.id;
      }

      // Create a folder
      drive.File folder = drive.File();
      folder.name = folderName;
      folder.mimeType = mimeType;
      final folderCreation = await driveApi.files.create(folder);
      print("Folder ID: ${folderCreation.id}");

      return folderCreation.id;
    } catch (e) {
      print(e);
      return null;
    }
  }

  uploadFileToGoogleDrive(List<File?> files, String folderName) async {
    var client = await getHttpClient();
    var gdrive = drive.DriveApi(client);
    String? folderId = await _getFolderId(gdrive, folderName);
    if (folderId == null) {
      print("Sign-in first Error");
    } else {
      drive.File fileToUpload = drive.File();
      fileToUpload.parents = [folderId];
      for (var file in files) {
        fileToUpload.name = p.basename(file!.absolute.path);
        var response = await gdrive.files.create(
          fileToUpload,
          uploadMedia: drive.Media(file.openRead(), file.lengthSync()),
        );
        print(response);
      }
      ;
    }
  }
}
