import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;


class FarmInfoScreen extends StatefulWidget {
  @override
  _FarmInfoScreenState createState() => _FarmInfoScreenState();
}

class _FarmInfoScreenState extends State<FarmInfoScreen> {
  List<Map<String, dynamic>> farms = [];

  @override
  void initState() {
    super.initState();
    _loadFarms();
  }

  Future<void> _loadFarms() async {
    farms = await DatabaseHelper.instance.getFarms();
    setState(() {});
  }

  Future<void> _editFarm(Map<String, dynamic> farm) async {
    await showDialog(
      context: context,
      builder: (context) => FarmDialog(
        farm: farm,
        onSave: (updatedFarm) async {
          await DatabaseHelper.instance.updateFarm(updatedFarm);
          await _loadFarms();
        },
      ),
    );
  }

  Future<void> _addFarm() async {
    await showDialog(
      context: context,
      builder: (context) => FarmDialog(
        onSave: (newFarm) async {
          await DatabaseHelper.instance.insertFarm(newFarm);
          await _loadFarms();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("농가 관리")),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: [
                  DataColumn(label: Text("농가명")),
                  DataColumn(label: Text("작물명")),
                  DataColumn(label: Text("지난 조사일")),
                  DataColumn(label: Text("주소")),
                  DataColumn(label: Text("편집")),
                ],
                rows: farms.map((farm) {
                  return DataRow(cells: [
                    DataCell(Text(farm['name'])),
                    DataCell(Text(farm['crop'])),
                    DataCell(Text(farm['lastSurveyDate'] ?? "없음")),
                    DataCell(Text(farm['address'])),
                    DataCell(
                      IconButton(
                        icon: Icon(Icons.edit),
                        onPressed: () => _editFarm(farm),
                      ),
                    ),
                  ]);
                }).toList(),
              ),
            ),
          ),
          ElevatedButton(
            onPressed: _addFarm,
            child: Text("농가 추가"),
          ),
        ],
      ),
    );
  }
}

/// 📌 농가 정보 입력/수정 다이얼로그
class FarmDialog extends StatefulWidget {
  final Map<String, dynamic>? farm;
  final Function(Map<String, dynamic>) onSave;

  FarmDialog({this.farm, required this.onSave});

  @override
  _FarmDialogState createState() => _FarmDialogState();
}

class _FarmDialogState extends State<FarmDialog> {
  final _formKey = GlobalKey<FormState>();
  String? name, crop, address;
  final List<String> crops = ["토마토", "파프리카", "사과", "배추", "콩"];

  @override
  void initState() {
    super.initState();
    if (widget.farm != null) {
      name = widget.farm!['name'];
      crop = widget.farm!['crop'];
      address = widget.farm!['address'];
    }
  }

  void _save() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      widget.onSave({
        'id': widget.farm?['id'],
        'name': name,
        'crop': crop,
        'lastSurveyDate': widget.farm?['lastSurveyDate'] ??
            DateFormat('yyyy-MM-dd').format(DateTime.now()),
        'address': address,
      });
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.farm == null ? "농가 추가" : "농가 수정"),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              initialValue: name,
              decoration: InputDecoration(labelText: "농가명"),
              validator: (value) => value!.isEmpty ? "농가명을 입력하세요" : null,
              onSaved: (value) => name = value,
            ),
            DropdownButtonFormField<String>(
              value: crop,
              decoration: InputDecoration(labelText: "작물명"),
              items: crops.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
              onChanged: (value) => setState(() => crop = value),
              validator: (value) => value == null ? "작물명을 선택하세요" : null,
            ),
            TextFormField(
              initialValue: address,
              decoration: InputDecoration(labelText: "주소"),
              validator: (value) => value!.isEmpty ? "주소를 입력하세요" : null,
              onSaved: (value) => address = value,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: Text("취소")),
        ElevatedButton(onPressed: _save, child: Text("저장")),
      ],
    );
  }
}

/// 📌 SQLite 데이터베이스 관리
class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<void> initDatabase() async {
    if (_database != null) return;

    String path = p.join(await getDatabasesPath(), 'farm.db');
    _database = await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE farms (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            crop TEXT NOT NULL,
            lastSurveyDate TEXT,
            address TEXT NOT NULL
          )
        ''');
      },
    );
  }

  Future<List<Map<String, dynamic>>> getFarms() async {
    final db = _database!;
    return await db.query('farms');
  }

  Future<void> insertFarm(Map<String, dynamic> farm) async {
    final db = _database!;
    await db.insert('farms', farm);
  }

  Future<void> updateFarm(Map<String, dynamic> farm) async {
    final db = _database!;
    await db.update(
      'farms',
      farm,
      where: 'id = ?',
      whereArgs: [farm['id']],
    );
  }
}
