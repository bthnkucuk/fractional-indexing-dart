import 'package:fractional_indexing_dart/fractional_indexing_dart.dart' as findex;

void main() {
  print('--- Single Key Generation ---');
  final first = findex.generateKeyBetween(null, null);
  print('First: $first'); // "a0"

  final second = findex.generateKeyBetween(first, null);
  print('Second (after First): $second'); // "a1"

  final third = findex.generateKeyBetween(second, null);
  print('Third (after Second): $third'); // "a2"

  final zeroth = findex.generateKeyBetween(null, first);
  print('Zeroth (before First): $zeroth'); // "Zz"

  final secondAndHalf = findex.generateKeyBetween(second, third);
  print('SecondAndHalf (between Second and Third): $secondAndHalf'); // "a1V"

  print('\n--- Multiple Key Generation ---');
  final multiple = findex.generateNKeysBetween(null, null, 2);
  print('Generate 2 keys from start: $multiple'); // ['a0', 'a1']

  final afterSecond = findex.generateNKeysBetween(second, null, 2);
  print('Generate 2 keys after Second: $afterSecond'); // ['a2', 'a3']

  final beforeZeroth = findex.generateNKeysBetween(null, zeroth, 2);
  print('Generate 2 keys before Zeroth: $beforeZeroth'); // ['Zy', 'Zz']

  final midpoints = findex.generateNKeysBetween(second, third, 2);
  print('Generate 2 keys between Second and Third: $midpoints'); // ['a1G', 'a1V']

  print('\n--- Comparison ---');
  final list = [second, first, third, secondAndHalf, zeroth];
  print('Unsorted: $list');
  list.sort((a, b) => a.compareTo(b));
  print('Sorted: $list');
}
