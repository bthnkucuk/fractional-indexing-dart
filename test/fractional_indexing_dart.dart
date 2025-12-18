import 'package:fractional_indexing_dart/fractional_indexing_dart.dart' as findex;
import 'package:test/test.dart';

void main() {
  group('fractional_indexing', () {
    // Helper function to match the JS test style
    void testKeyBetween(String? a, String? b, String expected) {
      test('generateKeyBetween($a, $b) == $expected', () {
        try {
          final result = findex.generateKeyBetween(a, b);
          expect(result, equals(expected));
        } catch (e) {
          expect(e.toString(), contains(expected));
        }
      });
    }

    testKeyBetween(null, null, "a0");
    testKeyBetween(null, "a0", "Zz");
    testKeyBetween(null, "Zz", "Zy");
    testKeyBetween("a0", null, "a1");
    testKeyBetween("a1", null, "a2");
    testKeyBetween("a0", "a1", "a0V");
    testKeyBetween("a1", "a2", "a1V");
    testKeyBetween("a0V", "a1", "a0l");
    testKeyBetween("Zz", "a0", "ZzV");
    testKeyBetween("Zz", "a1", "a0");
    testKeyBetween(null, "Y00", "Xzzz");
    testKeyBetween("bzz", null, "c000");
    testKeyBetween("a0", "a0V", "a0G");
    testKeyBetween("a0", "a0G", "a08");
    testKeyBetween("b125", "b129", "b127");
    testKeyBetween("a0", "a1V", "a1");
    testKeyBetween("Zz", "a01", "a0");
    testKeyBetween(null, "a0V", "a0");
    testKeyBetween(null, "b999", "b99");
    testKeyBetween(null, "A00000000000000000000000000", "invalid order key: A00000000000000000000000000");
    testKeyBetween(null, "A000000000000000000000000001", "A000000000000000000000000000V");
    testKeyBetween("zzzzzzzzzzzzzzzzzzzzzzzzzzy", null, "zzzzzzzzzzzzzzzzzzzzzzzzzzz");
    testKeyBetween("zzzzzzzzzzzzzzzzzzzzzzzzzzz", null, "zzzzzzzzzzzzzzzzzzzzzzzzzzzV");
    testKeyBetween("a00", null, "invalid order key: a00");
    testKeyBetween("a00", "a1", "invalid order key: a00");
    testKeyBetween("0", "1", "invalid order key head: 0");
    testKeyBetween("a1", "a0", "a1 >= a0");

    test('generateNKeysBetween base 10 tests', () {
      const base10Digits = "0123456789";

      void testN(String? a, String? b, int n, String expected) {
        try {
          final result = findex.generateNKeysBetween(a, b, n, base10Digits).join(" ");
          expect(result, equals(expected));
        } catch (e) {
          expect(e.toString(), contains(expected));
        }
      }

      testN(null, null, 5, "a0 a1 a2 a3 a4");
      testN("a4", null, 10, "a5 a6 a7 a8 a9 b00 b01 b02 b03 b04");
      testN(null, "a0", 5, "Z5 Z6 Z7 Z8 Z9");
      testN("a0", "a2", 20, "a01 a02 a03 a035 a04 a05 a06 a07 a08 a09 a1 a11 a12 a13 a14 a15 a16 a17 a18 a19");
    });

    test('generateKeyBetween base 95 tests', () {
      const base95Digits =
          " !\"#\$%&'()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\\]^_`abcdefghijklmnopqrstuvwxyz{|}~";

      void testBase95(String? a, String? b, String expected) {
        try {
          final result = findex.generateKeyBetween(a, b, base95Digits);
          expect(result, equals(expected));
        } catch (e) {
          expect(e.toString(), contains(expected));
        }
      }

      testBase95("a00", "a01", "a00P");
      testBase95("a0/", "a00", "a0/P");
      testBase95(null, null, "a ");
      testBase95("a ", null, "a!");
      testBase95(null, "a ", "Z~");
      testBase95("a0 ", "a0!", "invalid order key: a0 ");
      testBase95(null, "A                          0", "A                          (");
      testBase95("a~", null, "b  ");
      testBase95("Z~", null, "a ");
      testBase95("b   ", null, "invalid order key: b   ");
      testBase95("a0", "a0V", "a0;");
      testBase95("a  1", "a  2", "a  1P");
      testBase95(null, "A                          ", "invalid order key: A                          ");
    });
  });
}
