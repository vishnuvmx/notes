mod graph;
mod storage;
mod syntax;
mod wikilinks;

use std::ffi::{c_char, CString};
use std::slice;

/// Protocol version so Dart can verify the native library loaded cleanly.
#[no_mangle]
pub extern "C" fn tack_core_version() -> i32 {
    1
}

/// Allocates a raw byte buffer owned by Rust's allocator for zero-dependency Dart FFI transfers.
#[no_mangle]
pub extern "C" fn tack_alloc(len: usize) -> *mut u8 {
    if len == 0 {
        return std::ptr::null_mut();
    }
    let mut buf = Vec::<u8>::with_capacity(len);
    let ptr = buf.as_mut_ptr();
    std::mem::forget(buf);
    ptr
}

/// Frees a byte buffer previously allocated with `tack_alloc`.
#[no_mangle]
pub unsafe extern "C" fn tack_free(ptr: *mut u8, len: usize) {
    if !ptr.is_null() && len > 0 {
        drop(Vec::from_raw_parts(ptr, 0, len));
    }
}

/// Frees a NUL-terminated UTF-8 string returned by any `tack_*` FFI call.
#[no_mangle]
pub unsafe extern "C" fn tack_free_cstr(ptr: *mut c_char) {
    if !ptr.is_null() {
        drop(CString::from_raw(ptr));
    }
}

/// Frees an `i32` token buffer returned by `tack_tokenize_code`.
#[no_mangle]
pub unsafe extern "C" fn tack_free_i32_buf(ptr: *mut i32, len: usize) {
    if !ptr.is_null() && len > 0 {
        drop(Vec::from_raw_parts(ptr, len, len));
    }
}

/// Helper to read a UTF-8 string slice from raw pointer + byte length.
unsafe fn read_utf8<'a>(ptr: *const u8, len: usize) -> &'a str {
    if ptr.is_null() || len == 0 {
        return "";
    }
    let bytes = slice::from_raw_parts(ptr, len);
    std::str::from_utf8(bytes).unwrap_or("")
}

/// Helper to convert a Rust String into a heap-allocated C string for Dart FFI.
fn into_cstr(s: String) -> *mut c_char {
    // Strip any embedded NUL bytes defensively so CString::new never panics.
    let clean = if s.as_bytes().contains(&0) {
        s.replace('\0', "")
    } else {
        s
    };
    CString::new(clean)
        .map(CString::into_raw)
        .unwrap_or(std::ptr::null_mut())
}

// ============================================================================
// 1. Knowledge Graph Force-Directed Layout Engine
// ============================================================================

/// Mutates `positions` (`[x0, y0, x1, y1, ...]`) in-place using Tack's
/// deterministic Coulomb repulsion + Hooke spring + center-gravity layout.
#[no_mangle]
pub unsafe extern "C" fn tack_layout_graph(
    positions_ptr: *mut f32,
    node_count: i32,
    edges_ptr: *const i32,
    edge_count: i32,
    pinned_index: i32,
    center_x: f32,
    center_y: f32,
    canvas_size: f32,
    iterations: i32,
) {
    if positions_ptr.is_null() || node_count <= 0 {
        return;
    }
    let n = node_count as usize;
    let positions = slice::from_raw_parts_mut(positions_ptr, n * 2);
    let edges = if edges_ptr.is_null() || edge_count <= 0 {
        &[]
    } else {
        slice::from_raw_parts(edges_ptr, (edge_count as usize) * 3)
    };
    graph::layout_graph(
        positions,
        n,
        edges,
        pinned_index,
        center_x,
        center_y,
        canvas_size,
        iterations.max(1) as usize,
    );
}

// ============================================================================
// 2. SQLite + FTS5 Incremental Storage & Search Engine
// ============================================================================

/// Opens (or creates) a SQLite WAL + FTS5 database at `path` (or `:memory:`).
/// Returns handle > 0 on success, or 0 on failure.
#[no_mangle]
pub unsafe extern "C" fn tack_db_open(path_ptr: *const u8, path_len: usize) -> i64 {
    let path = read_utf8(path_ptr, path_len);
    storage::db_open(path).unwrap_or(0)
}

#[no_mangle]
pub extern "C" fn tack_db_close(handle: i64) {
    storage::db_close(handle);
}

#[no_mangle]
pub unsafe extern "C" fn tack_db_upsert_item(
    handle: i64,
    id_ptr: *const u8,
    id_len: usize,
    item_type_ptr: *const u8,
    item_type_len: usize,
    title_ptr: *const u8,
    title_len: usize,
    body_ptr: *const u8,
    body_len: usize,
    tags_ptr: *const u8,
    tags_len: usize,
    is_trash: i32,
    is_archived: i32,
    is_favorite: i32,
    updated_at_ms: i64,
    json_ptr: *const u8,
    json_len: usize,
) -> i32 {
    let ok = storage::db_upsert_item(
        handle,
        read_utf8(id_ptr, id_len),
        read_utf8(item_type_ptr, item_type_len),
        read_utf8(title_ptr, title_len),
        read_utf8(body_ptr, body_len),
        read_utf8(tags_ptr, tags_len),
        is_trash != 0,
        is_archived != 0,
        is_favorite != 0,
        updated_at_ms,
        read_utf8(json_ptr, json_len),
    );
    if ok { 1 } else { 0 }
}

/// Atomically upserts a JSON array of `StorageItemRecord` entries in one SQLite transaction.
#[no_mangle]
pub unsafe extern "C" fn tack_db_upsert_batch_json(
    handle: i64,
    batch_ptr: *const u8,
    batch_len: usize,
) -> i32 {
    let batch = read_utf8(batch_ptr, batch_len);
    if storage::db_upsert_batch_json(handle, batch) {
        1
    } else {
        0
    }
}

#[no_mangle]
pub unsafe extern "C" fn tack_db_delete_item(
    handle: i64,
    id_ptr: *const u8,
    id_len: usize,
) -> i32 {
    if storage::db_delete_item(handle, read_utf8(id_ptr, id_len)) {
        1
    } else {
        0
    }
}

#[no_mangle]
pub extern "C" fn tack_db_empty_trash(handle: i64) -> i32 {
    if storage::db_empty_trash(handle) {
        1
    } else {
        0
    }
}

/// Loads all stored item JSON payloads ordered by `updated_at DESC` as a JSON array string.
#[no_mangle]
pub extern "C" fn tack_db_load_all_json(handle: i64) -> *mut c_char {
    match storage::db_load_all_json(handle) {
        Some(json) => into_cstr(json),
        None => std::ptr::null_mut(),
    }
}

/// Searches active (non-trash) items using FTS5 BM25 + substring fallback.
/// Returns a JSON array of matching item IDs ordered by relevance & recency.
#[no_mangle]
pub unsafe extern "C" fn tack_db_search_ids(
    handle: i64,
    query_ptr: *const u8,
    query_len: usize,
    type_filter_ptr: *const u8,
    type_filter_len: usize,
    limit: i32,
) -> *mut c_char {
    let query = read_utf8(query_ptr, query_len);
    let type_filter = read_utf8(type_filter_ptr, type_filter_len);
    let tf = if type_filter.is_empty() {
        None
    } else {
        Some(type_filter)
    };
    let ids = storage::db_search_ids(handle, query, tf, limit.max(1) as usize);
    let json = serde_json::to_string(&ids).unwrap_or_else(|_| "[]".to_string());
    into_cstr(json)
}

// ============================================================================
// 3. Wiki-Link & Backlinks Scanner Engine
// ============================================================================

/// Extracts all `[[...]]` and `![[...]]` links outside fenced code blocks as JSON.
#[no_mangle]
pub unsafe extern "C" fn tack_extract_wikilinks(
    content_ptr: *const u8,
    content_len: usize,
) -> *mut c_char {
    let content = read_utf8(content_ptr, content_len);
    let links = wikilinks::extract_all_links(content);
    let json = serde_json::to_string(&links).unwrap_or_else(|_| "[]".to_string());
    into_cstr(json)
}

/// Computes explicit backlinks & unlinked mentions across workspace candidates.
#[no_mangle]
pub unsafe extern "C" fn tack_compute_backlinks(
    req_ptr: *const u8,
    req_len: usize,
) -> *mut c_char {
    let req_json = read_utf8(req_ptr, req_len);
    let resp_json = wikilinks::compute_backlinks_json(req_json);
    into_cstr(resp_json)
}

// ============================================================================
// 4. Zero-Copy Multi-Language Code Syntax Lexer
// ============================================================================

/// Tokenizes `code` for `lang`, returning a flat Rust-owned `i32` buffer of
/// triplets `[utf16_start, utf16_end, token_kind_id, ...]`.
/// Writes total `i32` element count (`token_count * 3`) to `*out_len`.
/// Caller must free the returned pointer via `tack_free_i32_buf(ptr, *out_len)`.
#[no_mangle]
pub unsafe extern "C" fn tack_tokenize_code(
    code_ptr: *const u8,
    code_len: usize,
    lang_ptr: *const u8,
    lang_len: usize,
    out_len: *mut usize,
) -> *mut i32 {
    if out_len.is_null() {
        return std::ptr::null_mut();
    }
    let code = read_utf8(code_ptr, code_len);
    let lang = read_utf8(lang_ptr, lang_len);
    let mut tokens = syntax::tokenize_code(code, lang);
    tokens.shrink_to_fit();
    let len = tokens.len();
    *out_len = len;
    if len == 0 {
        return std::ptr::null_mut();
    }
    let ptr = tokens.as_mut_ptr();
    std::mem::forget(tokens);
    ptr
}
