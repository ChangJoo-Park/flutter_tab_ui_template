import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:remote_api_list/models/post.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: MyHomePage(title: 'Remote List State'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);
  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  bool initialLoad = true;
  bool loading = false;
  bool showLoading = false;
  bool error = false;
  List<Post> items = [];
  String url;

  @override
  void initState() {
    _refresh();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          IconButton(
            icon: this.showLoading
                ? Icon(Icons.notifications_active)
                : Icon(Icons.notifications_off),
            onPressed: () {
              setState(() {
                this.showLoading = !this.showLoading;
              });
            },
          ),
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () {},
          ),
          IconButton(
            icon: Icon(Icons.remove),
            onPressed: () {},
          )
        ],
      ),
      body: _renderMainContent(showLoading: this.showLoading),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _refresh();
        },
        tooltip: 'Refresh',
        child: Icon(Icons.refresh),
      ),
    );
  }

  Widget _renderMainContent({showLoading = false}) {
    if (initialLoad || (loading && showLoading)) {
      return Center(child: CircularProgressIndicator());
    }

    if (error) {
      return Container(child: Text('에러'));
    }

    if (items.length == 0) {
      return Container(child: Text('자료 없음'));
    }

    if (items.length > 0) {
      return Container(child: Text('자료 있음'));
    }

    return Container();
  }

  _refresh() async {
    try {
      if (this.loading) {
        return;
      }
      setState(() {
        this.loading = true;
      });

      http.Response response = await http.get(
        'https://jsonplaceholder.typicode.com/posts',
      );
      List itemJSON = json.decode(response.body);

      setState(() {
        items = itemJSON.map((item) => Post.fromJson(item)).toList();
      });

      setState(() {
        this.loading = false;
        this.initialLoad = false;
        this.error = false;
      });
      print('종료');
    } catch (e) {
      setState(() {
        this.error = true;
        this.loading = false;
      });
      print(e);
    }
  }
}
