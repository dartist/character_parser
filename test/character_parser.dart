import 'package:test/test.dart';
import '../lib/character_parser.dart';

void main() {
  test('works out how much depth changes', () {
    var state = parse('foo(arg1, arg2, {\n  foo: [a, b\n');
    assert(state.roundDepth == 1);
    assert(state.curlyDepth == 1);
    assert(state.squareDepth == 1);

    parse('    c, d]\n  })', state: state);
    assert(state.squareDepth == 0);
    assert(state.curlyDepth == 0);
    assert(state.roundDepth == 0);
  });

  test('finds contents of bracketed expressions', () {
    var section = parseMax('foo="(", bar="}") bing bong');
    assert(section.start == 0);
    assert(section.end == 16); //exclusive end of string
    assert(section.src == 'foo="(", bar="}"');

    section = parseMax('{foo="(", bar="}"} bing bong', start: 1);
    assert(section.start == 1);
    assert(section.end == 17); //exclusive end of string
    assert(section.src == 'foo="(", bar="}"');
  });

  test('finds code up to a custom delimiter', () {
    var section = parseUntil('foo.bar("%>").baz%> bing bong', '%>');
    assert(section.start == 0);
    assert(section.end == 17); //exclusive end of string
    assert(section.src == 'foo.bar("%>").baz');

    section = parseUntil('<%foo.bar("%>").baz%> bing bong', '%>', start: 2);
    assert(section.start == 2);
    assert(section.end == 19); //exclusive end of string
    assert(section.src == 'foo.bar("%>").baz');
  });

  group("regressions", () {
    test('parses regular expressions', () {
      var section = parseMax('foo=/\\//g, bar="}") bing bong');
      assert(section.start == 0);
      assert(section.end == 18); //exclusive end of string
      assert(section.src == 'foo=/\\//g, bar="}"');
    });
  });
}
