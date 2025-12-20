import 'dart:collection';
import 'package:collection/collection.dart';
import 'package:fractional_indexing_dart/fractional_indexing_dart.dart';

/// A mixin for entries in a [RankedLinkedList].
///
/// This mixin adds a [rank] property to the entry and overrides insertion methods
/// to ensure that the list remains sorted by rank.
base mixin RankedLinkedListEntry<E extends RankedLinkedListEntry<E>> on LinkedListEntry<E> {
  String? _rank;

  String? get rank => _rank;

  /// The lexicographical rank string of this entry.
  ///
  /// This value is used to determine the order of the entry in the [RankedLinkedList].
  /// If set manually, the user must ensure it maintains the correct order relative
  /// to its neighbors, otherwise insertion methods will throw [ArgumentError].
  set rank(String? value) {
    _rank = value;
  }

  @override
  RankedLinkedList<E>? get list => super.list as RankedLinkedList<E>?;

  /// Inserts [entry] after this entry in the list.
  ///
  /// If [entry] has a [rank], it checks if the rank is valid (strictly between this entry's rank
  /// and the next entry's rank). If invalid, throws [ArgumentError].
  ///
  /// If [entry] does not have a [rank], a new rank is automatically generated between
  /// this entry's rank and the next entry's rank.
  @override
  void insertAfter(E entry) {
    final parentList = list;

    if (entry.rank != null) {
      final entryRank = entry.rank!;
      final currentRank = rank!;
      final nextRank = next?.rank;

      if (entryRank.compareTo(currentRank) <= 0) {
        throw ArgumentError('Invalid Rank: insertAfter when entry.rank ($entryRank), '
            'current rank ($currentRank) must be greater than.');
      }

      if (nextRank != null && entryRank.compareTo(nextRank) >= 0) {
        throw ArgumentError('Invalid Rank: insertAfter when entry.rank ($entryRank), '
            'next rank ($nextRank) must be greater than.');
      }
    } else {
      entry.rank = FractionalIndexing.generateKeyBetween(rank, next?.rank);
    }

    super.insertAfter(entry);
    parentList?.markAsDirty();
  }

  /// Inserts [entry] before this entry in the list.
  ///
  /// If [entry] has a [rank], it checks if the rank is valid (strictly between the previous entry's rank
  /// and this entry's rank). If invalid, throws [ArgumentError].
  ///
  /// If [entry] does not have a [rank], a new rank is automatically generated between
  /// the previous entry's rank and this entry's rank.
  @override
  void insertBefore(E entry) {
    final parentList = list;

    if (entry.rank != null) {
      final entryRank = entry.rank!;
      final currentRank = rank!;
      final prevRank = previous?.rank;

      if (entryRank.compareTo(currentRank) >= 0) {
        throw ArgumentError('Invalid Rank: insertBefore when entry.rank ($entryRank), '
            'current rank ($currentRank) must be less than.');
      }

      if (prevRank != null && entryRank.compareTo(prevRank) <= 0) {
        throw ArgumentError('Invalid Rank: insertBefore when entry.rank ($entryRank), '
            'previous rank ($prevRank) must be greater than.');
      }
    } else {
      entry.rank = FractionalIndexing.generateKeyBetween(previous?.rank, rank);
    }

    super.insertBefore(entry);
    parentList?.markAsDirty();
  }

  @override
  void unlink() {
    final parentList = list;
    super.unlink();
    parentList?.markAsDirty();
  }
}

/// A [LinkedList] that maintains its elements in a sorted order based on their [rank].
///
/// When elements are added without a rank, a rank is automatically generated using fractional indexing.
/// If a rank is provided, it is validated against the surrounding elements to ensure order.
final class RankedLinkedList<E extends RankedLinkedListEntry<E>> extends LinkedList<E> {
  /// Validates that the list is strictly sorted by rank.
  ///
  /// Throws [Exception] if any element is out of order.
  void validate() {
    final originalList = toList();
    final controlList = toList();
    controlList.sort((a, b) => a.rank!.compareTo(b.rank!));
    for (int i = 0; i < controlList.length; i++) {
      final originalEntry = originalList[i];
      final controlEntry = controlList[i];
      if (originalEntry.rank != controlEntry.rank) {
        throw Exception('Rank is not valid');
      }
    }
  }

  @override

  /// Adds [entry] to the beginning of the list.
  ///
  /// If [entry] has a [rank], it must be strictly smaller than the current head's rank.
  /// Otherwise throws [ArgumentError].
  ///
  /// If no rank is provided, one is generated less than the current head's rank.
  void addFirst(E entry) {
    if (entry.rank != null) {
      if (isNotEmpty) {
        final currentHeadRank = first.rank!;

        if (entry.rank!.compareTo(currentHeadRank) >= 0) {
          throw ArgumentError('Invalid Rank for addFirst: entry.rank (${entry.rank}) must be smaller '
              'than current first.rank ($currentHeadRank).');
        }
      }
    }
    super.addFirst(entry);
    entry.rank ??= FractionalIndexing.generateKeyBetween(null, entry.next?.rank);

    markAsDirty();
  }

  @override

  /// Appends [entry] to the end of the list.
  ///
  /// If [entry] has a [rank], it must be strictly greater than the current tail's rank.
  /// Otherwise throws [ArgumentError].
  ///
  /// If no rank is provided, one is generated greater than the current tail's rank.
  void add(E entry) {
    if (entry.rank != null) {
      if (isNotEmpty) {
        final currentTailRank = last.rank!;
        if (entry.rank!.compareTo(currentTailRank) <= 0) {
          throw ArgumentError('Invalid Rank for add/addLast: entry.rank (${entry.rank}) must be greater '
              'than current last.rank ($currentTailRank).');
        }
      }
    }
    super.add(entry);
    entry.rank ??= FractionalIndexing.generateKeyBetween(entry.previous?.rank, null);

    markAsDirty();
  }

  @override
  void addAll(Iterable<E> entries) {
    for (final entry in entries) {
      add(entry);
    }
  }

  /// Inserts [entry] into the list at the position determined by its [rank].
  ///
  /// [entry] MUST have a non-null [rank].
  /// Returns normally if insertion is successful.
  /// Throws [ArgumentError] if [entry.rank] is null.
  /// Throws [Exception] if an entry with the same rank already exists.
  void insert(String rank, E entry) {
    entry.rank = rank;

    final searchList = indexedList;

    if (searchList.isEmpty) {
      add(entry);
      return;
    }

    if (entry.rank!.compareTo(searchList.last.rank!) > 0) {
      add(entry);
      return;
    }

    final index = lowerBound(searchList, entry, compare: (a, b) => a.rank!.compareTo(b.rank!));

    if (index < searchList.length) {
      final existingEntry = searchList[index];

      if (existingEntry.rank == entry.rank) {
        throw Exception('Duplicate Rank: ${entry.rank} already exists.');
      }

      existingEntry.insertBefore(entry);
    } else {
      add(entry);
    }
  }

  /// Marks the list as "dirty", invalidating the cached indexed list.
  ///
  /// This should be called whenever the list structure or element ranks change.
  void markAsDirty() {
    _isDirty = true;
    _cachedIndexedList = null;
  }

  bool _isDirty = true;
  List<E>? _cachedIndexedList;

  /// Returns a random-access list view of the linked list elements.
  ///
  /// This list is cached and recalculated only when the list is marked as dirty.
  List<E> get indexedList {
    if (_isDirty) {
      _cachedIndexedList = toList(growable: false);
      _isDirty = false;
    }
    return _cachedIndexedList!;
  }

  /// Returns the element at the given [index].
  ///
  /// Throws [RangeError] if [index] is out of bounds.
  /// This operation uses the cached [indexedList] for O(1) access after cache population.
  E operator [](int index) {
    if (index < 0 || index >= length) {
      throw RangeError.index(index, this, "Index out of bounds.");
    }
    return indexedList[index];
  }
}
