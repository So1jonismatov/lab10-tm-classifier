# Lab 10 notes: Teachable Machine image classifier

Student: Sobirjon Ismatov (ID 240413)  Partner: ______________

## Class list (T1)
Handwritten digits, 10 classes (Teachable Machine image project, exported as TFLite **quantized**):

0. zero
1. one
2. two
3. three
4. four
5. five
6. six
7. seven
8. eight
9. nine

There is no separate background class, so an empty page will still get one of the digits.

## Design credit (T14)
- Name: Material 3 Design Kit
- Author: Material Design (Google)
- Link: https://www.figma.com/community/file/1035203688168086460
- Licence: CC BY 4.0
- Also shown in the app on the Model screen (`lib/theme/design_credit.dart`).

## Part 1 questions
1. What does the model answer for an object that belongs to none of the classes? How does the background class change that?
   - It still picks one of the classes, because the softmax always adds up to 100%. It can't say "I don't know". A background class gives it somewhere to put empty or random pictures, so they go there instead of to a real label. We didn't add one, so a blank page still shows up as some digit.
2. Floating point vs Quantized: what differs in file size, input type, and in the Dart code?
   - Quantized is about 4x smaller (ours is ~780 KB) because the weights are uint8 instead of float32. Input and output are uint8 (0-255), so you don't do `/127.5 - 1` and you read the output as bytes and convert it back with scale and zero point (or divide by 255). Float takes float32 input in -1..1 and gives float probabilities. Our `Classifier` reads the tensor type when it loads and handles both, so we can use either file.

## Part 2 questions
1. `assets/model/` vs `assets/`: which files would each bundle?
   - `assets/model/` bundles only the files directly in that folder (model + labels). `assets/` bundles only the files directly in `assets/`, not the subfolders, so the model would NOT be included. Subfolders have to be listed on their own.
2. Why can `image` and `http` run in a plain Dart unit test while `tflite_flutter` and `image_picker` cannot?
   - `image` and `http` are pure Dart. `tflite_flutter` needs the native TFLite library and `image_picker` uses a platform channel to the phone's camera/gallery, and neither exists in a normal test run.

## Part 3 questions and decisions
- Sharing the classifier (T11): I create it once in `AppState.load()` and give it to the screens with `AppScope` (InheritedNotifier). Screens don't call `Classifier.load()`. `close()` is called in dispose.
1. Change normalisation to `value / 255` and classify the sample again. What happens to the percentages, and why does nothing crash?
   - The percentages become wrong, often very confident in the wrong class, because the model was trained on -1..1 and gets 0..1. Nothing crashes because the tensor has the same shape and type, just different numbers. (With our quantized model the input is raw 0-255 anyway, so this only matters for the float model.)
2. Where in the app is the number of classes written down? What must be edited after retraining with a seventh class?
   - Nowhere in the dart code, it comes from `labels.txt`. Load also checks the model output size matches. So I only need to replace the 2 files in `assets/model/`.

## Part 4 questions
1. Two things in the Figma design that you changed or left out in Flutter, and why.
   - Colours: the kit uses the default purple baseline scheme. I used `ColorScheme.fromSeed` with a teal seed instead, so the app has its own colour but keeps the M3 tonal roles (primary, secondaryContainer, surfaceContainer...).
   - Left out most components (FABs, the large/medium top app bars, side sheets, carousels). The app only has a few screens, so I used the small top app bar, filled/outlined buttons, cards, chips and the navigation bar, and made the corners rounder (16 px).
2. The Model screen shows the labels. Does it read them from the classifier or from the file again? Defend your choice.
   - From the classifier. It's the same list used for the results so they can't be different, and no need to read the file twice.

## Part 5 questions
1. The same object scored differently from the camera and from a downloaded picture. Two reasons that come from your training data.
   - The training pictures were all taken one way (same webcam, lighting, pen and paper), so a downloaded digit with a different font, thickness or background looks unfamiliar.
   - Downloaded pictures are often cropped differently or the digit is small in the frame, but in training the digit filled most of the square.
2. `classify` runs on the UI thread. How long does it take on your phone (the Result screen prints the Stopwatch time), and what does the user see meanwhile?
   - Measured: ___ ms on ______ (shows a spinner while it runs). The image decoding runs in `Isolate.run`, so the spinner keeps moving.

## Evaluation table (T23)
Three new pictures per class, all three sources used across the test.

| # | Source | Expected | Predicted | Confidence | Correct? |
|---|--------|----------|-----------|-----------:|----------|
| 1 | | | | | |

Overall accuracy: ___ / ___ = ___ %
Weakest class: ___

## Checkpoint questions
1. Trace one photo from the shutter button to the percentage on screen: every transformation and the file where it happens.
   - `image_picker` takes the photo and shrinks it to max 1024 wide, then returns JPEG bytes (`services/image_sources.dart`) -> `AppState.classifyFrom` (`state/app_state.dart`) -> `Classifier.classify` (`services/classifier.dart`): decode, fix EXIF rotation, center crop + resize to 224x224, flatten to RGB bytes, map to the model's input values, run the interpreter, convert the output back to probabilities, pair with labels and sort -> `HistoryEntry` -> `ResultScreen`/`LabelRow` shows `(confidence * 100).toStringAsFixed(1) %` (`widgets/label_row.dart`).
2. Which three lines of `pubspec.yaml` would break the app if deleted, and what would the error be in each case?
   - `- assets/model/`: the model isn't bundled and the welcome screen shows "Model file not found".
   - `tflite_flutter: ...`: compile error, `package:tflite_flutter` can't be found.
   - `image_picker: ...` (or `image` / `http`): compile error in `image_sources.dart` / `classifier.dart`.
3. Why must the pre-processing in Flutter match Teachable Machine's? Name the two things that have to match.
   - The model only learned what its training inputs looked like. If the input is different it gives confident nonsense. The two things are (1) the crop/size: center square resized to 224x224, and (2) the pixel scaling: -1..1 for float (raw 0-255 for quantized).
4. The model is 97 % sure a shoe is a mug. Is that a bug? What does a percentage from this model mean, and what does it not mean?
   - Not a bug. The percentage only means "out of MY classes, this one looks most similar". It isn't the probability that the picture really is that thing. Softmax has to give 100% to someone, and the model has never seen a shoe.
5. What stays on the device and what leaves it? Compare with sending the photo to a cloud vision API.
   - Everything stays on the phone: the photo, the model and the results. The only network traffic is when you choose "Download an image", and that only downloads, nothing is uploaded. With a cloud API the photo is uploaded to someone's server, it needs internet, it's slower and it can cost money, but it recognises way more things.
