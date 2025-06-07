import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

// Model Todo
class Todo {
  final int id;
  final String judul;
  final bool selesai;

  Todo({required this.id, required this.judul, required this.selesai});

  factory Todo.fromJson(Map<String, dynamic> json) {
    return Todo(
      id: json['id'],
      judul: json['title'],
      selesai: json['completed'],
    );
  }
}

void main() {
  runApp(const AplikasiSaya());
}

class AplikasiSaya extends StatelessWidget {
  const AplikasiSaya({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Daftar Kegiatan',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const HalamanDaftarTodo(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class HalamanDaftarTodo extends StatefulWidget {
  const HalamanDaftarTodo({super.key});

  @override
  HalamanDaftarTodoState createState() => HalamanDaftarTodoState();
}

class HalamanDaftarTodoState extends State<HalamanDaftarTodo> {
  late Future<List<Todo>> masaDepanTodos;
  List<Todo> semuaTodos = [];
  List<Todo> todosTampil = [];

  String filter = 'Semua';
  String pencarian = '';
  final TextEditingController _controllerCari = TextEditingController();

  @override
  void initState() {
    super.initState();
    masaDepanTodos = ambilTodos();
  }

  Future<List<Todo>> ambilTodos() async {
    try {
      final response = await http.get(Uri.parse('https://jsonplaceholder.typicode.com/todos/'));
      if (response.statusCode == 200) {
        List<dynamic> dataJson = json.decode(response.body);
        List<Todo> daftarTodo = dataJson.map((item) => Todo.fromJson(item)).toList();
        setState(() {
          semuaTodos = daftarTodo;
          terapkanFilter();
        });
        return daftarTodo;
      } else {
        throw Exception('Gagal memuat data. Kode status: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Terjadi kesalahan: $e');
    }
  }

  void muatUlangData() {
    setState(() {
      masaDepanTodos = ambilTodos();
    });
  }

  void terapkanFilter() {
    List<Todo> hasilFilter = semuaTodos;
    if (filter == 'Selesai') {
      hasilFilter = hasilFilter.where((todo) => todo.selesai).toList();
    } else if (filter == 'Belum Selesai') {
      hasilFilter = hasilFilter.where((todo) => !todo.selesai).toList();
    }
    if (pencarian.isNotEmpty) {
      hasilFilter = hasilFilter
          .where((todo) => todo.judul.toLowerCase().contains(pencarian.toLowerCase()))
          .toList();
    }
    setState(() {
      todosTampil = hasilFilter;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Daftar Kegiatan'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: muatUlangData,
            tooltip: 'Muat Ulang',
          ),
        ],
      ),
      body: FutureBuilder<List<Todo>>(
        future: masaDepanTodos,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, size: 50, color: Colors.red),
                  const SizedBox(height: 10),
                  Text('Warning : ${snapshot.error}'),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: muatUlangData,
                    child: const Text('Coba Lagi'),
                  ),
                ],
              ),
            );
          } else {
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(10),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _controllerCari,
                      decoration: InputDecoration(
                        hintText: 'Cari kegiatan...',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: pencarian.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  _controllerCari.clear();
                                  pencarian = '';
                                  terapkanFilter();
                                },
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                      ),
                      onChanged: (nilai) {
                        pencarian = nilai;
                        terapkanFilter();
                      },
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: DropdownButton<String>(
                    value: filter,
                    isExpanded: true,
                    items: <String>['Semua', 'Selesai', 'Belum Selesai'].map((String nilai) {
                      return DropdownMenuItem<String>(
                        value: nilai,
                        child: Text('Filter: $nilai'),
                      );
                    }).toList(),
                    onChanged: (nilai) {
                      if (nilai != null) {
                        filter = nilai;
                        terapkanFilter();
                      }
                    },
                  ),
                ),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () async {
                      muatUlangData();
                    },
                    child: todosTampil.isEmpty
                        ? const Center(child: Text('Tidak ada data yang sesuai'))
                        : ListView.builder(
                            padding: const EdgeInsets.all(8),
                            itemCount: todosTampil.length,
                            itemBuilder: (context, index) {
                              final todo = todosTampil[index];
                              final isGanjil = todo.id % 2 != 0;

                              return Container(
                                margin: const EdgeInsets.symmetric(vertical: 6),
                                decoration: BoxDecoration(
                                  color: isGanjil ? Colors.lightBlue[50] : Colors.orange[50],
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.grey.withOpacity(0.2),
                                      blurRadius: 5,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.symmetric(
                                      vertical: 10, horizontal: 16),
                                  leading: CircleAvatar(
                                    backgroundColor:
                                        todo.selesai ? Colors.green : Colors.orange,
                                    child: Icon(
                                      todo.selesai ? Icons.thumb_up : Icons.timelapse,
                                      color: Colors.white,
                                    ),
                                  ),
                                  title: Text(
                                    todo.judul,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blueGrey[800],
                                    ),
                                  ),
                                  subtitle: Row(
                                    children: [
                                      Icon(
                                        todo.selesai
                                            ? Icons.check
                                            : Icons.hourglass_bottom,
                                        size: 16,
                                        color: todo.selesai ? Colors.green : Colors.red,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        todo.selesai
                                            ? 'Selesai mi tawwa'
                                            : 'Belumpi Selesai kerjanya',
                                        style: TextStyle(
                                          color: todo.selesai
                                              ? Colors.green[700]
                                              : Colors.red[700],
                                        ),
                                      ),
                                    ],
                                  ),
                                  trailing: Text(
                                    '#${todo.id}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ),
              ],
            );
          }
        },
      ),
    );
  }
}
