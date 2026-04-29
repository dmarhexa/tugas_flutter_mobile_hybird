import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: ListUserDataPage(),
    );
  }
}

//Database Helper untuk mengelola operasi CRUD dengan SQLite
class DatabaseHelper {
  static Database? _database;

  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  static Future<Database> _initDB() async {
    String path = p.join(await getDatabasesPath(), 'user_data.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE users (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            nama TEXT,
            umur INTEGER  
          )
        ''');
      },
    );
  }

  //  CREATE
  static Future<int> insertUser(UserModel user) async {
    final db = await database;
    Map<String, dynamic> userData = user.toJson();
    return await db.insert(
      'users',
      userData,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  //  READ
  static Future<List<UserModel>> getData() async {
    final db = await database;
    List<Map<String, dynamic>> users = await db.query('users');
    List<UserModel> userList = users
        .map((user) => UserModel.fromJson(user))
        .toList();
    return userList;
  }

  //  UPDATE
  static Future<int> updateUser(UserModel user) async {
    final db = await database;

    var userData = user.toJson()..remove('id');

    return await db.update(
      'users',
      userData,
      where: 'id = ?',
      whereArgs: [user.id],
    );
  }

  // DELETE
  static Future<int> deleteUser(int id) async {
    final db = await database;
    return await db.delete('users', where: 'id = ?', whereArgs: [id]);
  }
}

class ListUserDataPage extends StatefulWidget {
  const ListUserDataPage({super.key});

  @override
  State<ListUserDataPage> createState() => _ListUserDataPageState();
}

class UserModel {
  int? id;
  String nama = "";
  int umur = 0;

  UserModel({this.id, required this.nama, required this.umur});

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(id: json['id'], nama: json['nama'], umur: json['umur']);
  }

  //convert dari model ke map
  Map<String, dynamic> toJson() {
    return {'id': id, 'nama': nama, 'umur': umur};
  }
}

class _ListUserDataPageState extends State<ListUserDataPage> {
  final TextEditingController _namaController = TextEditingController();
  final TextEditingController _umurController = TextEditingController();

  List<UserModel> userList = [];

  @override
  void initState() {
    super.initState();
    _reloadData();
  }

  void _reloadData() async {
    var data = await DatabaseHelper.getData();
    setState(() => userList = data);
  }

  void _form(int? id) {
    if (id != null) {
      var user = userList.firstWhere((user) => user.id == id);
      _namaController.text = user.nama;
      _umurController.text = user.umur.toString();
    } else {
      _namaController.clear();
      _umurController.clear();
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          20,
          20,
          MediaQuery.of(context).viewInsets.bottom + 50,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _namaController,
              decoration: InputDecoration(hintText: "Nama"),
            ),
            TextField(
              controller: _umurController,
              decoration: InputDecoration(hintText: "Umur"),
              keyboardType: TextInputType.number,
            ),
            ElevatedButton(
              onPressed: () => _save(
                id,
                _namaController.text,
                int.parse(_umurController.text),
              ),
              child: Text(id == null ? "Tambah" : "Update"),
            ),
          ],
        ),
      ),
    );
  }

  void _save(int? id, String nama, int umur) async {
    if (id != null) {
      await DatabaseHelper.updateUser(
        UserModel(id: id, nama: nama, umur: umur),
      );
      setState(() {
        int index = userList.indexWhere((user) => user.id == id);
        if (index != -1) {
          userList[index] = UserModel(id: id, nama: nama, umur: umur);
        }
      });
    } else {
      var newUser = UserModel(nama: nama, umur: umur);
      await DatabaseHelper.insertUser(newUser);
    }

    _reloadData();
    Navigator.pop(context);
  }

  void _delete(int id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Konfirmasi Hapus"),
        content: Text("Apakah Anda yakin ingin menghapus data ini?"),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: Text("Batal"),
          ),
          IconButton(
            onPressed: () async {
              DatabaseHelper.deleteUser(id);
              setState(() {
                userList.removeWhere((user) => user.id == id);
              });
              Navigator.pop(context);
            },
            icon: Icon(Icons.delete, color: Colors.red),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('List User Data')),
      body: ListView.builder(
        itemCount: userList.length,
        itemBuilder: (context, index) => ListTile(
          title: Text(userList[index].nama),
          subtitle: Text("Umur ${userList[index].umur} Tahun"),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                onPressed: () => _form(userList[index].id),
                icon: Icon(Icons.edit),
              ),
              IconButton(
                onPressed: () => _delete(userList[index].id!),
                icon: Icon(Icons.delete, color: Colors.red),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _form(null),
        child: Icon(Icons.add),
      ),
    );
  }
}
