import 'dart:collection';

import 'package:fractional_indexing_dart/fractional_indexing_dart.dart';

base class TodoEntry extends LinkedListEntry<TodoEntry>
    with RankedLinkedListEntry<TodoEntry> {
  final String id;
  final String content;

  TodoEntry(this.id, this.content);

  @override
  String toString() => '$id ($rank): $content';
}

void main() {
  print('--- Single Key Generation ---');
  final first = FractionalIndexing.generateKeyBetween(null, null);
  print('First: $first'); // "a0"

  final second = FractionalIndexing.generateKeyBetween(first, null);
  print('Second (after First): $second'); // "a1"

  final third = FractionalIndexing.generateKeyBetween(second, null);
  print('Third (after Second): $third'); // "a2"

  final zeroth = FractionalIndexing.generateKeyBetween(null, first);
  print('Zeroth (before First): $zeroth'); // "Zz"

  final secondAndHalf = FractionalIndexing.generateKeyBetween(second, third);
  print('SecondAndHalf (between Second and Third): $secondAndHalf'); // "a1V"

  print('\n--- Multiple Key Generation ---');
  final multiple = FractionalIndexing.generateNKeysBetween(null, null, 2);
  print('Generate 2 keys from start: $multiple'); // ['a0', 'a1']

  final afterSecond = FractionalIndexing.generateNKeysBetween(second, null, 2);
  print('Generate 2 keys after Second: $afterSecond'); // ['a2', 'a3']

  final beforeZeroth = FractionalIndexing.generateNKeysBetween(null, zeroth, 2);
  print('Generate 2 keys before Zeroth: $beforeZeroth'); // ['Zy', 'Zz']

  final midpoints = FractionalIndexing.generateNKeysBetween(second, third, 2);
  print(
      'Generate 2 keys between Second and Third: $midpoints'); // ['a1G', 'a1V']

  print('\n--- Comparison ---');
  final list = [second, first, third, secondAndHalf, zeroth];
  print('Unsorted: $list');
  list.sort((a, b) => a.compareTo(b));
  print('Sorted: $list');

  print('\n--- RankedLinkedList ---');
  final rankedList = RankedLinkedList<TodoEntry>();

  final todo1 = TodoEntry('1', 'Buy milk');
  rankedList.add(todo1);
  print('Added Todo 1: $todo1');

  final todo3 = TodoEntry('3', 'Walk the dog');
  rankedList.add(todo3);
  print('Added Todo 3: $todo3');

  final todo2 = TodoEntry('2', 'Clean room');
  todo1.insertAfter(todo2);
  print('Inserted Todo 2 after Todo 1: $todo2');

  print('List order:');
  for (final entry in rankedList) {
    print(entry);
  }

  print('\n--- RankedLinkedList: insert (Binary Search) ---');
  final loadedList = RankedLinkedList<TodoEntry>();
  final items = [
    TodoEntry('3', 'C')..rank = 'a2',
    TodoEntry('1', 'A')..rank = 'a0',
    TodoEntry('2', 'B')..rank = 'a1',
  ];

  for (final item in items) {
    loadedList.insert(item.rank!, item);
  }

  print('Loaded List (sorted):');
  for (final entry in loadedList) {
    print(entry);
  }
}
