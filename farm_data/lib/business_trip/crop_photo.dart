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
import '../gdrive/gdrive.dart';

class CropPhotoScreen extends StatefulWidget {
  @override
  _CropPhotoState createState() => _CropPhotoState();
}

class _CropPhotoState extends State<CropPhotoScreen> {
  List<File?> _photos = List.generate(4, (_) => null);
  final List<String> imageTitles = [
    "재배전경",
    "1-1 개체생장점 사진",
    "1-1 개체 마디 진행상황",
    "pH",
    "백엽상 내부",
    "온습도",
    "1 개체 근권부 사진(좌)",
    "1개체 근권부 사진(우)",
    "특이사항",
  ]; // DB에서 불러올 값
  String? selectedFarm;
  List<String> farmNames = ["김관섭", "김영록"];
  String? excelFilePath;

  Future<void> _takePhoto(int index) async {
    final pickedFile = await ImagePicker().pickImage(
      source: ImageSource.camera,
    );
    if (pickedFile != null) {
      setState(() {
        _photos[index] = File(pickedFile.path);
      });
    }
  }

  // 이미지 선택 및 업로드 함수
  Future<void> uploadCropImage() async {
    // Googledrive 클래스의 uploadImage 호출
    await GoogleDrive.instance.uploadFileToGoogleDrive(_photos, "조사사진");
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text("이미지 업로드 완료!")));
  }

  @override
  Widget build(BuildContext context) {
    double width = constraints.maxWidth;
    double height = constraints.maxHeight;

    // 그리드 항목의 크기 (예: 3x3 그리드)
    int crossAxisCount = 3; // 3열로 설정
    double itemSize = width / crossAxisCount;
    return Scaffold(
      appBar: AppBar(title: Text("조사사진 업로드")),
      body: Column(
        children: [
          DropdownButton<String>(
            value: selectedFarm,
            hint: Text("농가 선택"),
            items:
                farmNames.map((String farm) {
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
            child: LayoutBuilder(
        builder: (context, constraints) {
          // 화면 크기에 맞춰서 그리드의 항목 수를 계산합니다.
          double width = constraints.maxWidth;
          double height = constraints.maxHeight;

          // 그리드 항목의 크기 (예: 3x3 그리드)
          double itemSize = width / crossAxisCount;)
          return GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 1.0,
              ),
              itemCount: 9,
              itemBuilder: (context, index) {
                return Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // 🔹 사진 미리보기 (사진이 있으면 표시, 없으면 기본 텍스트)
                      _photos[index] != null
                          ? Image.file(
                            _photos[index]!,
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                          )
                          : Icon(Icons.image, size: 80, color: Colors.grey),

                      SizedBox(height: 10),

                      // 🔹 사진 파일명 or 기본 제목 표시
                      Text(
                        _photos[index] != null
                            ? _photos[index]!.path.split('/').last
                            : imageTitles[index],
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),

                      SizedBox(height: 10),

                      // 📸 카메라 촬영 버튼
                      ElevatedButton(
                        onPressed:
                            () => _takePhoto(index), // 특정 index에 대한 사진 촬영
                        child: Icon(Icons.camera_alt),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          SizedBox(height: 10),
          ElevatedButton(onPressed: uploadCropImage, child: Text("수정된 엑셀 업로드")),
        ],
      ),
    );
  }
}
