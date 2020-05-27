import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:http/http.dart' as http;
import 'package:remote_api_list/models/post.dart';

Future<List<Post>> fetchPosts(http.Client client) async {
  final response =
      await client.get('https://jsonplaceholder.typicode.com/posts');
  return compute(_parsePosts, response.body);
}

List<Post> _parsePosts(String responseBody) {
  final parsed = json.decode(responseBody).cast<Map<String, dynamic>>();

  return parsed.map<Post>((json) => Post.fromJson(json)).toList();
}

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
  bool _initialLoad = true;
  bool _loading = false;
  bool _showLoading = false;
  bool _error = false;
  List<Post> _items = [];
  String url;

  @override
  void initState() {
    super.initState();
    _fetchPosts();
  }

  void _fetchPosts() {
    if (this._loading) {
      return;
    }

    setState(() {
      this._loading = true;
    });

    fetchPosts(http.Client()).then((value) {
      _items = value;

      setState(() {
        this._initialLoad = false;
        this._loading = false;
        this._error = false;
      });
    }).catchError((e) {
      setState(() {
        this._initialLoad = false;
        this._loading = false;
        this._error = true;
      });
    });
  }

  String get stateTitle {
    if (_initialLoad) {
      return '최초 로딩';
    }
    if (_loading) {
      return '불러오는 중';
    }
    if (_error) {
      return '에러';
    }

    return '완료';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(stateTitle),
        actions: [
          IconButton(
            icon: this._showLoading
                ? Icon(Icons.notifications_active)
                : Icon(Icons.notifications_off),
            onPressed: () {
              setState(() {
                this._showLoading = !this._showLoading;
              });
            },
          ),
        ],
      ),
      body: _renderContent(),
      floatingActionButton: FloatingActionButton(
          child: Icon(Icons.refresh),
          onPressed: () {
            _fetchPosts();
          }),
    );
  }

  _renderContent() {
    if (_error) {
      return ErrorWidget();
    }

    if (_initialLoad) {
      return PostLoadingWidget();
    }

    if (_showLoading && _loading) {
      return PostLoadingWidget();
    }

    if (_items.length == 0) {
      return EmptyPostsWidget();
    }

    return AnimationLimiter(
      child: ListView.builder(
        itemCount: _items.length,
        itemBuilder: (BuildContext context, int index) {
          Post post = _items[index];
          return PostListItemAnimationWidget(
            key: Key('post-animation-${post.id}'),
            index: index,
            child: PostListItemWidget(
              key: Key('post-${post.id}'),
              post: post,
            ),
          );
        },
      ),
    );
  }
}

class PostListItemAnimationWidget extends StatelessWidget {
  const PostListItemAnimationWidget({
    Key key,
    @required this.child,
    @required this.index,
    this.duration = const Duration(milliseconds: 225),
    this.verticalOffset,
    this.delay,
  }) : super(key: key);

  final Widget child;
  final int index;
  final double verticalOffset;
  final Duration duration;
  final Duration delay;
  @override
  Widget build(BuildContext context) {
    return AnimationConfiguration.staggeredList(
      position: index,
      duration: duration,
      delay: delay,
      child: ScaleAnimation(
        child: SlideAnimation(
          verticalOffset: verticalOffset,
          child: FadeInAnimation(
            child: child,
          ),
        ),
      ),
    );
  }
}

class PostListItemWidget extends StatelessWidget {
  const PostListItemWidget({
    Key key,
    @required this.post,
  }) : super(key: key);

  final Post post;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(8.0),
      padding: const EdgeInsets.all(4.0),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.blueAccent),
        borderRadius: BorderRadius.all(Radius.circular(5.0)),
      ),
      child: ListTile(
        key: key,
        title: Text(post.title),
        onTap: () {},
      ),
    );
  }
}

class ErrorWidget extends StatelessWidget {
  const ErrorWidget({
    Key key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(child: Text('에러가 있음'));
  }
}

class EmptyPostsWidget extends StatelessWidget {
  const EmptyPostsWidget({
    Key key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(child: Text('데이터가 없음'));
  }
}

class PostLoadingWidget extends StatelessWidget {
  const PostLoadingWidget({
    Key key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(child: CircularProgressIndicator());
  }
}
