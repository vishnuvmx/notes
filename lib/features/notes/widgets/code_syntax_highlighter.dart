import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Semantic token kinds produced by language-specific lexers.
enum _TokenKind {
  comment,
  string,
  annotation,
  property,
  variable,
  number,
  keyword,
  type,
  literal,
  function,
  operator,
  identifier,
}

class _PatternRule {
  final String pattern;
  final _TokenKind kind;
  const _PatternRule(this.pattern, this.kind);
}

class _LanguageSpec {
  final List<_PatternRule> rules;
  final Set<String> keywords;
  final Set<String> types;
  final Set<String> literals;
  final Set<String> builtins;
  final bool caseInsensitiveKeywords;
  final bool pascalCaseAsType;

  const _LanguageSpec({
    required this.rules,
    this.keywords = const {},
    this.types = const {},
    this.literals = const {},
    this.builtins = const {},
    this.caseInsensitiveKeywords = false,
    this.pascalCaseAsType = true,
  });
}

class _CompiledGrammar {
  final RegExp regex;
  final List<_TokenKind> kinds;
  final _LanguageSpec spec;

  _CompiledGrammar(this.spec)
      : kinds = spec.rules.map((r) => r.kind).toList(growable: false),
        regex = RegExp(
          spec.rules.map((r) => '(${r.pattern})').join('|'),
          multiLine: true,
        );
}

/// Multi-language code syntax highlighter with language-specific lexers and
/// JetBrains Mono typography.
class CodeSyntaxHighlighter {
  CodeSyntaxHighlighter._();

  static final Map<String, _CompiledGrammar> _grammarCache = {};

  static const String _cComments = r'//[^\n]*|/\*[\s\S]*?\*/';
  static const String _hashComment = r'#[^\n]*';
  static const String _doubleString = r'"(?:\\.|[^"\\\n])*"';
  static const String _singleString = r"'(?:\\.|[^'\\\n])*'";
  static const String _backtickString = r'`(?:\\.|[^`\\])*`';
  static const String _numberLiteral =
      r'\b0[xXbBoO][0-9a-fA-F_]+\b|\b\d[\d_]*(?:\.\d[\d_]*)?(?:[eE][+-]?\d+)?\b';
  static const String _ident = r'\b[A-Za-z_][A-Za-z0-9_]*\b';
  static const String _stdOps =
      r'=>|->|::|\|>|===|!==|==|!=|<=|>=|&&|\|\||\?\?|\+\+|--|[+\-*/%=<>!&|^~?:]';

  static String _normalizeLanguage(String? language) {
    final lang = (language ?? '').trim().toLowerCase();
    switch (lang) {
      case 'dart':
      case 'flutter':
        return 'dart';
      case 'py':
      case 'python':
      case 'python3':
        return 'python';
      case 'js':
      case 'javascript':
      case 'mjs':
      case 'cjs':
      case 'jsx':
        return 'javascript';
      case 'ts':
      case 'typescript':
      case 'tsx':
        return 'typescript';
      case 'json':
        return 'json';
      case 'jsonc':
      case 'json5':
        return 'jsonc';
      case 'yaml':
      case 'yml':
        return 'yaml';
      case 'sql':
      case 'postgres':
      case 'postgresql':
      case 'sqlite':
      case 'mysql':
      case 'plsql':
        return 'sql';
      case 'sh':
      case 'bash':
      case 'zsh':
      case 'shell':
      case 'console':
      case 'ps1':
      case 'powershell':
        return 'shell';
      case 'html':
      case 'htm':
      case 'xml':
      case 'svg':
        return 'html';
      case 'css':
      case 'scss':
      case 'sass':
        return 'css';
      case 'rs':
      case 'rust':
        return 'rust';
      case 'go':
      case 'golang':
        return 'go';
      case 'kt':
      case 'kotlin':
      case 'kts':
        return 'kotlin';
      case 'java':
        return 'java';
      case 'c':
      case 'h':
      case 'cpp':
      case 'cc':
      case 'cxx':
      case 'c++':
      case 'hpp':
        return 'cpp';
      case 'cs':
      case 'csharp':
      case 'c#':
        return 'csharp';
      case 'md':
      case 'markdown':
        return 'markdown';
      default:
        return 'generic';
    }
  }

  static _CompiledGrammar _grammarFor(String langKey) {
    return _grammarCache.putIfAbsent(langKey, () {
      return _CompiledGrammar(_buildSpec(langKey));
    });
  }

  static _LanguageSpec _buildSpec(String langKey) {
    switch (langKey) {
      case 'dart':
        return const _LanguageSpec(
          rules: [
            _PatternRule(_cComments, _TokenKind.comment),
            _PatternRule(
              r'''r?"""[\s\S]*?"""|r?\x27\x27\x27[\s\S]*?\x27\x27\x27|r?"(?:\\.|[^"\\\n])*"|r?\x27(?:\\.|[^\x27\\\n])*\x27''',
              _TokenKind.string,
            ),
            _PatternRule(r'@[A-Za-z_][A-Za-z0-9_]*', _TokenKind.annotation),
            _PatternRule(_numberLiteral, _TokenKind.number),
            _PatternRule(_ident, _TokenKind.identifier),
            _PatternRule(_stdOps, _TokenKind.operator),
          ],
          keywords: {
            'abstract', 'as', 'assert', 'async', 'await', 'base', 'break',
            'case', 'catch', 'class', 'const', 'continue', 'covariant',
            'default', 'deferred', 'do', 'dynamic', 'else', 'enum', 'export',
            'extends', 'extension', 'external', 'factory', 'final', 'finally',
            'for', 'Function', 'get', 'hide', 'if', 'implements', 'import',
            'in', 'interface', 'is', 'late', 'library', 'mixin', 'new', 'of',
            'on', 'operator', 'part', 'required', 'rethrow', 'return', 'sealed',
            'set', 'show', 'static', 'super', 'switch', 'sync', 'this', 'throw',
            'try', 'typedef', 'var', 'void', 'when', 'while', 'with', 'yield',
          },
          literals: {'true', 'false', 'null'},
          types: {
            'int', 'double', 'num', 'bool', 'String', 'List', 'Map', 'Set',
            'Iterable', 'Future', 'Stream', 'Object', 'Never', 'Symbol',
            'Duration', 'DateTime', 'Uri', 'RegExp', 'Widget', 'BuildContext',
            'State', 'StatelessWidget', 'StatefulWidget', 'Color', 'EdgeInsets',
            'TextSpan', 'InlineSpan', 'CustomPainter', 'Canvas', 'Size', 'Offset',
          },
          builtins: {'print', 'debugPrint', 'identical'},
        );

      case 'python':
        return const _LanguageSpec(
          rules: [
            _PatternRule(_hashComment, _TokenKind.comment),
            _PatternRule(
              r'''[rfbuRFBU]{0,2}"""[\s\S]*?"""|[rfbuRFBU]{0,2}\x27\x27\x27[\s\S]*?\x27\x27\x27|[rfbuRFBU]{0,2}"(?:\\.|[^"\\\n])*"|[rfbuRFBU]{0,2}\x27(?:\\.|[^\x27\\\n])*\x27''',
              _TokenKind.string,
            ),
            _PatternRule(r'@[A-Za-z_][A-Za-z0-9_.]*', _TokenKind.annotation),
            _PatternRule(_numberLiteral, _TokenKind.number),
            _PatternRule(_ident, _TokenKind.identifier),
            _PatternRule(_stdOps, _TokenKind.operator),
          ],
          keywords: {
            'and', 'as', 'assert', 'async', 'await', 'break', 'case', 'class',
            'continue', 'def', 'del', 'elif', 'else', 'except', 'finally',
            'for', 'from', 'global', 'if', 'import', 'in', 'is', 'lambda',
            'match', 'nonlocal', 'not', 'or', 'pass', 'raise', 'return', 'try',
            'while', 'with', 'yield',
          },
          literals: {'True', 'False', 'None', 'self', 'cls'},
          types: {
            'int', 'float', 'str', 'bool', 'list', 'dict', 'set', 'tuple',
            'bytes', 'bytearray', 'frozenset', 'object', 'Any', 'Optional',
            'Union', 'List', 'Dict', 'Tuple', 'Set', 'Callable', 'Iterable',
            'Sequence', 'Mapping', 'Exception', 'ValueError', 'TypeError',
          },
          builtins: {
            'print', 'len', 'range', 'enumerate', 'zip', 'map', 'filter',
            'sorted', 'reversed', 'sum', 'min', 'max', 'abs', 'any', 'all',
            'open', 'super', 'type', 'isinstance', 'issubclass', 'hasattr',
            'getattr', 'setattr', 'input', 'id',
          },
        );

      case 'javascript':
      case 'typescript':
        return _LanguageSpec(
          rules: const [
            _PatternRule(_cComments, _TokenKind.comment),
            _PatternRule(
              '$_backtickString|$_doubleString|$_singleString',
              _TokenKind.string,
            ),
            _PatternRule(r'@[A-Za-z_][A-Za-z0-9_]*', _TokenKind.annotation),
            _PatternRule(_numberLiteral, _TokenKind.number),
            _PatternRule(
              r'(?<![A-Za-z0-9_.])[A-Za-z_$][A-Za-z0-9_$]*(?=\s*:(?!:))',
              _TokenKind.property,
            ),
            _PatternRule(r'\b[A-Za-z_$][A-Za-z0-9_$]*\b', _TokenKind.identifier),
            _PatternRule(_stdOps, _TokenKind.operator),
          ],
          keywords: {
            'as', 'async', 'await', 'break', 'case', 'catch', 'class', 'const',
            'continue', 'debugger', 'default', 'delete', 'do', 'else', 'export',
            'extends', 'finally', 'for', 'from', 'function', 'get', 'if',
            'import', 'in', 'instanceof', 'let', 'new', 'of', 'return', 'set',
            'static', 'super', 'switch', 'this', 'throw', 'try', 'typeof',
            'var', 'void', 'while', 'with', 'yield',
            if (langKey == 'typescript') ...{
              'abstract', 'declare', 'enum', 'implements', 'interface', 'is',
              'keyof', 'module', 'namespace', 'override', 'private', 'protected',
              'public', 'readonly', 'satisfies', 'type', 'infer', 'asserts',
            },
          },
          literals: const {'true', 'false', 'null', 'undefined', 'NaN', 'Infinity'},
          types: const {
            'number', 'string', 'boolean', 'symbol', 'bigint', 'object',
            'unknown', 'any', 'never', 'Promise', 'Array', 'Record', 'Map',
            'Set', 'Partial', 'Required', 'Pick', 'Omit', 'Readonly', 'Date',
            'Error', 'RegExp', 'Math', 'JSON', 'console', 'document', 'window',
          },
          builtins: const {
            'parseInt', 'parseFloat', 'isNaN', 'setTimeout', 'setInterval',
            'fetch', 'require',
          },
        );

      case 'json':
      case 'jsonc':
        return _LanguageSpec(
          pascalCaseAsType: false,
          rules: [
            if (langKey == 'jsonc')
              const _PatternRule(_cComments, _TokenKind.comment),
            const _PatternRule(r'"(?:\\.|[^"\\\n])*"(?=\s*:)', _TokenKind.property),
            const _PatternRule(_doubleString, _TokenKind.string),
            const _PatternRule(r'-?\b\d+(?:\.\d+)?(?:[eE][+-]?\d+)?\b', _TokenKind.number),
            const _PatternRule(r'\b(?:true|false|null)\b', _TokenKind.literal),
            const _PatternRule(r'[{}\[\]:,]', _TokenKind.operator),
          ],
        );

      case 'yaml':
        return const _LanguageSpec(
          pascalCaseAsType: false,
          rules: [
            _PatternRule(_hashComment, _TokenKind.comment),
            _PatternRule(r'^(?:---|\.\.\.)(?=\s|$)', _TokenKind.keyword),
            _PatternRule(r'[A-Za-z0-9_.-]+(?=\s*:)', _TokenKind.property),
            _PatternRule('$_doubleString|$_singleString', _TokenKind.string),
            _PatternRule(r'[&*][A-Za-z0-9_-]+', _TokenKind.annotation),
            _PatternRule(r'\b(?:true|false|yes|no|on|off|null|~)\b', _TokenKind.literal),
            _PatternRule(_numberLiteral, _TokenKind.number),
            _PatternRule(r'[:\-\[\]{}|>]', _TokenKind.operator),
          ],
        );

      case 'sql':
        return const _LanguageSpec(
          caseInsensitiveKeywords: true,
          pascalCaseAsType: false,
          rules: [
            _PatternRule(r'--[^\n]*|/\*[\s\S]*?\*/', _TokenKind.comment),
            _PatternRule(r"'(?:''|[^'])*'", _TokenKind.string),
            _PatternRule(r'"(?:""|[^"])*"|`[^`]*`', _TokenKind.property),
            _PatternRule(_numberLiteral, _TokenKind.number),
            _PatternRule(_ident, _TokenKind.identifier),
            _PatternRule(r'<>|!=|<=|>=|::|\|\||[=<>+\-*/%(),;.]', _TokenKind.operator),
          ],
          keywords: {
            'SELECT', 'FROM', 'WHERE', 'INSERT', 'INTO', 'VALUES', 'UPDATE',
            'SET', 'DELETE', 'CREATE', 'ALTER', 'DROP', 'TABLE', 'INDEX',
            'VIEW', 'JOIN', 'INNER', 'LEFT', 'RIGHT', 'FULL', 'OUTER', 'CROSS',
            'ON', 'USING', 'AS', 'AND', 'OR', 'NOT', 'IN', 'IS', 'LIKE',
            'ILIKE', 'BETWEEN', 'EXISTS', 'HAVING', 'GROUP', 'BY', 'ORDER',
            'ASC', 'DESC', 'LIMIT', 'OFFSET', 'DISTINCT', 'UNION', 'ALL',
            'CASE', 'WHEN', 'THEN', 'ELSE', 'END', 'PRIMARY', 'KEY', 'FOREIGN',
            'REFERENCES', 'CONSTRAINT', 'DEFAULT', 'UNIQUE', 'CHECK',
            'RETURNING', 'WITH', 'BEGIN', 'COMMIT', 'ROLLBACK', 'EXPLAIN',
            'IF', 'CASCADE', 'TRUNCATE', 'PRAGMA',
          },
          literals: {'NULL', 'TRUE', 'FALSE'},
          types: {
            'INT', 'INTEGER', 'BIGINT', 'SMALLINT', 'SERIAL', 'BIGSERIAL',
            'TEXT', 'VARCHAR', 'CHAR', 'BOOLEAN', 'BOOL', 'DATE', 'TIME',
            'TIMESTAMP', 'TIMESTAMPTZ', 'UUID', 'JSON', 'JSONB', 'NUMERIC',
            'DECIMAL', 'REAL', 'DOUBLE', 'FLOAT', 'BLOB', 'BYTEA',
          },
          builtins: {
            'COUNT', 'SUM', 'AVG', 'MIN', 'MAX', 'COALESCE', 'NULLIF', 'CAST',
            'LOWER', 'UPPER', 'TRIM', 'LENGTH', 'NOW', 'CURRENT_TIMESTAMP',
            'DATE_TRUNC', 'EXTRACT', 'ROW_NUMBER', 'RANK', 'DENSE_RANK',
          },
        );

      case 'shell':
        return const _LanguageSpec(
          pascalCaseAsType: false,
          rules: [
            _PatternRule(_hashComment, _TokenKind.comment),
            _PatternRule(
              r'"(?:\\.|[^"\\])*"|\x27[^\x27]*\x27',
              _TokenKind.string,
            ),
            _PatternRule(
              r'\$\{[^}\n]+\}|\$[A-Za-z_][A-Za-z0-9_]*|\$[0-9@*#?$!-]',
              _TokenKind.variable,
            ),
            _PatternRule(r'(?<=\s)--?[A-Za-z0-9_-]+', _TokenKind.property),
            _PatternRule(_numberLiteral, _TokenKind.number),
            _PatternRule(_ident, _TokenKind.identifier),
            _PatternRule(r'&&|\|\||>>|<<|\|>|[|&;<>()=]', _TokenKind.operator),
          ],
          keywords: {
            'if', 'then', 'elif', 'else', 'fi', 'for', 'in', 'do', 'done',
            'while', 'until', 'case', 'esac', 'function', 'return', 'local',
            'export', 'source', 'alias', 'exit', 'break', 'continue', 'set',
            'unset', 'readonly', 'declare', 'select',
          },
          literals: {'true', 'false'},
          builtins: {
            'echo', 'printf', 'cd', 'pwd', 'ls', 'grep', 'sed', 'awk', 'find',
            'xargs', 'curl', 'wget', 'git', 'flutter', 'dart', 'npm', 'npx',
            'pnpm', 'pip', 'python', 'docker', 'sudo', 'chmod', 'chown',
            'mkdir', 'rm', 'cp', 'mv', 'cat', 'head', 'tail', 'sort', 'uniq',
          },
        );

      case 'html':
        return const _LanguageSpec(
          pascalCaseAsType: false,
          rules: [
            _PatternRule(r'<!--[\s\S]*?-->', _TokenKind.comment),
            _PatternRule('$_doubleString|$_singleString', _TokenKind.string),
            _PatternRule(r'</?[A-Za-z0-9:_-]+|/?>', _TokenKind.keyword),
            _PatternRule(r'[A-Za-z0-9:_-]+(?=\s*=)', _TokenKind.property),
            _PatternRule(r'&[A-Za-z0-9#]+;', _TokenKind.number),
            _PatternRule(r'=', _TokenKind.operator),
          ],
        );

      case 'css':
        return const _LanguageSpec(
          pascalCaseAsType: false,
          rules: [
            _PatternRule(_cComments, _TokenKind.comment),
            _PatternRule('$_doubleString|$_singleString', _TokenKind.string),
            _PatternRule(r'@[A-Za-z_-]+', _TokenKind.annotation),
            _PatternRule(r'--[A-Za-z0-9_-]+', _TokenKind.variable),
            _PatternRule(r'#[0-9a-fA-F]{3,8}\b', _TokenKind.number),
            _PatternRule(r'[a-zA-Z-]+(?=\s*:)', _TokenKind.property),
            _PatternRule(
              r'\b\d+(?:\.\d+)?(?:px|rem|em|vh|vw|vmin|vmax|%|deg|rad|s|ms|fr)?\b',
              _TokenKind.number,
            ),
            _PatternRule(r'!important\b', _TokenKind.keyword),
            _PatternRule(_ident, _TokenKind.identifier),
            _PatternRule(r'[{}:;,>+~*]', _TokenKind.operator),
          ],
        );

      case 'rust':
        return const _LanguageSpec(
          rules: [
            _PatternRule(_cComments, _TokenKind.comment),
            _PatternRule(_doubleString, _TokenKind.string),
            _PatternRule(r'#!?\[[^\]\n]*\]', _TokenKind.annotation),
            _PatternRule(r"'(?:[a-zA-Z_][a-zA-Z0-9_]*\b|static\b)", _TokenKind.variable),
            _PatternRule(r'\b[a-zA-Z_][a-zA-Z0-9_]*!', _TokenKind.function),
            _PatternRule(_numberLiteral, _TokenKind.number),
            _PatternRule(_ident, _TokenKind.identifier),
            _PatternRule(_stdOps, _TokenKind.operator),
          ],
          keywords: {
            'as', 'async', 'await', 'break', 'const', 'continue', 'crate',
            'dyn', 'else', 'enum', 'extern', 'fn', 'for', 'if', 'impl', 'in',
            'let', 'loop', 'match', 'mod', 'move', 'mut', 'pub', 'ref',
            'return', 'self', 'Self', 'static', 'struct', 'super', 'trait',
            'type', 'unsafe', 'use', 'where', 'while',
          },
          literals: {'true', 'false'},
          types: {
            'bool', 'char', 'str', 'i8', 'i16', 'i32', 'i64', 'i128', 'isize',
            'u8', 'u16', 'u32', 'u64', 'u128', 'usize', 'f32', 'f64',
            'String', 'Vec', 'Option', 'Result', 'Box', 'Rc', 'Arc', 'Some',
            'None', 'Ok', 'Err', 'HashMap', 'HashSet',
          },
        );

      case 'go':
        return const _LanguageSpec(
          rules: [
            _PatternRule(_cComments, _TokenKind.comment),
            _PatternRule(
              '$_backtickString|$_doubleString|$_singleString',
              _TokenKind.string,
            ),
            _PatternRule(_numberLiteral, _TokenKind.number),
            _PatternRule(_ident, _TokenKind.identifier),
            _PatternRule(r':=|<-|<<|>>|\.\.\.|' + _stdOps, _TokenKind.operator),
          ],
          keywords: {
            'break', 'case', 'chan', 'const', 'continue', 'default', 'defer',
            'else', 'fallthrough', 'for', 'func', 'go', 'goto', 'if', 'import',
            'interface', 'map', 'package', 'range', 'return', 'select',
            'struct', 'switch', 'type', 'var',
          },
          literals: {'true', 'false', 'nil', 'iota'},
          types: {
            'bool', 'byte', 'complex64', 'complex128', 'error', 'float32',
            'float64', 'int', 'int8', 'int16', 'int32', 'int64', 'rune',
            'string', 'uint', 'uint8', 'uint16', 'uint32', 'uint64', 'uintptr',
            'any', 'comparable',
          },
          builtins: {
            'append', 'cap', 'clear', 'close', 'copy', 'delete', 'len', 'make',
            'max', 'min', 'new', 'panic', 'print', 'println', 'recover',
          },
        );

      case 'kotlin':
      case 'java':
      case 'cpp':
      case 'csharp':
        return _LanguageSpec(
          rules: [
            const _PatternRule(_cComments, _TokenKind.comment),
            if (langKey == 'cpp')
              const _PatternRule(r'^\s*#[A-Za-z_][^\n]*', _TokenKind.annotation),
            const _PatternRule(
              r'"""[\s\S]*?"""|"[^"\\\n]*(?:\\.[^"\\\n]*)*"|\x27(?:\\.|[^\x27\\\n])*\x27',
              _TokenKind.string,
            ),
            const _PatternRule(r'@[A-Za-z_][A-Za-z0-9_]*', _TokenKind.annotation),
            const _PatternRule(_numberLiteral, _TokenKind.number),
            const _PatternRule(_ident, _TokenKind.identifier),
            const _PatternRule(_stdOps, _TokenKind.operator),
          ],
          keywords: {
            'abstract', 'as', 'break', 'case', 'catch', 'class', 'const',
            'continue', 'default', 'do', 'else', 'enum', 'extends', 'final',
            'finally', 'for', 'if', 'implements', 'import', 'in', 'interface',
            'is', 'new', 'operator', 'out', 'override', 'package', 'private',
            'protected', 'public', 'return', 'sealed', 'static', 'struct',
            'super', 'switch', 'this', 'throw', 'try', 'typedef', 'using',
            'val', 'var', 'virtual', 'void', 'while', 'when', 'fun', 'object',
            'companion', 'data', 'suspend', 'inline', 'lateinit', 'namespace',
            'template', 'typename', 'auto', 'constexpr', 'async', 'await',
          },
          literals: const {'true', 'false', 'null', 'nullptr'},
          types: const {
            'int', 'long', 'short', 'byte', 'float', 'double', 'char', 'bool',
            'boolean', 'void', 'String', 'Int', 'Long', 'Double', 'Float',
            'Boolean', 'Unit', 'Any', 'List', 'MutableList', 'Map', 'Set',
            'size_t', 'std', 'vector', 'string', 'Task', 'IEnumerable',
          },
          builtins: const {'println', 'print', 'printf', 'sizeof'},
        );

      case 'markdown':
        return const _LanguageSpec(
          pascalCaseAsType: false,
          rules: [
            _PatternRule(r'^#{1,6}\s[^\n]*', _TokenKind.keyword),
            _PatternRule(r'^\s*>[^\n]*', _TokenKind.comment),
            _PatternRule(r'`[^`\n]+`', _TokenKind.string),
            _PatternRule(r'\*\*[^*\n]+\*\*', _TokenKind.type),
            _PatternRule(r'\[[^\]\n]+\]\([^)\n]+\)', _TokenKind.function),
            _PatternRule(r'^\s*(?:[-*+]|\d+\.)\s', _TokenKind.operator),
          ],
        );

      case 'generic':
      default:
        return const _LanguageSpec(
          rules: [
            _PatternRule('$_cComments|$_hashComment', _TokenKind.comment),
            _PatternRule(
              '$_doubleString|$_singleString|$_backtickString',
              _TokenKind.string,
            ),
            _PatternRule(r'@[A-Za-z_][A-Za-z0-9_]*', _TokenKind.annotation),
            _PatternRule(_numberLiteral, _TokenKind.number),
            _PatternRule(_ident, _TokenKind.identifier),
            _PatternRule(_stdOps, _TokenKind.operator),
          ],
          keywords: {
            'abstract', 'as', 'async', 'await', 'break', 'case', 'catch',
            'class', 'const', 'continue', 'default', 'def', 'do', 'else',
            'enum', 'export', 'extends', 'final', 'finally', 'fn', 'for',
            'from', 'function', 'func', 'if', 'implements', 'import', 'in',
            'interface', 'is', 'let', 'match', 'new', 'of', 'package',
            'private', 'protected', 'pub', 'public', 'return', 'static',
            'struct', 'super', 'switch', 'this', 'throw', 'try', 'type',
            'typedef', 'var', 'void', 'while', 'with', 'yield',
          },
          literals: {'true', 'false', 'True', 'False', 'null', 'nil', 'none', 'None'},
          types: {
            'bool', 'boolean', 'double', 'float', 'int', 'long', 'num', 'void',
            'String', 'List', 'Map', 'Set', 'Future', 'Stream', 'Widget',
            'Object', 'Promise', 'Array', 'Record', 'Any',
          },
        );
    }
  }

  /// Highlights [code] using language-specific rules when [language] is given.
  static List<TextSpan> highlight(
    String code, {
    required bool isDark,
    String? language,
    TextStyle? baseStyle,
  }) {
    final style = baseStyle ??
        GoogleFonts.jetBrainsMono(
          fontSize: 12.5,
          height: 1.52,
          letterSpacing: -0.1,
          color: isDark ? const Color(0xFFABB2BF) : const Color(0xFF2E3440),
        );

    if (code.isEmpty) {
      return [TextSpan(text: '', style: style)];
    }

    final langKey = _normalizeLanguage(language);
    final grammar = _grammarFor(langKey);
    final spec = grammar.spec;

    final styles = <_TokenKind, TextStyle>{
      _TokenKind.comment: style.copyWith(
        color: isDark ? const Color(0xFF7E8494) : const Color(0xFF8C93A4),
        fontStyle: FontStyle.italic,
      ),
      _TokenKind.string: style.copyWith(
        color: isDark ? const Color(0xFF98C379) : const Color(0xFF3E8E41),
      ),
      _TokenKind.annotation: style.copyWith(
        color: isDark ? const Color(0xFFE5C07B) : const Color(0xFFB57D05),
        fontWeight: FontWeight.w600,
      ),
      _TokenKind.property: style.copyWith(
        color: isDark ? const Color(0xFFE06C75) : const Color(0xFFBE3455),
        fontWeight: FontWeight.w600,
      ),
      _TokenKind.variable: style.copyWith(
        color: isDark ? const Color(0xFFE06C75) : const Color(0xFFC23B4E),
      ),
      _TokenKind.keyword: style.copyWith(
        color: isDark ? const Color(0xFFC678DD) : const Color(0xFF9C27B0),
        fontWeight: FontWeight.w700,
      ),
      _TokenKind.type: style.copyWith(
        color: isDark ? const Color(0xFFE5C07B) : const Color(0xFFB7791F),
        fontWeight: FontWeight.w600,
      ),
      _TokenKind.number: style.copyWith(
        color: isDark ? const Color(0xFFD19A66) : const Color(0xFFB26200),
        fontWeight: FontWeight.w600,
      ),
      _TokenKind.literal: style.copyWith(
        color: isDark ? const Color(0xFFD19A66) : const Color(0xFFB26200),
        fontWeight: FontWeight.w700,
      ),
      _TokenKind.function: style.copyWith(
        color: isDark ? const Color(0xFF61AFEF) : const Color(0xFF2563EB),
        fontWeight: FontWeight.w600,
      ),
      _TokenKind.operator: style.copyWith(
        color: isDark ? const Color(0xFF56B6C2) : const Color(0xFF06839C),
      ),
    };

    final spans = <TextSpan>[];
    int lastIndex = 0;

    for (final match in grammar.regex.allMatches(code)) {
      if (match.start > lastIndex) {
        spans.add(TextSpan(
          text: code.substring(lastIndex, match.start),
          style: style,
        ));
      }

      _TokenKind kind = _TokenKind.identifier;
      for (int i = 0; i < grammar.kinds.length; i++) {
        if (match.group(i + 1) != null) {
          kind = grammar.kinds[i];
          break;
        }
      }

      final tokenText = match.group(0)!;
      if (kind == _TokenKind.identifier) {
        kind = _classifyIdentifier(tokenText, code, match.end, spec);
      }

      spans.add(TextSpan(
        text: tokenText,
        style: styles[kind] ?? style,
      ));

      lastIndex = match.end;
    }

    if (lastIndex < code.length) {
      spans.add(TextSpan(
        text: code.substring(lastIndex),
        style: style,
      ));
    }

    return spans;
  }

  static _TokenKind _classifyIdentifier(
    String word,
    String code,
    int matchEnd,
    _LanguageSpec spec,
  ) {
    final lookup = spec.caseInsensitiveKeywords ? word.toUpperCase() : word;

    if (spec.keywords.contains(lookup)) return _TokenKind.keyword;
    if (spec.literals.contains(lookup)) return _TokenKind.literal;
    if (spec.types.contains(lookup)) return _TokenKind.type;
    if (spec.builtins.contains(lookup)) return _TokenKind.function;

    if (_isFollowedByCallParen(code, matchEnd)) {
      return _TokenKind.function;
    }

    if (spec.pascalCaseAsType && _isPascalCase(word)) {
      return _TokenKind.type;
    }

    return _TokenKind.identifier;
  }

  static bool _isFollowedByCallParen(String code, int index) {
    int i = index;
    while (i < code.length) {
      final ch = code.codeUnitAt(i);
      if (ch == 0x20 || ch == 0x09) {
        i++;
        continue;
      }
      return ch == 0x28; // '('
    }
    return false;
  }

  static bool _isPascalCase(String word) {
    if (word.length < 2) return false;
    final first = word.codeUnitAt(0);
    if (first < 0x41 || first > 0x5A) return false;
    // Skip ALL_CAPS constants unless mixed case exists.
    for (int i = 1; i < word.length; i++) {
      final c = word.codeUnitAt(i);
      if (c >= 0x61 && c <= 0x7A) return true;
    }
    return false;
  }
}
