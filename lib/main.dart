import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(MyApp());
}

class Owner {
  //final int accountId;
  // final int reputation;
  final int userId;
  final String userType;
  // final int acceptRate;
  final String profileImage;
  final String displayName;
  final String link;

  Owner({
    //required this.accountId,
    //required this.reputation,
    required this.userId,
    required this.userType,
    required this.profileImage,
    required this.displayName,
    required this.link,
  });

  factory Owner.fromJson(Map<String, dynamic> json) {
    return Owner(
      //accountId: json['account_id']??Text('account_id'),
      //reputation: json['reputation'],
      userId: json['user_id'],
      userType: json['user_type'],
      profileImage: json['profile_image'],
      displayName: json['display_name'],
      link: json['link'],
    );
  }
}

class Item {
  final List<String> tags;
  final Owner owner;
  final bool isAnswered;
  final int viewCount;
  //final int protectedDate;
  //final int acceptedAnswerId;
  final int answerCount;
  final int score;
  final int lastActivityDate;
  final int creationDate;
  //final int lastEditDate;
  final int questionId;
  //final String contentLicense;
  final String link;
  final String title;

  Item({
    required this.tags,
    required this.owner,
    required this.isAnswered,
    required this.viewCount,
    //required this.protectedDate,
    // required this.acceptedAnswerId,
    required this.answerCount,
    required this.score,
    required this.lastActivityDate,
    required this.creationDate,
    //required this.lastEditDate,
    required this.questionId,
    //  required this.contentLicense,
    required this.link,
    required this.title,
  });

  factory Item.fromJson(Map<String, dynamic> json) {
    return Item(
      tags: List<String>.from(json['tags']),
      owner: Owner.fromJson(json['owner']),
      isAnswered: json['is_answered'],
      viewCount: json['view_count'],
      //protectedDate: json['protected_date'],
      //acceptedAnswerId: json['accepted_answer_id'],
      answerCount: json['answer_count'],
      score: json['score'],
      lastActivityDate: json['last_activity_date'],
      creationDate: json['creation_date'],
      //lastEditDate: json['last_edit_date'],
      questionId: json['question_id'],
      //contentLicense: json['content_license'],
      link: json['link'],
      title: json['title'],
    );
  }
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Stack Overflow Search',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: StackOverflowSearch(),
    );
  }
}

class StackOverflowSearch extends StatefulWidget {
  @override
  _StackOverflowSearchState createState() => _StackOverflowSearchState();
}

class _StackOverflowSearchState extends State<StackOverflowSearch> {
  TextEditingController _searchController = TextEditingController();
  List<Item> _searchResults = [];
  int _currentPage = 1;
  bool _isLoading = false;

  Future<void> _searchStackOverflow() async {
    String query = _searchController.text;

    if (query.isNotEmpty) {
      // Reset the search results and page number
      setState(() {
        _searchResults.clear();
        _currentPage = 1;
      });

      await _fetchSearchResults(query);
    }
  }

  Future<void> _fetchSearchResults(String query) async {
    // Prevent multiple simultaneous requests
    if (_isLoading) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      String apiUrl =
          'https://api.stackexchange.com/2.3/search?order=desc&sort=votes&site=stackoverflow&intitle=$query&pagesize=10&page=$_currentPage';
      final url = Uri.parse(apiUrl);

      var response = await http.get(url);
      print(response.body);

      var data = json.decode(response.body);
      List<dynamic> items = data['items'];

      List<Item> results = [];

      for (var item in items) {
        Item question = Item(
          tags: List<String>.from(item['tags']),
          owner: Owner.fromJson(item['owner']),
          isAnswered: item['is_answered'],
          viewCount: item['view_count'],
          answerCount: item['answer_count'],
          score: item['score'],
          lastActivityDate: item['last_activity_date'],
          creationDate: item['creation_date'],
          questionId: item['question_id'],
          link: item['link'],
          title: item['title'],
        );
        results.add(question);
      }

      setState(() {
        _searchResults.addAll(results);
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _loadMoreResults() {
    if (!_isLoading) {
      setState(() {
        _currentPage++;
      });

      _fetchSearchResults(_searchController.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    double height = MediaQuery.of(context).size.height;
    double width = MediaQuery.of(context).size.width;
    return Scaffold(
      appBar: AppBar(
        title: Text('Stack Overflow Search'),
      ),
      body: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Container(
                  width: width,
                  padding: const EdgeInsets.all(16.0),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Enter a search term',
                    ),
                  ),
                ),
              ),
              Container(
                child: IconButton(
                  icon: Icon(Icons.search),
                  onPressed: _searchStackOverflow,
                ),
              ),
            ],
          ),
          Expanded(
            child: NotificationListener<ScrollNotification>(
              onNotification: (ScrollNotification scrollInfo) {
                if (!_isLoading &&
                    scrollInfo.metrics.pixels ==
                        scrollInfo.metrics.maxScrollExtent) {
                  _loadMoreResults();
                }
                return true;
              },
              child: ListView.builder(
                scrollDirection: Axis.vertical,
                itemCount: _searchResults.length + 1,
                itemBuilder: (BuildContext context, int index) {
                  if (index == _searchResults.length) {
                    return _isLoading
                        ? Center(child: CircularProgressIndicator())
                        : Container();
                  } else {
                    return Column(
                      children: [
                        Padding(
                          padding: EdgeInsets.all(10),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: width * 0.30,
                                decoration: BoxDecoration(
                                  color: Colors.black12,
                                  borderRadius: BorderRadius.circular(4.0),
                                ),
                                padding: EdgeInsets.all(8.0),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.where_to_vote_sharp),
                                    SizedBox(height: 5),
                                    Icon(Icons.comment),
                                    SizedBox(height: 5),
                                    Text(
                                      _searchResults[index].score.toString(),
                                    ),
                                    SizedBox(
                                      height: 20,
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _searchResults[index].title,
                                      style: TextStyle(
                                        color: Colors.blue,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16.0,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    SizedBox(height: 5),
                                    Wrap(
                                      spacing: 8.0,
                                      runSpacing: 4.0,
                                      children:
                                          _searchResults[index].tags.map((tag) {
                                        return Container(
                                          decoration: BoxDecoration(
                                            color: Colors.blue,
                                            borderRadius:
                                                BorderRadius.circular(4.0),
                                          ),
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 8.0,
                                            vertical: 4.0,
                                          ),
                                          child: Text(
                                            tag,
                                            style:
                                                TextStyle(color: Colors.white),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                    SizedBox(height: 5),
                                    Text(
                                      'Asked by: ${_searchResults[index].owner.displayName}',
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Divider(thickness: 2),
                      ],
                    );
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
