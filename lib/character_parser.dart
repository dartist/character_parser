library character_parser;

class SyntaxError extends Error {
  String msg;
  SyntaxError(this.msg);
  String toString() => msg;
}

class ParseError extends Error {
  String msg;
  ParseError(this.msg);
  String toString() => msg;
}

class ParserState {
  bool lineComment = false;
  bool blockComment = false;

  bool singleQuote = false;
  bool doubleQuote = false;
  bool regexp = false;
  bool escaped = false;

  int roundDepth = 0;
  int curlyDepth = 0;
  int squareDepth = 0;

  String history = '';
  String lastChar = '';
}

class SrcPosition {
  int start;
  int end;
  String src;
  SrcPosition({this.start, this.end, this.src});
}

ParserState parse(src, {ParserState state: null, int start: 0, int end: null}) {
  if (state == null) {
    state = defaultState();
  }
  if (end == null) {
    end = src.length;
  }

  var index = start;
  while (index < end) {
    if (state.roundDepth < 0 || state.curlyDepth < 0 || state.squareDepth < 0) {
      throw SyntaxError('Mismatched Bracket: ' + src[index - 1]);
    }
    parseChar(src[index++], state);
  }
  return state;
}

SrcPosition parseMax(src, {int start: 0}) {
  var index = start;
  var state = defaultState();
  while (state.roundDepth >= 0 &&
      state.curlyDepth >= 0 &&
      state.squareDepth >= 0) {
    if (index >= src.length) {
      throw ParseError(
          'The end of the string was reached with no closing bracket found.');
    }
    parseChar(src[index++], state);
  }
  var end = index - 1;
  return SrcPosition(start: start, end: end, src: src.substring(start, end));
}

SrcPosition parseUntil(src, delimiter,
    {int start: 0, bool includeLineComment: false}) {
  var index = start;
  var state = defaultState();
  while (state.singleQuote ||
      state.doubleQuote ||
      state.regexp ||
      state.blockComment ||
      (!includeLineComment && state.lineComment) ||
      !startsWith(src, delimiter, index)) {
    parseChar(src[index++], state);
  }
  var end = index;
  return SrcPosition(start: start, end: end, src: src.substring(start, end));
}

ParserState parseChar(character, [ParserState state]) {
  if (character.length != 1) {
    throw ParseError('Character must be a string of length 1');
  }
  if (state == null) {
    state = defaultState();
  }

  String history;
  var wasComment = state.blockComment || state.lineComment;
  var lastChar = state.history.isNotEmpty ? state.history[0] : '';
  if (state.lineComment) {
    if (character == '\n') {
      state.lineComment = false;
    }
  } else if (state.blockComment) {
    if (state.lastChar == '*' && character == '/') {
      state.blockComment = false;
    }
  } else if (state.singleQuote) {
    if (character == '\'' && !state.escaped) {
      state.singleQuote = false;
    } else if (character == '\\' && !state.escaped) {
      state.escaped = true;
    } else {
      state.escaped = false;
    }
  } else if (state.doubleQuote) {
    if (character == '"' && !state.escaped) {
      state.doubleQuote = false;
    } else if (character == '\\' && !state.escaped) {
      state.escaped = true;
    } else {
      state.escaped = false;
    }
  } else if (state.regexp) {
    if (character == '/' && !state.escaped) {
      state.regexp = false;
    } else if (character == '\\' && !state.escaped) {
      state.escaped = true;
    } else {
      state.escaped = false;
    }
  } else if (lastChar == '/' && character == '/') {
    history = history.substring(1);
    state.lineComment = true;
  } else if (lastChar == '/' && character == '*') {
    history = history.substring(1);
    state.blockComment = true;
  } else if (character == '/') {
    //could be start of regexp or divide sign
    history = state.history.replaceFirst(RegExp("^\s*"), '');
    /*if (history[0] == ')') {
      //unless its an `if`, `while`, `for` or `with` it's a divide
      //this is probably best left though
    } else if (history[0] == '}') {
      //unless it's a function expression, it's a regexp
      //this is probably best left though
    } else */
    if (isPunctuator(history[0])) {
      state.regexp = true;
    } else if (RegExp("/^\w+\b/").hasMatch(history) &&
        isKeyword(RegExp("^\w+\b").firstMatch(history).group(0))) {
      state.regexp = true;
    }
    /*else {
      // assume it's divide
    }*/
  } else if (character == '\'') {
    state.singleQuote = true;
  } else if (character == '"') {
    state.doubleQuote = true;
  } else if (character == '(') {
    state.roundDepth++;
  } else if (character == ')') {
    state.roundDepth--;
  } else if (character == '{') {
    state.curlyDepth++;
  } else if (character == '}') {
    state.curlyDepth--;
  } else if (character == '[') {
    state.squareDepth++;
  } else if (character == ']') {
    state.squareDepth--;
  }
  if (!state.blockComment && !state.lineComment && !wasComment) {
    state.history = character + state.history;
    return state;
  }
}

ParserState defaultState() => ParserState();

bool startsWith(String str, String start, [int i = 0]) =>
    str.substring(i, start.length + i) == start;

bool isPunctuator(String c) {
  var code = c.codeUnitAt(0);

  switch (code) {
    case 46: // . dot
    case 40: // ( open bracket
    case 41: // ) close bracket
    case 59: // ; semicolon
    case 44: // , comma
    case 123: // { open curly brace
    case 125: // } close curly brace
    case 91: // [
    case 93: // ]
    case 58: // :
    case 63: // ?
    case 126: // ~
    case 37: // %
    case 38: // &
    case 42: // *:
    case 43: // +
    case 45: // -
    case 47: // /
    case 60: // <
    case 62: // >
    case 94: // ^
    case 124: // |
    case 33: // !
    case 61: // =
      return true;
    default:
      return false;
  }
}

isKeyword(id) {
  return (id == 'if') ||
      (id == 'in') ||
      (id == 'do') ||
      (id == 'var') ||
      (id == 'for') ||
      (id == 'new') ||
      (id == 'try') ||
      (id == 'let') ||
      (id == 'this') ||
      (id == 'else') ||
      (id == 'case') ||
      (id == 'void') ||
      (id == 'with') ||
      (id == 'enum') ||
      (id == 'while') ||
      (id == 'break') ||
      (id == 'catch') ||
      (id == 'throw') ||
      (id == 'const') ||
      (id == 'yield') ||
      (id == 'class') ||
      (id == 'super') ||
      (id == 'return') ||
      (id == 'typeof') ||
      (id == 'delete') ||
      (id == 'switch') ||
      (id == 'export') ||
      (id == 'import') ||
      (id == 'default') ||
      (id == 'finally') ||
      (id == 'extends') ||
      (id == 'function') ||
      (id == 'continue') ||
      (id == 'debugger') ||
      (id == 'package') ||
      (id == 'private') ||
      (id == 'interface') ||
      (id == 'instanceof') ||
      (id == 'implements') ||
      (id == 'protected') ||
      (id == 'public') ||
      (id == 'static') ||
      (id == 'yield') ||
      (id == 'let');
}
