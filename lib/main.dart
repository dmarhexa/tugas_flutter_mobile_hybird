import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(home: ListUserDataPage());
  }
}

class ListUserDataPage extends StatefulWidget {
  const ListUserDataPage({super.key});

  @override
  State<ListUserDataPage> createState() => _ListUserDataPageState();
}

class UserModel {
  int id;
  String nama = "";
  int umur = 0;

  UserModel({required this.id, required this.nama, required this.umur});
}

class _ListUserDataPageState extends State<ListUserDataPage> {
  final TextEditingController _namaController = TextEditingController();
  final TextEditingController _umurController = TextEditingController();

  List<UserModel> userList = [
    UserModel(id: 1, nama: "Angga Dicky", umur: 30),
    UserModel(id: 2, nama: "Yudha Pras", umur: 25),
    UserModel(id: 3, nama: "Siti Nurhaliza", umur: 28),
    UserModel(id: 4, nama: "Bambang Santoso", umur: 25),
    UserModel(id: 5, nama: "Putri Ayu", umur: 22),
  ];

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
        padding: EdgeInsetsGeometry.fromLTRB(
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

  void _save(int? id, String nama, int umur) {
    if (id != null) {
      var user = userList.firstWhere((data) => data.id == id);
      setState(() {
        user.nama = nama;
        user.umur = umur;
      });
    } else {
      var nextId = userList.length + 1;
      var newUser = UserModel(id: nextId, nama: nama, umur: umur);
      setState(() {
        userList.add(newUser);
      });
    }
    Navigator.pop(context);
  }

  void _delete(int id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("KonfirmasiHapus"),
        content: Text("Apakah Anda yakin ingin menghapus data ini?"),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: Text("Batal"),
          ),
          TextButton(
            onPressed: () {
              setState(() => userList.removeWhere((data) => data.id == id));
              Navigator.pop(context);
            },
            child: Text("Hapus"),
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
              TextButton(
                onPressed: () => _form(userList[index].id),
                child: Icon(Icons.edit),
              ),
              TextButton(
                onPressed: () => _delete(userList[index].id),
                child: Icon(Icons.delete),
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
