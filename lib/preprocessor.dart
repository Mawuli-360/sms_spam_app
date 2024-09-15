import 'package:english_words/english_words.dart';
import 'package:lemmatizerx/lemmatizerx.dart';

class TextPreprocessor {
  final Set<String> stopWords = Set.from(all); // Using english_words package
  final Lemmatizer lemmatizer = Lemmatizer(); // Using lemmatizerx package

  String preprocessText(String text) {
    text = text.toLowerCase();
    text = _removeDigits(text);
    text = _removeHtmlTags(text);
    text = _removeUrl(text);
    text = _removeSpecialCharacters(text);
    text = _removeStopwords(text);
    text = _removePunctuations(text);
    text = _replaceSpecialSymbols(text);
    text = _convertEmoji(text);
    text = _expandContractions(text);
    text = _lemmatizeWords(text);
    return text;
  }

  String _removeDigits(String text) {
    return text.replaceAll(RegExp(r'\d+'), '');
  }

  String _removeHtmlTags(String text) {
    return text.replaceAll(RegExp(r'<[^>]*>'), '');
  }

  String _removeUrl(String text) {
    return text.replaceAll(RegExp(r'https?://\S+|www\.\S+'), '');
  }

  String _removeSpecialCharacters(String text) {
    return text.replaceAll(RegExp(r'[^a-zA-Z\s]'), ' ');
  }

  String _removeStopwords(String text) {
    return text.split(' ').where((word) => !stopWords.contains(word)).join(' ');
  }

  String _removePunctuations(String text) {
    return text.replaceAll(RegExp(r'[^\w\s]'), '');
  }

  String _replaceSpecialSymbols(String text) {
    return text.replaceAll('&', 'and').replaceAll('@', 'at');
  }

  String _convertEmoji(String text) {
    // This is a simplified version. For a more comprehensive emoji conversion,
    // you might need to use a dedicated emoji package.
    return text.replaceAllMapped(RegExp(r'[\u{1F600}-\u{1F64F}]'), (match) {
      return ':${match.group(0)}:';
    });
  }

  String _expandContractions(String text) {
    var contractions = {
      "n't": " not",
      "'re": " are",
      "'s": " is",
      "'d": " would",
      "'ll": " will",
      "'ve": " have",
      "'m": " am"
    };
    contractions.forEach((key, value) {
      text = text.replaceAll(key, value);
    });
    return text;
  }

  String _lemmatizeWords(String text) {
    return text.split(' ').map((word) => lemmatizer.lemmas(word)).join(' ');
  }
}
