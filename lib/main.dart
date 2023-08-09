import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

void main() {
  runApp(const ToDoList());
}

class ToDoList extends StatefulWidget {
  const ToDoList({Key? key}) : super(key: key);

  @override
  State<ToDoList> createState() => _ToDoListState();
}

class _ToDoListState extends State<ToDoList> {
  final _toDoController = TextEditingController();
  List _toDoList = [];
  late Map<String, dynamic> _lastRemoved;
  late int _lastRemovedPosition;

  @override
  void initState() {
    super.initState();

    _readData().then((data) {
      setState(() {
        _toDoList = json.decode(data!);
      });
    });
  }

  void _addToDO() {
    setState(() {
      Map<String, dynamic> newToDo = {};
      newToDo["title"] = _toDoController.text;
      _toDoController.text = "";
      newToDo["ok"] = false;
      _toDoList.add(newToDo);
      _saveData();
    });
  }

  Future<void> _refresh() async {
    await Future.delayed(const Duration(seconds: 1));
    setState(() {
      _toDoList.sort((a, b) {
        if (a["ok"] && !b["ok"]) {
          return 1;
        } else if (!a["ok"] && b["ok"]) {
          return -1;
        } else {
          return 0;
        }
      });
      _saveData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text("Lista de Tarefas"),
          backgroundColor: Colors.teal,
          centerTitle: true,
        ),
        body: Column(
          children: <Widget>[
            Container(
              padding: const EdgeInsets.fromLTRB(16, 2, 16, 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Expanded(
                    child: TextField(
                      controller: _toDoController,
                      decoration: const InputDecoration(
                        labelText: "Nova Tarefa",
                        labelStyle: TextStyle(color: Colors.teal),
                      ),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: _addToDO,
                    style:
                        ElevatedButton.styleFrom(backgroundColor: Colors.teal),
                    child: const Text("ADD"),
                  )
                ],
              ),
            ),
            Expanded(
                child: RefreshIndicator(
                    onRefresh: _refresh,
                    child: ListView.builder(
                      padding: const EdgeInsets.only(top: 10),
                      itemCount: _toDoList.length,
                      itemBuilder: buildItem,
                    )))
          ],
        ),
      ),
    );
  }

  Widget buildItem(BuildContext context, int index) {
    return Dismissible(
      background: Container(
        color: Colors.red,
        child: const Align(
          alignment: Alignment(-0.9, 0.0),
          child: Icon(
            Icons.delete,
            color: Colors.white,
          ),
        ),
      ),
      direction: DismissDirection.startToEnd,
      key: Key(DateTime.now().microsecondsSinceEpoch.toString()),
      child: CheckboxListTile(
        value: _toDoList[index]["ok"],
        onChanged: (check) {
          setState(() {
            _toDoList[index]["ok"] = check;
            _saveData();
          });
        },
        title: Text(_toDoList[index]["title"]),
        secondary: CircleAvatar(
          backgroundColor: Colors.white,
          child: Icon(
            _toDoList[index]["ok"] ? Icons.check : Icons.error,
          ),
        ),
      ),
      onDismissed: (direction) {
        setState(() {
          _lastRemoved = Map.from(_toDoList[index]);
          _lastRemovedPosition = index;
          _toDoList.removeAt(index);

          _saveData();

          final snack = SnackBar(
            content: Text("Tarefa \" ${_lastRemoved["title"]} \" removida"),
            action: SnackBarAction(
                label: "Desfazer",
                onPressed: () {
                  setState(() {
                    _toDoList.insert(_lastRemovedPosition, _lastRemoved);
                    _saveData();
                  });
                }),
            duration: const Duration(seconds: 2),
          );
          ScaffoldMessenger.of(context).removeCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(snack);
        });
      },
    );
  }

  Future<File> _getFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File("${directory.path}/data.json");
  }

  Future<File> _saveData() async {
    String data = json.encode(_toDoList);
    final file = await _getFile();
    return file.writeAsString(data);
  }

  Future<String?> _readData() async {
    try {
      final file = await _getFile();

      return file.readAsString();
    } catch (e) {
      return null;
    }
  }
}
