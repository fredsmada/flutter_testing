import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:flutter/services.dart' show rootBundle, ByteData;

// Initial database setup
Future<Database> openPrePopulatedDatabase() async {
  var databasesPath = await getDatabasesPath();
  var path = join(databasesPath, "db.db");

  // Copy database from assets
    await Directory(dirname(path)).create(recursive: true);
    ByteData data = await rootBundle.load(join("assets", "db.db"));
    List<int> bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
    await File(path).writeAsBytes(bytes, flush: true);
  return await openDatabase(path);
}

void main() async {
  // Avoid errors caused by flutter upgrade.
  // Importing 'package:flutter/widgets.dart' is required.
  WidgetsFlutterBinding.ensureInitialized();
  
  runApp(SqliteApp());
}

class SqliteApp extends StatefulWidget {
  //const SqliteApp({Key? key}) : super(key: key);
  const SqliteApp({super.key});

  @override
  SqliteAppState createState() => SqliteAppState();
}

class SqliteAppState extends State<SqliteApp> {
  int? selectedId;
  int spot = 0;

  // State variable for the card title
  String cardTitle = '';

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FutureBuilder<List<Story>>(
                future: openPrePopulatedDatabase().then((db) async {
                  final List<Map<String, Object?>> storiesMaps = await db.query('Pages');
                  return [
                    for (final {'Number': Number as int, 'PageContent': PageContent as String, 'Heart': Heart as int}
                        in storiesMaps)
                      Story(Number: Number, PageContent: PageContent, Heart: Heart),
                  ];
                }),
                builder: (BuildContext context,
                  AsyncSnapshot<List<Story>> snapshot) {
                    if (!snapshot.hasData) {
                      return Center(child: Text('Loading...'));
                    }
                    // Set initial title
                    if (cardTitle.isEmpty) {
                      cardTitle = snapshot.data!.first.PageContent;
                    }
                    spot++;
                    return snapshot.data!.isEmpty ? Center(child: Text('No Stories in List.')) : Card(
                      color: selectedId == snapshot.data!.first.Number ? Colors.grey : Colors.white,
                      child: ListTile(
                        title: Text(cardTitle),
                        onTap: () {
                          setState(() {
                          // Change title using database row
                          spot++;
                          cardTitle = snapshot.data![spot].PageContent;

                          selectedId = snapshot.data![spot].Number;
                          });
                        },
                      ),
                    );
                  },
              ),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          child: Icon(Icons.save),
          onPressed: () async {
            setState(() {

            });
          },
        ),
      ),
    );
  }
}

class Story {
  final int Number;
  final String PageContent;
  final int Heart;

  Story({required this.Number, required this.PageContent, required this.Heart});

  // Convert a Story into a Map. The keys must correspond to the names of the
  // columns in the database.

  factory Story.fromMap(Map<String, dynamic> json) => Story(
        Number: json['Number'],
        PageContent: json['PageContent'],
        Heart: json['Heart'],
      );

  Map<String, dynamic> toMap() {
    return {
      'Number': Number,
      'PageContent': PageContent,
      'Heart': Heart,
    };
  }
  // Implement toString to make it easier to see information about
  // each story when using the print statement.
  @override
  String toString() {
    return 'Story{Number: $Number, PageContent: $PageContent, Heart: $Heart}';
  }
}