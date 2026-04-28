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
      debugShowCheckedModeBanner:
          false, // ✅ sudah benar untuk hilangkan debug banner
      home: ListUserDataPage(),
    );
  }
}

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

  // CREATE
  static Future<int> insertUser(UserModel user) async {
    final db = await database;
    return await db.insert(
      'users',
      user.toJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // READ
  static Future<List<UserModel>> getData() async {
    final db = await database;
    List<Map<String, dynamic>> users = await db.query('users');
    return users.map((user) => UserModel.fromJson(user)).toList();
  }

  // UPDATE
  static Future<int> updateUser(UserModel user) async {
    final db = await database;

    // ❌ sebelumnya: id ikut dikirim ke update
    // ✅ sekarang id dihapus agar tidak error
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

    // ❌ sebelumnya: kirim object UserModel
    // ✅ cukup kirim id saja
    return await db.delete('users', where: 'id = ?', whereArgs: [id]);
  }
}

class ListUserDataPage extends StatefulWidget {
  const ListUserDataPage({super.key});

  @override
  State<ListUserDataPage> createState() => _ListUserDataPageState();
}

class UserModel {
  int? id; // ❌ sebelumnya wajib (required) → bikin error saat insert
  String nama;
  int umur;

  // ✅ id dibuat nullable karena auto increment dari database
  UserModel({this.id, required this.nama, required this.umur});

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(id: json['id'], nama: json['nama'], umur: json['umur']);
  }

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
        // ❌ sebelumnya: EdgeInsetsGeometry.fromLTRB (SALAH)
        // ✅ seharusnya:
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
              decoration: const InputDecoration(hintText: "Nama"),
            ),
            TextField(
              controller: _umurController,
              decoration: const InputDecoration(hintText: "Umur"),
              keyboardType: TextInputType.number,
            ),
            ElevatedButton(
              onPressed: () => _save(
                id,
                _namaController.text,
                _umurController
                    .text, // ❌ sebelumnya langsung parse → rawan crash
              ),
              child: Text(id == null ? "Tambah" : "Update"),
            ),
          ],
        ),
      ),
    );
  }

  void _save(int? id, String nama, String umurText) async {
    // ❌ sebelumnya: int.parse → bisa crash kalau kosong
    // ✅ gunakan tryParse
    int? umur = int.tryParse(umurText);

    if (nama.isEmpty || umur == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Input tidak valid")));
      return;
    }

    if (id != null) {
      await DatabaseHelper.updateUser(
        UserModel(id: id, nama: nama, umur: umur),
      );
    } else {
      await DatabaseHelper.insertUser(UserModel(nama: nama, umur: umur));
    }

    _reloadData(); // ❌ sebelumnya tidak ada → data tidak refresh
    Navigator.pop(context);
  }

  void _delete(int id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Konfirmasi Hapus"),
        content: const Text("Apakah Anda yakin ingin menghapus data ini?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Batal"),
          ),
          TextButton(
            onPressed: () async {
              await DatabaseHelper.deleteUser(id);

              setState(() {
                userList.removeWhere((user) => user.id == id);
              });

              Navigator.pop(context);
            },
            child: const Text("Hapus"),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    // ❌ sebelumnya tidak ada → bisa memory leak
    _namaController.dispose();
    _umurController.dispose();
    super.dispose();
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
                // ❌ sebelumnya pakai TextButton + Icon (kurang tepat)
                // ✅ lebih cocok IconButton
                onPressed: () => _form(userList[index].id),
                icon: const Icon(Icons.edit),
              ),
              IconButton(
                onPressed: () => _delete(userList[index].id!),
                icon: const Icon(Icons.delete),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _form(null),
        child: const Icon(Icons.add),
      ),
    );
  }
}
