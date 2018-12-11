import 'dart:convert';
import 'package:bible_bloc/Models/SearchQuery.dart';
import 'package:bible_bloc/Views/SearchPage/SearchFilter.dart';
import 'package:bible_bloc/Views/SearchPage/SearchResults.dart';
import 'package:queries/collections.dart';
import 'package:bible_bloc/Blocs/bible_bloc.dart';
import 'package:bible_bloc/Designs/DarkDesign.dart';
import 'package:bible_bloc/InheritedBlocs.dart';
import 'package:bible_bloc/Models/Book.dart';
import 'package:bible_bloc/Models/Chapter.dart';
import 'package:bible_bloc/Models/Verse.dart';
import 'package:bible_bloc/Views/BookDrawer/BookDrawer.dart';
import 'package:bible_bloc/Views/VerseViewer/DismissableVerseViewer.dart';
import 'package:flutter/material.dart';
import 'dart:collection';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  final bibleBloc = BibleBloc('resources/esv.xml');
  runApp(MyApp(
    bibleBloc: bibleBloc,
  ));
}

class MyApp extends StatelessWidget {
  final bibleBloc;

  MyApp({this.bibleBloc});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return InheritedBlocs(
      bibleBloc: bibleBloc,
      child: MaterialApp(
        title: 'Flutter Demo',
        theme: Designs.darkTheme,
        home: MyHomePage(
          title: 'Flutter Demo Home Page',
          bibleBloc: bibleBloc,
        ),
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title, this.bibleBloc}) : super(key: key);
  final String title;
  final bibleBloc;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final String membershipKey = 'david.anderson.bibleapp';
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: StreamBuilder<Chapter>(
          stream: InheritedBlocs.of(context).bibleBloc.chapter,
          builder: (BuildContext context, AsyncSnapshot<Chapter> snapshot) {
            if (snapshot.hasData) {
              return Text("${snapshot.data.book.name} ${snapshot.data.number}");
            } else {
              return Text("");
            }
          },
        ),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.search),
            onPressed: () {
              showSearch(
                context: context,
                delegate: BibleSearchDelegate(),
              );
            },
          )
        ],
      ),
      body: StreamBuilder(
        stream: InheritedBlocs.of(context).bibleBloc.chapter,
        //initialData: Chapter(1, []),
        builder: (BuildContext context, AsyncSnapshot snapshot) {
          if (snapshot.hasData) {
            saveCurrentBookAndChapter();
            return Verses(
              addBackgrounds: true,
              book: snapshot.data.book,
              chapter: snapshot.data,
              swipeAction: swipeVersesAway,
            );
          } else {
            readCurrentBookAndChapter();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Center(child: CircularProgressIndicator()),
              ],
            );
          }
        },
      ),
      drawer: BookDrawer(),
    );
  }

  void saveCurrentBookAndChapter() async {
    SharedPreferences sp = await SharedPreferences.getInstance();
    var currentChapter =
        await InheritedBlocs.of(context).bibleBloc.chapter.first;
    sp.setString(membershipKey, json.encode(currentChapter));
  }

  void readCurrentBookAndChapter() async {
    try {
      SharedPreferences sp = await SharedPreferences.getInstance();

      var loadedChapter =
          Chapter.fromJson(json.decode(sp.getString(membershipKey)));
      var books = await InheritedBlocs.of(context).bibleBloc.books.first;
      var currentChapter = books
          .firstWhere((book) => book.name == loadedChapter.book.name)
          .chapters
          .firstWhere((chapter) => chapter.number == loadedChapter.number);
      InheritedBlocs.of(context).bibleBloc.currentChapter.add(currentChapter);
    } catch (e) {
      //return new AppState();
    }
  }

  swipeVersesAway(DismissDirection swipeDetails) async {
    Chapter currentChapter =
        await InheritedBlocs.of(context).bibleBloc.chapter.first;
    var books = await InheritedBlocs.of(context).bibleBloc.books.first;
    if (swipeDetails == DismissDirection.endToStart) {
      goToNextChapter(books, currentChapter);
    } else {
      goToPreviousChapter(books, currentChapter);
    }
    saveCurrentBookAndChapter();
  }

  void goToPreviousChapter(
      UnmodifiableListView<Book> books, Chapter currentChapter) {
    if (books.first == currentChapter.book && currentChapter.number == 1) {
      var prevBook = books.last;
      InheritedBlocs.of(context)
          .bibleBloc
          .currentChapter
          .add(prevBook.chapters.last);
    } else if (1 == currentChapter.number) {
      var prevBook = books[books.indexOf(currentChapter.book) - 1];
      InheritedBlocs.of(context)
          .bibleBloc
          .currentChapter
          .add(prevBook.chapters.last);
    } else {
      Chapter prevChapter = currentChapter.book
          .chapters[currentChapter.book.chapters.indexOf(currentChapter) - 1];
      InheritedBlocs.of(context).bibleBloc.currentChapter.add(prevChapter);
    }
  }

  void goToNextChapter(
      UnmodifiableListView<Book> books, Chapter currentChapter) {
    if (books.last == currentChapter.book &&
        currentChapter.number == currentChapter.book.chapters.length) {
      var nextBook = books.first;
      InheritedBlocs.of(context)
          .bibleBloc
          .currentChapter
          .add(nextBook.chapters.first);
    } else if (currentChapter.book.chapters.length == currentChapter.number) {
      var nextBook = books[books.indexOf(currentChapter.book) + 1];
      InheritedBlocs.of(context)
          .bibleBloc
          .currentChapter
          .add(nextBook.chapters.first);
    } else {
      Chapter nextChapter = currentChapter.book
          .chapters[currentChapter.book.chapters.indexOf(currentChapter) + 1];
      InheritedBlocs.of(context).bibleBloc.currentChapter.add(nextChapter);
    }
  }
}

class BibleSearchDelegate extends SearchDelegate<Chapter> {
  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    InheritedBlocs.of(context)
        .bibleBloc
        .searchTerm
        .add(SearchQuery(queryText: query, book: ""));

    InheritedBlocs.of(context)
        .bibleBloc
        .suggestionSearchTerm
        .add(SearchQuery(queryText: query, book: ""));

    return Column(
      children: <Widget>[
        StreamBuilder(
          stream:
              InheritedBlocs.of(context).bibleBloc.suggestionSearchearchResults,
          initialData: [],
          builder: (BuildContext context, AsyncSnapshot snapshot) {
            final books = Collection(snapshot.data)
                .select((verse) => verse.chapter.book)
                .distinct()
                .toList();
            return new SearchFilter(query: query, books: books);
          },
        ),
        StreamBuilder(
          stream: InheritedBlocs.of(context).bibleBloc.searchResults,
          builder:
              (context, AsyncSnapshot<UnmodifiableListView<Verse>> snapshot) {
            final results = snapshot.data;
            return new SearchResults(results: results);
          },
        ),
      ],
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return Column();
  }
}