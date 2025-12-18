// License: CC0 (no rights reserved).

// This is based on https://observablehq.com/@dgreensp/implementing-fractional-indexing

const String base62Digits = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz";

/// `a` may be empty string, `b` is null or non-empty string.
/// `a < b` lexicographically if `b` is non-null.
/// no trailing zeros allowed.
/// digits is a string such as '0123456789' for base 10. Digits must be in
/// ascending character code order!
String midpoint(String a, String? b, String digits) {
  final zero = digits[0];
  if (b != null && a.compareTo(b) >= 0) {
    throw Exception("$a >= $b");
  }
  if ((a.isNotEmpty && a.substring(a.length - 1) == zero) ||
      (b != null && b.isNotEmpty && b.substring(b.length - 1) == zero)) {
    throw Exception("trailing zero");
  }
  if (b != null) {
    // remove longest common prefix. pad `a` with 0s as we
    // go. note that we don't need to pad `b`, because it can't
    // end before `a` while traversing the common prefix.
    int n = 0;
    while (n < b.length && (n < a.length ? a[n] : zero) == b[n]) {
      n++;
    }
    if (n > 0) {
      return b.substring(0, n) + midpoint(a.length > n ? a.substring(n) : "", b.substring(n), digits);
    }
  }
  // first digits (or lack of digit) are different
  final digitA = a.isNotEmpty ? digits.indexOf(a[0]) : 0;
  final digitB = b != null ? digits.indexOf(b[0]) : digits.length;
  if (digitB - digitA > 1) {
    final midDigit = (0.5 * (digitA + digitB)).round();
    return digits[midDigit];
  } else {
    // first digits are consecutive
    if (b != null && b.length > 1) {
      return b.substring(0, 1);
    } else {
      // `b` is null or has length 1 (a single digit).
      // the first digit of `a` is the previous digit to `b`,
      // or 9 if `b` is null.
      // given, for example, midpoint('49', '5'), return
      // '4' + midpoint('9', null), which will become
      // '4' + '9' + midpoint('', null), which is '495'
      return digits[digitA] + midpoint(a.length > 1 ? a.substring(1) : "", null, digits);
    }
  }
}

void validateInteger(String intPart) {
  if (intPart.length != getIntegerLength(intPart[0])) {
    throw Exception("invalid integer part of order key: $intPart");
  }
}

int getIntegerLength(String head) {
  final code = head.codeUnitAt(0);
  if (code >= 'a'.codeUnitAt(0) && code <= 'z'.codeUnitAt(0)) {
    return code - 'a'.codeUnitAt(0) + 2;
  } else if (code >= 'A'.codeUnitAt(0) && code <= 'Z'.codeUnitAt(0)) {
    return 'Z'.codeUnitAt(0) - code + 2;
  } else {
    throw Exception("invalid order key head: $head");
  }
}

String getIntegerPart(String key) {
  final integerPartLength = getIntegerLength(key[0]);
  if (integerPartLength > key.length) {
    throw Exception("invalid order key: $key");
  }
  return key.substring(0, integerPartLength);
}

void validateOrderKey(String key, String digits) {
  if (key == "A${digits[0] * 26}") {
    throw Exception("invalid order key: $key");
  }
  // getIntegerPart will throw if the first character is bad,
  // or the key is too short. we'd call it to check these things
  // even if we didn't need the result
  final i = getIntegerPart(key);
  final f = key.substring(i.length);
  if (f.isNotEmpty && f.substring(f.length - 1) == digits[0]) {
    throw Exception("invalid order key: $key");
  }
}

// note that this may return null, as there is a largest integer
String? incrementInteger(String x, String digits) {
  validateInteger(x);
  final digs = x.split('');
  digs.removeAt(0); // This modifies digs, which is what we want for 'head' extraction? No, split gives new list.
  // Actually in Dart split returns list. head is 0th index.
  // JS: const [head, ...digs] = x.split(""); head is first char, digs is the rest.

  // Let's re-implement split logic carefully
  final headChar = x[0];
  final digsList = x.substring(1).split('');

  bool carry = true;
  for (int i = digsList.length - 1; carry && i >= 0; i--) {
    final d = digits.indexOf(digsList[i]) + 1;
    if (d == digits.length) {
      digsList[i] = digits[0];
    } else {
      digsList[i] = digits[d];
      carry = false;
    }
  }
  if (carry) {
    if (headChar == "Z") {
      return "a${digits[0]}";
    }
    if (headChar == "z") {
      return null;
    }
    final h = String.fromCharCode(headChar.codeUnitAt(0) + 1);
    if (h.compareTo("a") > 0) {
      digsList.add(digits[0]);
    } else {
      digsList.removeLast();
    }
    return h + digsList.join("");
  } else {
    return headChar + digsList.join("");
  }
}

// note that this may return null, as there is a smallest integer
String? decrementInteger(String x, String digits) {
  validateInteger(x);
  final headChar = x[0];
  final digsList = x.substring(1).split('');

  bool borrow = true;
  for (int i = digsList.length - 1; borrow && i >= 0; i--) {
    final d = digits.indexOf(digsList[i]) - 1;
    if (d == -1) {
      digsList[i] = digits.substring(digits.length - 1);
    } else {
      digsList[i] = digits[d];
      borrow = false;
    }
  }
  if (borrow) {
    if (headChar == "a") {
      return "Z${digits.substring(digits.length - 1)}";
    }
    if (headChar == "A") {
      return null;
    }
    final h = String.fromCharCode(headChar.codeUnitAt(0) - 1);
    if (h.compareTo("Z") < 0) {
      digsList.add(digits.substring(digits.length - 1));
    } else {
      digsList.removeLast();
    }
    return h + digsList.join("");
  } else {
    return headChar + digsList.join("");
  }
}

// `a` is an order key or null (START).
// `b` is an order key or null (END).
// `a < b` lexicographically if both are non-null.
// digits is a string such as '0123456789' for base 10. Digits must be in
// ascending character code order!
String generateKeyBetween(String? a, String? b, [String digits = base62Digits]) {
  if (a != null) {
    validateOrderKey(a, digits);
  }
  if (b != null) {
    validateOrderKey(b, digits);
  }
  if (a != null && b != null && a.compareTo(b) >= 0) {
    throw Exception("$a >= $b");
  }
  if (a == null) {
    if (b == null) {
      return "a${digits[0]}";
    }

    final ib = getIntegerPart(b);
    final fb = b.substring(ib.length);
    if (ib == "A${digits[0] * 26}") {
      return ib + midpoint("", fb, digits);
    }
    if (ib.compareTo(b) < 0) {
      return ib;
    }
    final res = decrementInteger(ib, digits);
    if (res == null) {
      throw Exception("cannot decrement any more");
    }
    return res;
  }

  if (b == null) {
    final ia = getIntegerPart(a);
    final fa = a.substring(ia.length);
    final i = incrementInteger(ia, digits);
    return i ?? ia + midpoint(fa, null, digits);
  }

  final ia = getIntegerPart(a);
  final fa = a.substring(ia.length);
  final ib = getIntegerPart(b);
  final fb = b.substring(ib.length);
  if (ia == ib) {
    return ia + midpoint(fa, fb, digits);
  }
  final i = incrementInteger(ia, digits);
  if (i == null) {
    throw Exception("cannot increment any more");
  }
  if (i.compareTo(b) < 0) {
    return i;
  }
  return ia + midpoint(fa, null, digits);
}

/// same preconditions as generateKeysBetween.
/// n >= 0.
/// Returns an array of n distinct keys in sorted order.
/// If a and b are both null, returns [a0, a1, ...]
/// If one or the other is null, returns consecutive "integer"
/// keys. Otherwise, returns relatively short keys between
/// a and b.
List<String> generateNKeysBetween(String? a, String? b, int n, [String digits = base62Digits]) {
  if (n == 0) {
    return [];
  }
  if (n == 1) {
    return [generateKeyBetween(a, b, digits)];
  }
  if (b == null) {
    var c = generateKeyBetween(a, b, digits);
    final result = [c];
    for (int i = 0; i < n - 1; i++) {
      c = generateKeyBetween(c, b, digits);
      result.add(c);
    }
    return result;
  }
  if (a == null) {
    var c = generateKeyBetween(a, b, digits);
    final result = [c];
    for (int i = 0; i < n - 1; i++) {
      c = generateKeyBetween(a, c, digits);
      result.add(c);
    }
    // result.reverse(); // Dart List is not like JS array, reverse returns Iterable
    return result.reversed.toList();
  }
  final mid = (n / 2).floor();
  final c = generateKeyBetween(a, b, digits);
  return [...generateNKeysBetween(a, c, mid, digits), c, ...generateNKeysBetween(c, b, n - mid - 1, digits)];
}
