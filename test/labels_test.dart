import 'package:flutter_test/flutter_test.dart';
import 'package:tm_classifier/services/classifier.dart';

void main() {
  test('parseLabels: normal Teachable Machine file', () {
    expect(parseLabels('0 Mug\n1 Bottle\n'), ['Mug', 'Bottle']);
  });

  test('parseLabels: Windows line endings, blank lines, labels with spaces', () {
    expect(
      parseLabels('0 Mug\r\n1 Bottle\r\n2 Car keys\r\n\r\n'),
      ['Mug', 'Bottle', 'Car keys'],
    );
    expect(parseLabels('0 Mug\r1 Pen'), ['Mug', 'Pen']);
    expect(parseLabels('  3   Nothing  \n'), ['Nothing']);
  });

  test('Classifier.load with a wrong path says what is missing and where', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await expectLater(
      Classifier.load(labelsPath: 'assets/model/labelz.txt'),
      throwsA(isA<ClassifierLoadException>()
          .having((e) => e.message, 'message', contains('assets/model/labelz.txt'))),
    );
  });
}
