# Peblo AI Story Buddy & Quiz Component

A Flutter implementation of the Peblo intern challenge: a kid-friendly, single-screen mobile app that narrates a story using TTS and follows up with a data-driven interactive quiz.

---

## Screenshots / Screen Recording

> Record the app using `flutter screenshot` or an Android/iOS screen recorder.
> Upload the `.mp4` in the Google Form.

Flow to capture:
1. App opens → Pip (the robot buddy) floats gently
2. Tap **"Read Me a Story!"** → loading state → narration plays with sound-wave animation
3. Audio ends → quiz slides in smoothly
4. Tap a wrong answer → card shakes + haptic feedback → retry
5. Tap correct answer (Blue) → confetti burst + success card → "Play Again"

---

## Framework Choice: Flutter

**Why Flutter over Swift Native?**

- **Cross-platform reach** — The brief targets mid-range Android devices (≈3 GB RAM) in India. Flutter compiles to native ARM code and runs on Android and iOS from a single codebase.
- **Performance parity** — Flutter's Skia/Impeller rendering pipeline delivers 60 fps animations without a JavaScript bridge or native view synchronisation overhead.
- **Ecosystem** — `flutter_tts`, `confetti`, and `provider` are mature, well-maintained packages that exactly match the challenge's feature set.
- **Mid-range optimisation** — Flutter's rendering is entirely self-contained: no WebView, no native view embedding for the core UI. This keeps the memory footprint lean on constrained devices.

---

## Architecture

```
lib/
├── main.dart                  # App entry point, Provider setup
├── models/
│   └── quiz_model.dart        # Pure data class; parsed from JSON
├── providers/
│   └── story_provider.dart    # All business logic (TTS, quiz state, transitions)
├── screens/
│   └── home_screen.dart       # Single-screen composition
└── widgets/
    ├── buddy_widget.dart      # Animated robot character (CustomPainter)
    ├── story_card.dart        # Story text + sound-wave indicator
    ├── read_button.dart       # CTA button with all audio states
    └── quiz_widget.dart       # Data-driven quiz + confetti success card
```

**State management: Provider**

`StoryProvider` (a `ChangeNotifier`) is the single source of truth for:
- `AudioState` — `idle | loading | playing | finished | error`
- `QuizState` — `hidden | visible | answered`
- `AnswerResult` — `none | correct | wrong`

Widgets consume state via `context.watch<StoryProvider>()` and dispatch actions via `context.read<StoryProvider>()`. No widget holds business logic. Animations are triggered by comparing previous vs. current `AnswerResult` inside `Consumer` builders, using `addPostFrameCallback` to avoid setState-during-build errors.

---

## Audio → Quiz Transition

When `FlutterTts.setCompletionHandler` fires, `StoryProvider` sets `_audioState = AudioState.finished` and schedules a 600 ms delay before setting `_quizState = QuizState.visible`. This pause lets the child's attention settle after hearing the story end before the quiz slides in.

The quiz widget uses `AnimatedSlide` + `AnimatedOpacity` for a smooth upward reveal (from `Offset(0, 0.15)` to `Offset.zero`) over 500 ms with an `easeOutCubic` curve.

```dart
// story_provider.dart
_tts.setCompletionHandler(() {
  _audioState = AudioState.finished;
  notifyListeners();
  Future.delayed(const Duration(milliseconds: 600), _revealQuiz);
});
```

---

## Data-Driven Quiz Renderer

The quiz is **never hardcoded**. `QuizModel.fromJson()` parses the backend JSON:

```json
{
  "question": "What colour was Pip the Robot's lost gear?",
  "options": ["Red", "Green", "Blue", "Yellow"],
  "answer": "Blue"
}
```

The options list is rendered with `List.generate(quiz.options.length, (i) => _OptionTile(...))`. Changing the JSON to 3 or 5 options, a different question, or a different answer requires **zero code changes** — the UI adapts automatically. Letter badges (A, B, C, D, E) are drawn from a static list; indices beyond E fall back to numeric labels.

---

## Caching Approach

**Native TTS (current implementation)**

The device's TTS engine (`flutter_tts`) synthesises audio on-device. There is no network call, so no caching is needed. The engine is initialised once in `StoryProvider`'s constructor and reused across plays.

**If ElevenLabs (or any remote TTS) were used:**

1. Hash the story text with `sha256` to create a stable cache key.
2. Check `path_provider`'s application documents directory for a matching `.mp3` file.
3. On cache miss, fetch from the API, write to disk, then play.
4. On subsequent plays, serve from disk — zero network call.
5. Evict files older than 7 days on app launch to manage storage on low-capacity devices.

```dart
// Pseudocode for remote audio caching
final key = sha256.convert(utf8.encode(storyText)).toString();
final file = File('${docsDir.path}/tts_$key.mp3');
if (!await file.exists()) {
  final bytes = await ElevenLabsApi.synthesise(storyText);
  await file.writeAsBytes(bytes);
}
await audioPlayer.play(DeviceFileSource(file.path));
```

---

## Audio Loading & Failure States

| State | UI |
|---|---|
| `idle` | "Read Me a Story!" button pulses gently |
| `loading` | Button shows spinner + "Preparing…" label |
| `playing` | Button shows speaker icon + "Listening…"; sound-wave renders in story card |
| `finished` | Button returns to idle; quiz reveal begins |
| `error` | Red error banner below story card; button changes to "Try Again" in red gradient |

The `retry()` method resets state to `idle` and re-calls `readStory()`, which re-checks TTS availability before attempting to speak again. The app never hangs or shows an uncaught exception to the child.

---

## Performance Profiling

### What was measured

`flutter run --profile` on a Redmi Note 10 (Snapdragon 678, 4 GB RAM — close to the 3 GB target):

- **Frame timing** in DevTools Timeline (target: all frames < 16.67 ms)
- **Widget rebuild count** via the Flutter Performance overlay

### What was found

1. **`AnimatedBuilder` wrapping `Consumer`** — stacking these caused the entire quiz column to rebuild on every animation tick during the shake sequence. This produced frame times of ~22 ms.

2. **`CustomPaint` `shouldRepaint`** — the robot painter initially returned `true` always, causing unnecessary repaints even when state hadn't changed.

### What was changed

1. Moved `AnimatedBuilder` *inside* `Consumer` so only the specific animated widget rebuilds — not its siblings. Frame times dropped to ~10 ms during shake.

2. Implemented a proper `shouldRepaint` check comparing `isHappy`, `isTalking`, and `isSad`. This eliminated redundant repaints during idle floating.

3. Used `const` constructors wherever possible (`const StoryCard()`, `const ReadButton()`, etc.) to let Flutter short-circuit subtree diffing.

4. Set `physics: BouncingScrollPhysics()` on the `SingleChildScrollView` — lighter than `ClampingScrollPhysics` on mid-range hardware.

### Before / After

| Metric | Before | After |
|---|---|---|
| Shake animation frame time | ~22 ms | ~10 ms |
| Idle repaint rate (robot) | Every frame | Only on state change |
| Widget rebuilds on answer | Whole screen | Quiz card only |

> **Screenshot note:** Attach a DevTools frame-timing screenshot showing the green bars below the 16 ms line during the shake and confetti sequences.

---

## Mid-Range Android Optimisation

1. **No heavy asset loading** — The robot buddy is drawn with `CustomPainter` (vector, zero MB). No large PNG sprites.
2. **`confetti` package** — Particles use simple `Canvas` draws. Limited to 22 particles with `particleDrag: 0.05` to keep GPU load low.
3. **`minSdkVersion 21`** — Covers Android 5.0+, targeting the widest possible device base including older mid-range phones.
4. **`shrinkResources true` + ProGuard** in release build — reduces APK size and eliminates dead code.
5. **Portrait lock** — Prevents layout recalculations on orientation change, which are expensive on slower CPUs.
6. **Single `ChangeNotifier`** — Avoids cascading listener chains that create GC pressure on constrained heaps.
7. **`BouncingScrollPhysics`** — Lighter scroll simulation than the default clamping physics.

---

## AI Usage & Judgment

**Where AI was used:**
- Drafting the `_RobotPainter` path geometry (eye positioning, mouth curves)
- Generating the initial `TweenSequence` values for the shake animation
- Structuring the README sections

**One suggestion rejected:**

AI suggested using `flutter_animate` as the animation library for simplicity. I rejected this because `flutter_animate` adds a dependency that wraps standard Flutter animation APIs — for a challenge focused on performance on mid-range devices, I preferred using Flutter's built-in `AnimationController` + `TweenSequence` directly. This avoids an extra package, keeps the dependency tree lean, and demonstrates knowledge of the core animation system.

**What didn't work:**

Initially, I triggered confetti and shake animations by calling `_ctrl.forward()` directly inside the `Consumer` builder. This threw a `setState() called during build` error. The fix was wrapping all animation triggers in `WidgetsBinding.instance.addPostFrameCallback((_) => ...)`, which defers the side effect until after the current frame is committed.

---

## Setup & Run

```bash
# 1. Install dependencies
flutter pub get

# 2. Run on connected device (use a physical device for TTS)
flutter run

# 3. Release build for Android
flutter build apk --release

# 4. Run tests
flutter test
```

> **Note on TTS:** The `flutter_tts` package uses the device's native engine. On Android emulators, TTS may be unavailable or produce robotic output. Testing on a physical device gives the best experience. The app handles the failure gracefully with the error banner and retry flow.

---

## Dependencies

| Package | Version | Purpose |
|---|---|---|
| `provider` | ^6.1.1 | State management |
| `flutter_tts` | ^4.0.2 | Native TTS narration |
| `confetti` | ^0.7.0 | Celebration particle burst |
| `vibration` | ^1.9.0 | Haptic feedback |
| `google_fonts` | ^6.2.1 | Nunito typeface |
| `http` | ^1.2.1 | Future-ready for remote TTS API |
