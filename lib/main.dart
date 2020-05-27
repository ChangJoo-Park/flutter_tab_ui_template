import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_shimmer/flutter_shimmer.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:http/http.dart' as http;
import 'package:remote_api_list/models/post.dart';
import 'package:scroll_bottom_navigation_bar/scroll_bottom_navigation_bar.dart';

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

class _MyHomePageState extends State<MyHomePage> with TickerProviderStateMixin {
  bool _initialLoad = true;
  bool _loading = false;
  bool _showLoading = false;
  bool _error = false;
  List<Post> _items = [];
  String url;
  // Tab
  int _selectedIndex = 0;
  // Scroll
  final controller = ScrollController();

  @override
  void initState() {
    _fetchPosts();
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
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
        body: ValueListenableBuilder<int>(
          valueListenable: controller.bottomNavigationBar.tabNotifier,
          builder: (BuildContext context, int tabIndex, Widget child) {
            // TODO: 여기서 tabIndex 컨트롤
            return Snap(
              controller: controller.bottomNavigationBar,
              child: _renderContent(),
            );
          },
        ),
        floatingActionButton: FloatingActionButton(
          child: Icon(Icons.refresh),
          onPressed: () {
            _fetchPosts();
          },
        ),
        bottomNavigationBar: ScrollBottomNavigationBar(
          controller: controller,
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: Icon(Icons.home),
              title: Text('Home'),
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.business),
              title: Text('Business'),
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.school),
              title: Text('School'),
            ),
          ],
        ));
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
      child: ListView.separated(
        controller: controller,
        separatorBuilder: (BuildContext context, int index) => Divider(
          color: Colors.black,
        ),
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
    return ListTile(
      key: key,
      title: Text(post.title),
      onTap: () {},
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
    return ListTileShimmer(
      isRectBox: true,
      isDisabledAvatar: true,
      isDisabledButton: true,
      padding: const EdgeInsets.all(0),
      beginAlign: Alignment.centerLeft,
      endAlign: Alignment.centerLeft,
    );
  }
}
