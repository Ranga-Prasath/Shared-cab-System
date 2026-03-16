import 'package:flutter_test/flutter_test.dart';
import 'package:shared_cab/core/utils/ride_formatters.dart';

void main() {
  group('RideFormatters', () {
    test('safeInitial returns a fallback for empty names', () {
      expect(RideFormatters.safeInitial(''), '?');
      expect(RideFormatters.safeInitial('   '), '?');
      expect(RideFormatters.safeInitial(null), '?');
    });

    test('safeInitial uppercases the first visible character', () {
      expect(RideFormatters.safeInitial('alice'), 'A');
      expect(RideFormatters.safeInitial(' bob'), 'B');
    });

    test('firstName falls back when the input is blank', () {
      expect(RideFormatters.firstName(''), 'there');
      expect(RideFormatters.firstName('   ', fallback: 'Rider'), 'Rider');
      expect(RideFormatters.firstName('Ada Lovelace'), 'Ada');
    });
  });
}
