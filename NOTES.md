# Lab 10 notes: Teachable Machine image classifier

Students: ______________  Partner: ______________

## Class list (T1)
1.
2.
3.
4.
5.
6.

## Design credit (T14)
- Name:
- Author:
- Link:
- Licence:
- Also update `lib/theme/design_credit.dart` (shown on the Model screen).

## Part 1 questions
1. What does the model answer for an object that belongs to none of the classes? How does the background class change that?
2. Floating point vs Quantized: what differs in file size, input type, and in the Dart code?

## Part 2 questions
1. `assets/model/` vs `assets/`: which files would each bundle?
2. Why can `image` and `http` run in a plain Dart unit test while `tflite_flutter` and `image_picker` cannot?

## Part 3 questions and decisions
- Sharing the classifier (T11): I create it once in `AppState.load()` and give it to the screens with `AppScope` (InheritedNotifier). Screens don't call `Classifier.load()`. `close()` is called in dispose.
1. Change normalisation to `value / 255` and classify the sample again. What happens to the percentages, and why does nothing crash?
2. Where in the app is the number of classes written down? What must be edited after retraining with a seventh class?
   - Nowhere in the dart code, it comes from `labels.txt`. Load also checks the model output size matches. So I only need to replace the 2 files in `assets/model/`.

## Part 4 questions
1. Two things in the Figma design that you changed or left out in Flutter, and why.
2. The Model screen shows the labels. Does it read them from the classifier or from the file again? Defend your choice.
   - From the classifier. It's the same list used for the results so they can't be different, and no need to read the file twice.

## Part 5 questions
1. The same object scored differently from the camera and from a downloaded picture. Two reasons that come from your training data.
2. `classify` runs on the UI thread. How long does it take on your phone (the Result screen prints the Stopwatch time), and what does the user see meanwhile?
   - Measured: ___ ms on ______ (shows a spinner while it runs).

## Evaluation table (T23)
Three new pictures per class, all three sources used across the test.

| # | Source | Expected | Predicted | Confidence | Correct? |
|---|--------|----------|-----------|-----------:|----------|
| 1 | | | | | |

Overall accuracy: ___ / ___ = ___ %
Weakest class: ___

## Checkpoint questions
1. Trace one photo from the shutter button to the percentage on screen: every transformation and the file where it happens.
2. Which three lines of `pubspec.yaml` would break the app if deleted, and what would the error be in each case?
3. Why must the pre-processing in Flutter match Teachable Machine's? Name the two things that have to match.
4. The model is 97 % sure a shoe is a mug. Is that a bug? What does a percentage from this model mean, and what does it not mean?
5. What stays on the device and what leaves it? Compare with sending the photo to a cloud vision API.
