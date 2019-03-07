import 'package:bible_bloc/Models/Book.dart';
import 'package:bible_bloc/Models/Chapter.dart';
import 'package:bible_bloc/Models/Verse.dart';

abstract class IBibleProvider {
  Future<List<Book>> getAllBooks();

  Book getBook(String name);

  Chapter getChapter(String bookName, int chapterNumber);

  Future<Chapter> getChapterById(int chapterId);

  List<Verse> getSearchResults(String searchTerm, List<Book> booksToSearch);

  Future init();
}
