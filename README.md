Character Parser
================

Port of [ForbesLindesay/character-parser](https://github.com/ForbesLindesay/character-parser).

Parse Dart one character at a time to look for snippets in Templates. 

## [Installing via Pub](http://pub.dartlang.org/packages/character_parser)	

Add this to your package's pubspec.yaml file:

	dependencies:
	  character_parser: 0.1.2


## Usage

Work out how much depth changes:

```dart
var state = parse('foo(arg1, arg2, {\n  foo: [a, b\n');
assert(state.roundDepth == 1);
assert(state.curlyDepth == 1);
assert(state.squareDepth == 1);

parse('    c, d]\n  })', state:state);
assert(state.squareDepth == 0);
assert(state.curlyDepth == 0);
assert(state.roundDepth == 0);
```

### Bracketed Expressions

Find all the contents of a bracketed expression:

```dart
var section = parseMax('foo="(", bar="}") bing bong');
assert(section.start == 0);
assert(section.end == 16);//exclusive end of string
assert(section.src == 'foo="(", bar="}"');

section = parseMax('{foo="(", bar="}"} bing bong', start:1);
assert(section.start == 1);
assert(section.end == 17);//exclusive end of string
assert(section.src == 'foo="(", bar="}"');
```

The bracketed expression parsing simply parses up to but excluding the first unmatched closed bracket (), }, ]). 
It is clever enough to ignore brackets in comments or strings.

### Custom Delimited Expressions

Find code up to a custom delimiter:

```dart
var section = parseUntil('foo.bar("%>").baz%> bing bong', '%>');
assert(section.start == 0);
assert(section.end == 17);//exclusive end of string
assert(section.src == 'foo.bar("%>").baz');

section = parseUntil('<%foo.bar("%>").baz%> bing bong', '%>', start:2);
assert(section.start == 2);
assert(section.end == 19);//exclusive end of string
assert(section.src == 'foo.bar("%>").baz');
```

Delimiters are ignored if they are inside strings or comments.

## API

### ParserState parse(src, {ParserState state:null, int start:0, int end:null})

Parse a string starting at the index start, and return the state after parsing that string.

If you want to parse one string in multiple sections you should keep passing the resulting state to the next parse operation.

The resulting object has the ParserState structure:

	{
	  lineComment: false, //true if inside a line comment
	  blockComment: false, //true if inside a block comment
	
	  singleQuote: false, //true if inside a single quoted string
	  doubleQuote: false, //true if inside a double quoted string
	  escaped: false, //true if in a string and the last character was an escape character
	
	  roundDepth: 0, //number of un-closed open `(` brackets
	  curlyDepth: 0, //number of un-closed open `{` brackets
	  squareDepth: 0 //number of un-closed open `[` brackets
	}
	
### SrcPosition parseMax(src, {int start:0})

Parses the source until the first unmatched close bracket (any of ), }, ]). 
It returns a SrcPosition with the structure:

	{
	  start: 0,//index of first character of string
	  end: 13,//index of first character after the end of string
	  src: 'source string'
	}
	
### SrcPosition parseUntil(src, delimiter, {int start:0, bool includeLineComment:false}){

Parses the source until the first occurence of delimiter which is not in a string or a comment. 
If `includeLineComment` is true, it will still count if the delimiter occurs in a line comment, 
but not in a block comment. It returns a SrcPosition with the structure:

	{
	  start: 0,//index of first character of string
	  end: 13,//index of first character after the end of string
	  src: 'source string'
	}

### ParserState parseChar(character, [ParserState state])

Parses the single character and returns the state. See parse for the structure of the returned state object. 
N.B. character must be a single character not a multi character string.

### ParserState defaultState()

Get a default starting ParserState. 

------

### Contributors

  - [mythz](https://github.com/mythz) (Demis Bellot)
