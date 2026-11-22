/// Zero-regex multi-language code syntax lexer returning flat UTF-16 span
/// triplets `[utf16_start, utf16_end, token_kind_id]`.
///
/// Token kind IDs match Dart `_TokenKind.values` order:
/// 0 = comment
/// 1 = string
/// 2 = annotation
/// 3 = property
/// 4 = variable
/// 5 = number
/// 6 = keyword
/// 7 = type
/// 8 = literal
/// 9 = function
/// 10 = operator
/// 11 = identifier

const KIND_COMMENT: i32 = 0;
const KIND_STRING: i32 = 1;
const KIND_ANNOTATION: i32 = 2;
const KIND_PROPERTY: i32 = 3;
const KIND_VARIABLE: i32 = 4;
const KIND_NUMBER: i32 = 5;
const KIND_KEYWORD: i32 = 6;
const KIND_TYPE: i32 = 7;
const KIND_LITERAL: i32 = 8;
const KIND_FUNCTION: i32 = 9;
const KIND_OPERATOR: i32 = 10;
const KIND_IDENTIFIER: i32 = 11;

#[derive(Copy, Clone, PartialEq, Eq)]
enum Lang {
    Dart,
    Python,
    JavaScript,
    TypeScript,
    Rust,
    Go,
    Kotlin,
    Java,
    Cpp,
    CSharp,
    Sql,
    Json,
    Yaml,
    Shell,
    Html,
    Css,
    Generic,
}

fn parse_lang(raw: &str) -> Lang {
    match raw.trim().to_ascii_lowercase().as_str() {
        "dart" | "flutter" => Lang::Dart,
        "py" | "python" | "python3" => Lang::Python,
        "js" | "javascript" | "mjs" | "cjs" | "jsx" => Lang::JavaScript,
        "ts" | "typescript" | "tsx" => Lang::TypeScript,
        "rs" | "rust" => Lang::Rust,
        "go" | "golang" => Lang::Go,
        "kt" | "kotlin" | "kts" => Lang::Kotlin,
        "java" => Lang::Java,
        "c" | "h" | "cpp" | "cc" | "cxx" | "c++" | "hpp" => Lang::Cpp,
        "cs" | "csharp" | "c#" => Lang::CSharp,
        "sql" | "postgres" | "postgresql" | "sqlite" | "mysql" | "plsql" => Lang::Sql,
        "json" | "jsonc" | "json5" => Lang::Json,
        "yaml" | "yml" => Lang::Yaml,
        "sh" | "bash" | "zsh" | "shell" | "console" | "ps1" | "powershell" => Lang::Shell,
        "html" | "htm" | "xml" | "svg" => Lang::Html,
        "css" | "scss" | "sass" => Lang::Css,
        _ => Lang::Generic,
    }
}

fn is_keyword(lang: Lang, w: &str) -> bool {
    match lang {
        Lang::Dart => matches!(
            w,
            "abstract" | "as" | "assert" | "async" | "await" | "base" | "break" | "case"
                | "catch" | "class" | "const" | "continue" | "covariant" | "default" | "deferred"
                | "do" | "dynamic" | "else" | "enum" | "export" | "extends" | "extension"
                | "external" | "factory" | "final" | "finally" | "for" | "Function" | "get"
                | "hide" | "if" | "implements" | "import" | "in" | "interface" | "is" | "late"
                | "library" | "mixin" | "new" | "on" | "operator" | "part" | "required"
                | "rethrow" | "return" | "sealed" | "set" | "show" | "static" | "super"
                | "switch" | "sync" | "this" | "throw" | "try" | "typedef" | "var" | "void"
                | "when" | "while" | "with" | "yield"
        ),
        Lang::Python => matches!(
            w,
            "and" | "as" | "assert" | "async" | "await" | "break" | "class" | "continue" | "def"
                | "del" | "elif" | "else" | "except" | "finally" | "for" | "from" | "global"
                | "if" | "import" | "in" | "is" | "lambda" | "match" | "nonlocal" | "not" | "or"
                | "pass" | "raise" | "return" | "try" | "while" | "with" | "yield" | "case"
        ),
        Lang::JavaScript | Lang::TypeScript => matches!(
            w,
            "as" | "async" | "await" | "break" | "case" | "catch" | "class" | "const"
                | "continue" | "debugger" | "default" | "delete" | "do" | "else" | "enum"
                | "export" | "extends" | "finally" | "for" | "from" | "function" | "if"
                | "implements" | "import" | "in" | "instanceof" | "interface" | "let" | "new"
                | "of" | "private" | "protected" | "public" | "readonly" | "return" | "static"
                | "super" | "switch" | "this" | "throw" | "try" | "type" | "typeof" | "var"
                | "void" | "while" | "with" | "yield"
        ),
        Lang::Rust => matches!(
            w,
            "as" | "async" | "await" | "break" | "const" | "continue" | "crate" | "dyn" | "else"
                | "enum" | "extern" | "fn" | "for" | "if" | "impl" | "in" | "let" | "loop"
                | "match" | "mod" | "move" | "mut" | "pub" | "ref" | "return" | "self" | "Self"
                | "static" | "struct" | "super" | "trait" | "type" | "unsafe" | "use" | "where"
                | "while"
        ),
        Lang::Go => matches!(
            w,
            "break" | "case" | "chan" | "const" | "continue" | "default" | "defer" | "else"
                | "fallthrough" | "for" | "func" | "go" | "goto" | "if" | "import" | "interface"
                | "map" | "package" | "range" | "return" | "select" | "struct" | "switch"
                | "type" | "var"
        ),
        Lang::Kotlin => matches!(
            w,
            "abstract" | "as" | "break" | "by" | "catch" | "class" | "companion" | "const"
                | "constructor" | "continue" | "data" | "do" | "else" | "enum" | "final"
                | "finally" | "for" | "fun" | "if" | "import" | "in" | "init" | "inline"
                | "interface" | "internal" | "is" | "lateinit" | "object" | "open" | "operator"
                | "out" | "override" | "package" | "private" | "protected" | "public" | "return"
                | "sealed" | "super" | "suspend" | "this" | "throw" | "try" | "typealias" | "val"
                | "var" | "when" | "while"
        ),
        Lang::Java => matches!(
            w,
            "abstract" | "assert" | "break" | "case" | "catch" | "class" | "continue" | "default"
                | "do" | "else" | "enum" | "extends" | "final" | "finally" | "for" | "if"
                | "implements" | "import" | "instanceof" | "interface" | "native" | "new"
                | "package" | "private" | "protected" | "public" | "record" | "return" | "sealed"
                | "static" | "super" | "switch" | "synchronized" | "this" | "throw" | "throws"
                | "try" | "var" | "void" | "volatile" | "while"
        ),
        Lang::Cpp => matches!(
            w,
            "alignas" | "alignof" | "auto" | "break" | "case" | "catch" | "class" | "const"
                | "constexpr" | "continue" | "default" | "delete" | "do" | "else" | "enum"
                | "explicit" | "extern" | "for" | "friend" | "goto" | "if" | "inline"
                | "namespace" | "new" | "noexcept" | "operator" | "private" | "protected"
                | "public" | "return" | "sizeof" | "static" | "struct" | "switch" | "template"
                | "this" | "throw" | "try" | "typedef" | "typename" | "union" | "using"
                | "virtual" | "void" | "volatile" | "while"
        ),
        Lang::CSharp => matches!(
            w,
            "abstract" | "as" | "async" | "await" | "base" | "break" | "case" | "catch" | "class"
                | "const" | "continue" | "default" | "do" | "else" | "enum" | "event" | "extern"
                | "finally" | "for" | "foreach" | "if" | "in" | "interface" | "internal" | "is"
                | "lock" | "namespace" | "new" | "null" | "operator" | "out" | "override"
                | "params" | "private" | "protected" | "public" | "readonly" | "record" | "ref"
                | "return" | "sealed" | "static" | "struct" | "switch" | "this" | "throw" | "try"
                | "typeof" | "using" | "var" | "virtual" | "void" | "while" | "yield"
        ),
        Lang::Sql => {
            let up = w.to_ascii_uppercase();
            matches!(
                up.as_str(),
                "SELECT" | "FROM" | "WHERE" | "INSERT" | "INTO" | "VALUES" | "UPDATE" | "SET"
                    | "DELETE" | "CREATE" | "TABLE" | "INDEX" | "DROP" | "ALTER" | "JOIN"
                    | "LEFT" | "RIGHT" | "INNER" | "OUTER" | "ON" | "AS" | "AND" | "OR" | "NOT"
                    | "IN" | "IS" | "LIKE" | "ORDER" | "BY" | "GROUP" | "HAVING" | "LIMIT"
                    | "OFFSET" | "PRIMARY" | "KEY" | "FOREIGN" | "REFERENCES" | "DISTINCT"
                    | "UNION" | "CASE" | "WHEN" | "THEN" | "ELSE" | "END" | "EXISTS" | "IF"
                    | "DESC" | "ASC" | "PRAGMA" | "VIRTUAL" | "USING" | "MATCH"
            )
        }
        Lang::Shell => matches!(
            w,
            "if" | "then" | "else" | "elif" | "fi" | "for" | "in" | "do" | "done" | "while"
                | "case" | "esac" | "function" | "return" | "local" | "export" | "unset" | "set"
                | "echo" | "cd" | "exit"
        ),
        _ => matches!(
            w,
            "if" | "else" | "for" | "while" | "return" | "function" | "class" | "const" | "let"
                | "var" | "import" | "export" | "async" | "await" | "try" | "catch" | "new"
                | "void" | "struct" | "enum" | "fn" | "pub"
        ),
    }
}

fn is_literal(lang: Lang, w: &str) -> bool {
    match lang {
        Lang::Python => matches!(w, "True" | "False" | "None"),
        Lang::Sql => {
            let up = w.to_ascii_uppercase();
            matches!(up.as_str(), "TRUE" | "FALSE" | "NULL")
        }
        Lang::Go => matches!(w, "true" | "false" | "nil" | "iota"),
        _ => matches!(w, "true" | "false" | "null" | "undefined" | "NaN" | "Infinity" | "nullptr"),
    }
}

fn is_builtin_type(lang: Lang, w: &str) -> bool {
    match lang {
        Lang::Dart => matches!(
            w,
            "int" | "double" | "num" | "bool" | "String" | "List" | "Map" | "Set" | "Future"
                | "Stream" | "Object" | "Widget" | "BuildContext" | "Color" | "Offset" | "Size"
        ),
        Lang::Rust => matches!(
            w,
            "i8" | "i16" | "i32" | "i64" | "i128" | "isize" | "u8" | "u16" | "u32" | "u64"
                | "u128" | "usize" | "f32" | "f64" | "bool" | "char" | "str" | "String" | "Vec"
                | "Option" | "Result" | "Box" | "Arc" | "Mutex" | "HashMap"
        ),
        Lang::TypeScript | Lang::JavaScript => matches!(
            w,
            "string" | "number" | "boolean" | "any" | "unknown" | "never" | "object" | "Array"
                | "Promise" | "Record" | "Map" | "Set"
        ),
        Lang::Python => matches!(
            w,
            "int" | "float" | "str" | "bool" | "list" | "dict" | "set" | "tuple" | "bytes"
                | "object"
        ),
        Lang::Go => matches!(
            w,
            "bool" | "byte" | "error" | "float32" | "float64" | "int" | "int8" | "int16" | "int32"
                | "int64" | "rune" | "string" | "uint" | "uint8" | "uint16" | "uint32" | "uint64"
                | "uintptr" | "any"
        ),
        Lang::Cpp | Lang::Java | Lang::CSharp | Lang::Kotlin => matches!(
            w,
            "int" | "long" | "short" | "byte" | "float" | "double" | "bool" | "boolean" | "char"
                | "string" | "String" | "size_t" | "uint32_t" | "int32_t" | "int64_t" | "Int"
                | "Long" | "Double" | "Boolean" | "Unit" | "Any"
        ),
        Lang::Sql => {
            let up = w.to_ascii_uppercase();
            matches!(
                up.as_str(),
                "INT" | "INTEGER" | "TEXT" | "VARCHAR" | "REAL" | "FLOAT" | "BLOB" | "BOOLEAN"
                    | "TIMESTAMP" | "DATE" | "NUMERIC"
            )
        }
        _ => false,
    }
}

fn is_pascal_case(w: &str) -> bool {
    let bytes = w.as_bytes();
    if bytes.len() < 2 || !bytes[0].is_ascii_uppercase() {
        return false;
    }
    bytes[1..].iter().any(|b| b.is_ascii_lowercase())
}

fn is_followed_by_lparen(bytes: &[u8], mut i: usize) -> bool {
    while i < bytes.len() && (bytes[i] == b' ' || bytes[i] == b'\t') {
        i += 1;
    }
    i < bytes.len() && bytes[i] == b'('
}

fn uses_hash_comments(lang: Lang) -> bool {
    matches!(lang, Lang::Python | Lang::Yaml | Lang::Shell)
}

fn uses_c_comments(lang: Lang) -> bool {
    !matches!(lang, Lang::Python | Lang::Yaml | Lang::Shell | Lang::Html)
}

/// Scans `code` in a single linear pass, emitting `[utf16_start, utf16_end, kind]`
/// triplets for every highlighted token.
pub fn tokenize_code(code: &str, raw_lang: &str) -> Vec<i32> {
    if code.is_empty() {
        return Vec::new();
    }
    let lang = parse_lang(raw_lang);
    let bytes = code.as_bytes();
    let n = bytes.len();

    // Build byte-offset -> utf16-offset lookup only if non-ASCII exists;
    // for pure ASCII (99% of source code), utf16 offset == byte offset (O(1) zero alloc!).
    let is_ascii = code.is_ascii();
    let utf16_map: Vec<i32> = if is_ascii {
        Vec::new()
    } else {
        let mut map = vec![0i32; n + 1];
        let mut u16_pos = 0i32;
        for (byte_idx, ch) in code.char_indices() {
            map[byte_idx] = u16_pos;
            u16_pos += ch.len_utf16() as i32;
        }
        map[n] = u16_pos;
        map
    };

    let to_u16 = |b: usize| -> i32 {
        if is_ascii {
            b as i32
        } else {
            utf16_map[b]
        }
    };

    let mut out = Vec::with_capacity((n / 4).max(16) * 3);
    let mut i = 0usize;

    while i < n {
        let b = bytes[i];

        // Skip whitespace quickly
        if b == b' ' || b == b'\t' || b == b'\n' || b == b'\r' {
            i += 1;
            continue;
        }

        // 1. Line / Block Comments
        if uses_c_comments(lang) && b == b'/' && i + 1 < n {
            if bytes[i + 1] == b'/' {
                let start = i;
                i += 2;
                while i < n && bytes[i] != b'\n' {
                    i += 1;
                }
                out.extend_from_slice(&[to_u16(start), to_u16(i), KIND_COMMENT]);
                continue;
            } else if bytes[i + 1] == b'*' {
                let start = i;
                i += 2;
                while i + 1 < n && !(bytes[i] == b'*' && bytes[i + 1] == b'/') {
                    i += 1;
                }
                i = (i + 2).min(n);
                out.extend_from_slice(&[to_u16(start), to_u16(i), KIND_COMMENT]);
                continue;
            }
        }
        if lang == Lang::Sql && b == b'-' && i + 1 < n && bytes[i + 1] == b'-' {
            let start = i;
            i += 2;
            while i < n && bytes[i] != b'\n' {
                i += 1;
            }
            out.extend_from_slice(&[to_u16(start), to_u16(i), KIND_COMMENT]);
            continue;
        }
        if uses_hash_comments(lang) && b == b'#' {
            let start = i;
            i += 1;
            while i < n && bytes[i] != b'\n' {
                i += 1;
            }
            out.extend_from_slice(&[to_u16(start), to_u16(i), KIND_COMMENT]);
            continue;
        }
        if lang == Lang::Html && b == b'<' && i + 3 < n && &bytes[i..i + 4] == b"<!--" {
            let start = i;
            i += 4;
            while i + 2 < n && &bytes[i..i + 3] != b"-->" {
                i += 1;
            }
            i = (i + 3).min(n);
            out.extend_from_slice(&[to_u16(start), to_u16(i), KIND_COMMENT]);
            continue;
        }

        // 2. Strings ("...", '...', `...`)
        if b == b'"' || b == b'\'' || (b == b'`' && matches!(lang, Lang::JavaScript | Lang::TypeScript | Lang::Go | Lang::Sql | Lang::Generic)) {
            let quote = b;
            let start = i;
            i += 1;
            while i < n {
                if bytes[i] == b'\\' && i + 1 < n {
                    i += 2;
                    continue;
                }
                if bytes[i] == quote {
                    i += 1;
                    break;
                }
                if bytes[i] == b'\n' && quote != b'`' {
                    break;
                }
                i += 1;
            }
            // JSON property key detection: `"key":`
            let mut kind = KIND_STRING;
            if lang == Lang::Json && quote == b'"' {
                let mut look = i;
                while look < n && (bytes[look] == b' ' || bytes[look] == b'\t') {
                    look += 1;
                }
                if look < n && bytes[look] == b':' {
                    kind = KIND_PROPERTY;
                }
            }
            out.extend_from_slice(&[to_u16(start), to_u16(i), kind]);
            continue;
        }

        // 3. Annotations / Decorators (@override, #[derive])
        if b == b'@' && i + 1 < n && (bytes[i + 1].is_ascii_alphabetic() || bytes[i + 1] == b'_') {
            let start = i;
            i += 1;
            while i < n && (bytes[i].is_ascii_alphanumeric() || bytes[i] == b'_' || bytes[i] == b'.') {
                i += 1;
            }
            out.extend_from_slice(&[to_u16(start), to_u16(i), KIND_ANNOTATION]);
            continue;
        }
        if lang == Lang::Rust && b == b'#' && i + 1 < n && (bytes[i + 1] == b'[' || (bytes[i + 1] == b'!' && i + 2 < n && bytes[i + 2] == b'[')) {
            let start = i;
            while i < n && bytes[i] != b']' && bytes[i] != b'\n' {
                i += 1;
            }
            if i < n && bytes[i] == b']' {
                i += 1;
            }
            out.extend_from_slice(&[to_u16(start), to_u16(i), KIND_ANNOTATION]);
            continue;
        }

        // 4. Shell / CSS variables ($VAR, --var)
        if lang == Lang::Shell && b == b'$' && i + 1 < n {
            let start = i;
            i += 1;
            if bytes[i] == b'{' {
                while i < n && bytes[i] != b'}' && bytes[i] != b'\n' {
                    i += 1;
                }
                if i < n && bytes[i] == b'}' {
                    i += 1;
                }
            } else {
                while i < n && (bytes[i].is_ascii_alphanumeric() || bytes[i] == b'_') {
                    i += 1;
                }
            }
            out.extend_from_slice(&[to_u16(start), to_u16(i), KIND_VARIABLE]);
            continue;
        }

        // 5. Numbers
        if b.is_ascii_digit() {
            let start = i;
            if b == b'0' && i + 1 < n && matches!(bytes[i + 1], b'x' | b'X' | b'b' | b'B' | b'o' | b'O') {
                i += 2;
                while i < n && (bytes[i].is_ascii_hexdigit() || bytes[i] == b'_') {
                    i += 1;
                }
            } else {
                i += 1;
                while i < n && (bytes[i].is_ascii_digit() || bytes[i] == b'_') {
                    i += 1;
                }
                if i + 1 < n && bytes[i] == b'.' && bytes[i + 1].is_ascii_digit() {
                    i += 1;
                    while i < n && (bytes[i].is_ascii_digit() || bytes[i] == b'_') {
                        i += 1;
                    }
                }
                if i < n && (bytes[i] == b'e' || bytes[i] == b'E') {
                    i += 1;
                    if i < n && (bytes[i] == b'+' || bytes[i] == b'-') {
                        i += 1;
                    }
                    while i < n && bytes[i].is_ascii_digit() {
                        i += 1;
                    }
                }
            }
            out.extend_from_slice(&[to_u16(start), to_u16(i), KIND_NUMBER]);
            continue;
        }

        // 6. Identifiers, Keywords, Types, Literals, Functions
        if b.is_ascii_alphabetic() || b == b'_' {
            let start = i;
            i += 1;
            while i < n && (bytes[i].is_ascii_alphanumeric() || bytes[i] == b'_') {
                i += 1;
            }
            let word = &code[start..i];
            let kind = if lang == Lang::Yaml && i < n && bytes[i] == b':' {
                KIND_PROPERTY
            } else if is_keyword(lang, word) {
                KIND_KEYWORD
            } else if is_literal(lang, word) {
                KIND_LITERAL
            } else if is_builtin_type(lang, word) {
                KIND_TYPE
            } else if is_followed_by_lparen(bytes, i) {
                KIND_FUNCTION
            } else if is_pascal_case(word) && !matches!(lang, Lang::Sql | Lang::Shell | Lang::Json | Lang::Yaml) {
                KIND_TYPE
            } else {
                KIND_IDENTIFIER
            };

            if kind != KIND_IDENTIFIER {
                out.extend_from_slice(&[to_u16(start), to_u16(i), kind]);
            }
            continue;
        }

        // 7. Operators
        if matches!(
            b,
            b'+' | b'-' | b'*' | b'/' | b'%' | b'=' | b'<' | b'>' | b'!' | b'&' | b'|' | b'^'
                | b'~' | b'?' | b':'
        ) {
            let start = i;
            i += 1;
            while i < n
                && matches!(
                    bytes[i],
                    b'=' | b'>' | b'<' | b'&' | b'|' | b'?' | b'+' | b'-' | b':'
                )
            {
                i += 1;
            }
            out.extend_from_slice(&[to_u16(start), to_u16(i), KIND_OPERATOR]);
            continue;
        }

        // Advance safely over any UTF-8 scalar
        let ch_len = code[i..].chars().next().map(|c| c.len_utf8()).unwrap_or(1);
        i += ch_len;
    }

    out
}
