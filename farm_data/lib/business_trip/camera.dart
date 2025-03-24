import 'dart:io';
import 'dart:typed_data';
import 'package:farm_data/provider.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image/image.dart' as img;
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:googleapis/sheets/v4.dart' as sheets;
import 'package:googleapis_auth/googleapis_auth.dart' as auth;
import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../gdrive/gdrive.dart';

class CropPhotoScreen extends StatefulWidget {
  @override
  _CropPhotoState createState() => _CropPhotoState();
}

class _CropPhotoState extends State<CropPhotoScreen> {
  List<File?> _photos = List.generate(4, (_) => null);
  String? selectedFarm;
  List<String> farmNames = ["농가1", "농가2", "농가3"]; // DB에서 불러올 값
  String? excelFilePath;


  Future<void> _takePhoto(int index) async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.camera);
    if (pickedFile != null) {
      setState(() {
        _photos[index] = File(pickedFile.path);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final _provider = Provider.of<provider>(context);

    return Scaffold(
      appBar: AppBar(title: Text("농산물 품질 관리")),
      body: Column(
        children: [
          DropdownButton<String>(
            value: selectedFarm,
            hint: Text("농가 선택"),
            items: farmNames.map((String farm) {
              return DropdownMenuItem<String>(
                value: farm,
                child: Text(farm),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                selectedFarm = value;
              });
            },
          ),
          Expanded(
            child: GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2),
              itemCount: 4,
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () => _takePhoto(index),
                  child: Container(
                    margin: EdgeInsets.all(8.0),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                    ),
                    child: _photos[index] == null
                        ? Icon(Icons.camera_alt, size: 50)
                        : Image.file(_photos[index]!, fit: BoxFit.cover),
                  ),
                );
              },
            ),
          ),
          ElevatedButton(
            onPressed: _provider.googledrive.uploadFileToGoogleDrive(_photos),
            child: Text("Google Drive에서 엑셀 가져오기"),
          ),
          ElevatedButton(
            onPressed: (){},
            child: Text("수정된 엑셀 업로드"),
          ),
        ],
      ),);}
}
