import 'package:fractional_indexing_dart/fractional_indexing_dart.dart';
import 'package:test/test.dart';

import 'dart:collection';

final class TestEntry extends LinkedListEntry<TestEntry>
    with RankedLinkedListEntry<TestEntry> {
  final String id;
  TestEntry(this.id);

  @override
  String toString() => 'TestEntry($id, rank: $rank)';
}

void main() {
  group('RankedLinkedList', () {
    late RankedLinkedList<TestEntry> list;

    setUp(() {
      list = RankedLinkedList<TestEntry>();
    });

    test('add automatically generates ranks', () {
      final e1 = TestEntry('A');
      final e2 = TestEntry('B');
      final e3 = TestEntry('C');

      list.add(e1);
      list.add(e2);
      list.add(e3);

      expect(list.length, 3);
      expect(e1.rank, isNotNull);
      expect(e2.rank, isNotNull);
      expect(e3.rank, isNotNull);

      // Since default add appends, ranks should be increasing lexicographically
      expect(e1.rank!.compareTo(e2.rank!) < 0, isTrue);
      expect(e2.rank!.compareTo(e3.rank!) < 0, isTrue);

      list.validate();
    });

    test('addFirst automatically generates ranks', () {
      final e1 = TestEntry('A');
      final e2 = TestEntry('B');

      list.add(e1);
      list.addFirst(e2); // B should be before A

      expect(e2.next, equals(e1));
      expect(e2.rank!.compareTo(e1.rank!) < 0, isTrue);

      list.validate();
    });

    test('insertAfter automatically generates ranks', () {
      // A -> C
      final e1 = TestEntry('A');
      final e3 = TestEntry('C');
      list.add(e1);
      list.add(e3);

      // insert B between A and C
      final e2 = TestEntry('B');
      e1.insertAfter(e2);

      expect(list.toList(), equals([e1, e2, e3]));
      expect(e1.rank!.compareTo(e2.rank!) < 0, isTrue);
      expect(e2.rank!.compareTo(e3.rank!) < 0, isTrue);

      list.validate();
    });

    test('insertBefore automatically generates ranks', () {
      // A -> C
      final e1 = TestEntry('A');
      final e3 = TestEntry('C');
      list.add(e1);
      list.add(e3);

      // insert B before C
      final e2 = TestEntry('B');
      e3.insertBefore(e2);

      expect(list.toList(), equals([e1, e2, e3]));
      expect(e1.rank!.compareTo(e2.rank!) < 0, isTrue);
      expect(e2.rank!.compareTo(e3.rank!) < 0, isTrue);

      list.validate();
    });

    group('Manual Rank Assignment', () {
      test('addLast throws if entry.rank <= last.rank', () {
        final e1 = TestEntry('A')..rank = 'b';
        list.add(e1);

        final e2 = TestEntry('B')..rank = 'a'; // smaller than last
        expect(() => list.add(e2), throwsArgumentError);

        final e3 = TestEntry('C')..rank = 'b'; // equal to last
        expect(() => list.add(e3), throwsArgumentError);
      });

      test('addFirst throws if entry.rank >= first.rank', () {
        final e1 = TestEntry('A')..rank = 'b';
        list.add(e1);

        final e2 = TestEntry('B')..rank = 'c'; // larger than first
        expect(() => list.addFirst(e2), throwsArgumentError);

        final e3 = TestEntry('C')..rank = 'b'; // equal to first
        expect(() => list.addFirst(e3), throwsArgumentError);
      });

      test('insertAfter throws if invalid rank', () {
        final e1 = TestEntry('A')..rank = 'a';
        final e3 = TestEntry('C')..rank = 'c';
        list.add(e1);
        list.add(e3);

        // Try inserting B after A, but with rank 'a' (equal to A) -> error
        final e2Bad1 = TestEntry('B1')..rank = 'a';
        expect(() => e1.insertAfter(e2Bad1), throwsArgumentError);

        // Try inserting B after A, but with rank 'd' (greater than C) -> error
        final e2Bad2 = TestEntry('B2')..rank = 'd';
        expect(() => e1.insertAfter(e2Bad2), throwsArgumentError);

        // Valid insert
        final e2Good = TestEntry('BGood')..rank = 'b';
        e1.insertAfter(e2Good);
        expect(e2Good.list, list);
        list.validate();
      });

      test('insertBefore throws if invalid rank', () {
        final e1 = TestEntry('A')..rank = 'a';
        final e3 = TestEntry('C')..rank = 'c';
        list.add(e1);
        list.add(e3);

        // Try inserting B before C, but with rank 'c' (equal to C) -> error
        final e2Bad1 = TestEntry('B1')..rank = 'c';
        expect(() => e3.insertBefore(e2Bad1), throwsArgumentError);

        // Try inserting B before C, but with rank 'a' (less or equal to A which is prev) -> error
        // Wait, prev is A (rank 'a'). Rank 'a' is <= 'a'. Should throw.
        final e2Bad2 = TestEntry('B2')..rank = 'a';
        expect(() => e3.insertBefore(e2Bad2), throwsArgumentError);

        // Valid insert
        final e2Good = TestEntry('BGood')..rank = 'b';
        e3.insertBefore(e2Good);
        expect(e2Good.list, list);
        list.validate();
      });
    });

    test('indexedList caching works', () {
      final e1 = TestEntry('A');
      list.add(e1);

      final list1 = list.indexedList;
      final list2 = list.indexedList;

      expect(identical(list1, list2), isTrue);

      // Modifying list should invalidate cache
      list.add(TestEntry('B'));
      final list3 = list.indexedList;
      expect(identical(list1, list3), isFalse);
    });

    test('operator [] access', () {
      final e1 = TestEntry('A');
      final e2 = TestEntry('B');
      list.add(e1);
      list.add(e2);

      expect(list[0], equals(e1));
      expect(list[1], equals(e2));
      expect(() => list[2], throwsRangeError);
      expect(() => list[-1], throwsRangeError);
    });

    test('Unlinking updates dirty state', () {
      final e1 = TestEntry('A');
      list.add(e1);

      // cache it
      var l = list.indexedList;
      expect(l.length, 1);

      e1.unlink();
      expect(list.indexedList.isEmpty, isTrue);
    });

    test('validate throws on inconsistent ranks', () {
      // This is a bit tricky since we can't easily modify rank without re-inserting or using private setters if exposed,
      // but the setter is public.

      final e1 = TestEntry('A')..rank = 'a';
      final e2 = TestEntry('B')..rank = 'c';
      list.add(e1);
      list.add(e2);

      list.validate(); // should pass

      // Manually mess up rank to violate order
      e1.rank = 'd';
      // Now list is A('d') -> B('c'). Sorted order would be B, A. But list link is A -> B.

      expect(() => list.validate(), throwsException);
    });

    test('insert at correct position', () {
      final e1 = TestEntry('A')..rank = 'b';
      final e3 = TestEntry('C')..rank = 'd';
      list.add(e1);
      list.add(e3);

      final e2 = TestEntry('B')..rank = 'c';
      list.insert(e2.rank!, e2);

      expect(list.toList(), equals([e1, e2, e3]));
      expect(e1.rank!.compareTo(e2.rank!) < 0, isTrue);
      expect(e2.rank!.compareTo(e3.rank!) < 0, isTrue);

      // Add to end
      final e4 = TestEntry('D')..rank = 'e';
      list.insert(e4.rank!, e4);
      expect(list.last, equals(e4));

      // Add to start
      final e0 = TestEntry('Start')..rank = 'a';
      list.insert(e0.rank!, e0);
      expect(list.first, equals(e0));

      list.validate();
    });

    test('insert throws on duplicate rank', () {
      final e1 = TestEntry('A')..rank = 'a';
      list.add(e1);

      final e2 = TestEntry('B')..rank = 'a';
      expect(() => list.insert(e2.rank!, e2), throwsException);
    });

    test('insert works with empty list', () {
      final e1 = TestEntry('A')..rank = 'a';
      list.insert(e1.rank!, e1);
      expect(list.length, 1);
      expect(list.first, equals(e1));
      list.validate();
    });

    test('insert maintains sort order when adding items in random order', () {
      final entries = [
        TestEntry('C')..rank = 'c',
        TestEntry('A')..rank = 'a',
        TestEntry('E')..rank = 'e',
        TestEntry('B')..rank = 'b',
        TestEntry('D')..rank = 'd',
      ];

      for (final e in entries) {
        list.insert(e.rank!, e);
      }

      list.validate();
      expect(list.length, 5);

      final ids = list.map((e) => e.id).toList();
      expect(ids, equals(['A', 'B', 'C', 'D', 'E']));
    });
  });
}
