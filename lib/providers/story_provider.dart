// lib/providers/story_provider.dart

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../models/quiz_model.dart';

enum AudioState { idle, loading, playing, paused, finished, error }

enum QuizState { hidden, visible, answered }

enum AnswerResult { none, correct, wrong }

class StoryProvider extends ChangeNotifier {
  // ─── TTS ────────────────────────────────────────────────────────────────
  final FlutterTts _tts = FlutterTts();
  AudioState _audioState = AudioState.idle;
  String _errorMessage = '';

  // ─── Quiz ────────────────────────────────────────────────────────────────
  QuizState _quizState = QuizState.hidden;
  AnswerResult _answerResult = AnswerResult.none;
  String? _selectedOption;
  int _wrongAttempts = 0;

  // ─── Story data ──────────────────────────────────────────────────────────
  static const String storyText =
      'Once upon a time, a clever little robot named Pip '
      'lost his shiny blue gear in the Whispering Woods...';

  /// The quiz JSON exactly as specified by the challenge.
  /// Treat as if it were a backend response — parsed via [QuizModel.fromJson].
  static final Map<String, dynamic> _quizJson = {
    'question': "What colour was Pip the Robot's lost gear?",
    'options': ['Red', 'Green', 'Blue', 'Yellow'],
    'answer': 'Blue',
  };

  late QuizModel _quiz;

  // ─── Getters ─────────────────────────────────────────────────────────────
  AudioState get audioState => _audioState;
  QuizState get quizState => _quizState;
  AnswerResult get answerResult => _answerResult;
  String? get selectedOption => _selectedOption;
  int get wrongAttempts => _wrongAttempts;
  String get errorMessage => _errorMessage;
  QuizModel get quiz => _quiz;

  bool get isBuddyHappy => _answerResult == AnswerResult.correct;
  bool get isBuddyShaking => _answerResult == AnswerResult.wrong;

  // ─── Init ─────────────────────────────────────────────────────────────────
  StoryProvider() {
    _quiz = QuizModel.fromJson(_quizJson); // data-driven parse
    _initTts();
  }

  Future<void> _initTts() async {
    await _tts.setLanguage('en-US');
    await _tts.setSpeechRate(0.42); // slightly slower for children
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.1); // slightly higher pitch, friendlier

    _tts.setStartHandler(() {
      _audioState = AudioState.playing;
      notifyListeners();
    });

    _tts.setCompletionHandler(() {
      _audioState = AudioState.finished;
      notifyListeners();
      // Slight delay before quiz appears for polish
      Future.delayed(const Duration(milliseconds: 600), _revealQuiz);
    });

    _tts.setErrorHandler((msg) {
      _audioState = AudioState.error;
      _errorMessage = msg.toString();
      notifyListeners();
    });

    _tts.setCancelHandler(() {
      if (_audioState != AudioState.finished) {
        _audioState = AudioState.idle;
        notifyListeners();
      }
    });
  }

  // ─── Actions ──────────────────────────────────────────────────────────────

  /// Called when the child taps "Read Me a Story".
  Future<void> readStory() async {
    if (_audioState == AudioState.playing) return;

    _audioState = AudioState.loading;
    _errorMessage = '';
    notifyListeners();

    try {
      // Check TTS engine is available
      final available = await _tts.isLanguageAvailable('en-US');
      if (available == false) throw Exception('TTS language not available');

      await _tts.speak(storyText);
      // setStartHandler fires → sets playing
    } catch (e) {
      _audioState = AudioState.error;
      _errorMessage = 'Could not start narration. Please try again.';
      notifyListeners();
    }
  }

  /// Stop playback (e.g. user navigates away).
  Future<void> stopAudio() async {
    await _tts.stop();
    if (_audioState != AudioState.finished) {
      _audioState = AudioState.idle;
      notifyListeners();
    }
  }

  /// Retry after error.
  Future<void> retry() async {
    _audioState = AudioState.idle;
    _errorMessage = '';
    notifyListeners();
    await readStory();
  }

  // ─── Quiz logic ───────────────────────────────────────────────────────────

  void _revealQuiz() {
    _quizState = QuizState.visible;
    notifyListeners();
  }

  /// Called when child taps an option.
  void submitAnswer(String option) {
    if (_answerResult == AnswerResult.correct) return; // already won

    _selectedOption = option;

    if (option == _quiz.answer) {
      _answerResult = AnswerResult.correct;
      _quizState = QuizState.answered;
    } else {
      _wrongAttempts++;
      _answerResult = AnswerResult.wrong;
    }
    notifyListeners();

    // Reset wrong state after shake animation (650 ms) to allow retry
    if (_answerResult == AnswerResult.wrong) {
      Future.delayed(const Duration(milliseconds: 750), () {
        _answerResult = AnswerResult.none;
        _selectedOption = null;
        notifyListeners();
      });
    }
  }

  /// Reset everything (for dev/testing).
  Future<void> reset() async {
    await _tts.stop();
    _audioState = AudioState.idle;
    _quizState = QuizState.hidden;
    _answerResult = AnswerResult.none;
    _selectedOption = null;
    _wrongAttempts = 0;
    _errorMessage = '';
    _quiz = QuizModel.fromJson(_quizJson);
    notifyListeners();
  }

  @override
  void dispose() {
    _tts.stop();
    super.dispose();
  }
}
