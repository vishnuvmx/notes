use rusqlite::{params, Connection};
use serde::Deserialize;
use std::collections::HashMap;
use std::sync::atomic::{AtomicI64, Ordering};
use std::sync::{Mutex, OnceLock};

static NEXT_HANDLE: AtomicI64 = AtomicI64::new(1);

fn db_registry() -> &'static Mutex<HashMap<i64, Connection>> {
    static REGISTRY: OnceLock<Mutex<HashMap<i64, Connection>>> = OnceLock::new();
    REGISTRY.get_or_init(|| Mutex::new(HashMap::new()))
}

#[derive(Deserialize)]
#[serde(rename_all = "camelCase")]
struct BatchItemRecord {
    id: String,
    item_type: String,
    title: String,
    body_text: String,
    tags_text: String,
    is_trash: bool,
    is_archived: bool,
    is_favorite: bool,
    updated_at_ms: i64,
    json_payload: String,
}

fn init_schema(conn: &Connection) -> rusqlite::Result<()> {
    conn.execute_batch(
        r#"
        PRAGMA journal_mode = WAL;
        PRAGMA synchronous = NORMAL;
        PRAGMA temp_store = MEMORY;

        CREATE TABLE IF NOT EXISTS items (
            id TEXT PRIMARY KEY,
            item_type TEXT NOT NULL,
            title TEXT NOT NULL,
            body_text TEXT NOT NULL,
            tags_text TEXT NOT NULL,
            is_trash INTEGER NOT NULL DEFAULT 0,
            is_archived INTEGER NOT NULL DEFAULT 0,
            is_favorite INTEGER NOT NULL DEFAULT 0,
            updated_at INTEGER NOT NULL,
            json_payload TEXT NOT NULL
        );

        CREATE INDEX IF NOT EXISTS idx_items_active_updated
            ON items (is_trash, is_archived, updated_at DESC);

        CREATE VIRTUAL TABLE IF NOT EXISTS items_fts USING fts5(
            id UNINDEXED,
            title,
            body_text,
            tags_text,
            tokenize = 'unicode61'
        );
        "#,
    )
}

pub fn db_open(path: &str) -> Option<i64> {
    let conn = if path.is_empty() || path == ":memory:" {
        Connection::open_in_memory().ok()?
    } else {
        Connection::open(path).ok()?
    };
    init_schema(&conn).ok()?;

    let handle = NEXT_HANDLE.fetch_add(1, Ordering::Relaxed);
    if let Ok(mut map) = db_registry().lock() {
        map.insert(handle, conn);
        Some(handle)
    } else {
        None
    }
}

pub fn db_close(handle: i64) {
    if let Ok(mut map) = db_registry().lock() {
        map.remove(&handle);
    }
}

fn upsert_single(
    conn: &Connection,
    id: &str,
    item_type: &str,
    title: &str,
    body_text: &str,
    tags_text: &str,
    is_trash: bool,
    is_archived: bool,
    is_favorite: bool,
    updated_at_ms: i64,
    json_payload: &str,
) -> rusqlite::Result<()> {
    conn.execute(
        r#"
        INSERT INTO items (
            id, item_type, title, body_text, tags_text,
            is_trash, is_archived, is_favorite, updated_at, json_payload
        ) VALUES (?1, ?2, ?3, ?4, ?5, ?6, ?7, ?8, ?9, ?10)
        ON CONFLICT(id) DO UPDATE SET
            item_type = excluded.item_type,
            title = excluded.title,
            body_text = excluded.body_text,
            tags_text = excluded.tags_text,
            is_trash = excluded.is_trash,
            is_archived = excluded.is_archived,
            is_favorite = excluded.is_favorite,
            updated_at = excluded.updated_at,
            json_payload = excluded.json_payload
        "#,
        params![
            id,
            item_type,
            title,
            body_text,
            tags_text,
            if is_trash { 1 } else { 0 },
            if is_archived { 1 } else { 0 },
            if is_favorite { 1 } else { 0 },
            updated_at_ms,
            json_payload,
        ],
    )?;

    conn.execute("DELETE FROM items_fts WHERE id = ?1", params![id])?;
    if !is_trash {
        conn.execute(
            "INSERT INTO items_fts (id, title, body_text, tags_text) VALUES (?1, ?2, ?3, ?4)",
            params![id, title, body_text, tags_text],
        )?;
    }
    Ok(())
}

#[allow(clippy::too_many_arguments)]
pub fn db_upsert_item(
    handle: i64,
    id: &str,
    item_type: &str,
    title: &str,
    body_text: &str,
    tags_text: &str,
    is_trash: bool,
    is_archived: bool,
    is_favorite: bool,
    updated_at_ms: i64,
    json_payload: &str,
) -> bool {
    let Ok(mut map) = db_registry().lock() else {
        return false;
    };
    let Some(conn) = map.get_mut(&handle) else {
        return false;
    };
    let Ok(tx) = conn.transaction() else {
        return false;
    };
    let ok = upsert_single(
        &tx,
        id,
        item_type,
        title,
        body_text,
        tags_text,
        is_trash,
        is_archived,
        is_favorite,
        updated_at_ms,
        json_payload,
    )
    .is_ok();
    if ok {
        tx.commit().is_ok()
    } else {
        false
    }
}

pub fn db_upsert_batch_json(handle: i64, batch_json: &str) -> bool {
    let Ok(records) = serde_json::from_str::<Vec<BatchItemRecord>>(batch_json) else {
        return false;
    };
    let Ok(mut map) = db_registry().lock() else {
        return false;
    };
    let Some(conn) = map.get_mut(&handle) else {
        return false;
    };
    let Ok(tx) = conn.transaction() else {
        return false;
    };
    for r in &records {
        if upsert_single(
            &tx,
            &r.id,
            &r.item_type,
            &r.title,
            &r.body_text,
            &r.tags_text,
            r.is_trash,
            r.is_archived,
            r.is_favorite,
            r.updated_at_ms,
            &r.json_payload,
        )
        .is_err()
        {
            return false;
        }
    }
    tx.commit().is_ok()
}

pub fn db_delete_item(handle: i64, id: &str) -> bool {
    let Ok(mut map) = db_registry().lock() else {
        return false;
    };
    let Some(conn) = map.get_mut(&handle) else {
        return false;
    };
    let Ok(tx) = conn.transaction() else {
        return false;
    };
    let ok = tx
        .execute("DELETE FROM items WHERE id = ?1", params![id])
        .is_ok()
        && tx
            .execute("DELETE FROM items_fts WHERE id = ?1", params![id])
            .is_ok();
    if ok {
        tx.commit().is_ok()
    } else {
        false
    }
}

pub fn db_empty_trash(handle: i64) -> bool {
    let Ok(mut map) = db_registry().lock() else {
        return false;
    };
    let Some(conn) = map.get_mut(&handle) else {
        return false;
    };
    let Ok(tx) = conn.transaction() else {
        return false;
    };
    let ok = tx
        .execute(
            "DELETE FROM items_fts WHERE id IN (SELECT id FROM items WHERE is_trash = 1)",
            [],
        )
        .is_ok()
        && tx.execute("DELETE FROM items WHERE is_trash = 1", []).is_ok();
    if ok {
        tx.commit().is_ok()
    } else {
        false
    }
}

pub fn db_load_all_json(handle: i64) -> Option<String> {
    let map = db_registry().lock().ok()?;
    let conn = map.get(&handle)?;
    let mut stmt = conn
        .prepare("SELECT json_payload FROM items ORDER BY updated_at DESC")
        .ok()?;
    let rows = stmt
        .query_map([], |row| row.get::<_, String>(0))
        .ok()?;

    let mut out = String::from("[");
    let mut first = true;
    for payload in rows.flatten() {
        if !first {
            out.push(',');
        }
        first = false;
        out.push_str(&payload);
    }
    out.push(']');
    Some(out)
}

fn build_fts_query(raw: &str) -> Option<String> {
    let mut parts = Vec::new();
    for token in raw.split_whitespace() {
        let cleaned: String = token
            .chars()
            .filter(|c| c.is_alphanumeric() || *c == '_' || *c == '-')
            .collect();
        if !cleaned.is_empty() {
            let escaped = cleaned.replace('"', "\"\"");
            parts.push(format!("\"{escaped}\"*"));
        }
    }
    if parts.is_empty() {
        None
    } else {
        Some(parts.join(" AND "))
    }
}

fn row_to_id(row: &rusqlite::Row<'_>) -> rusqlite::Result<String> {
    row.get::<_, String>(0)
}

pub fn db_search_ids(
    handle: i64,
    query: &str,
    type_filter: Option<&str>,
    limit: usize,
) -> Vec<String> {
    let trimmed = query.trim();
    if trimmed.is_empty() {
        return Vec::new();
    }
    let Ok(map) = db_registry().lock() else {
        return Vec::new();
    };
    let Some(conn) = map.get(&handle) else {
        return Vec::new();
    };

    let mut seen = Vec::new();
    let lim = limit as i64;

    // 1. Primary FTS5 BM25 ranked prefix search (sub-millisecond on large workspaces)
    if let Some(fts_q) = build_fts_query(trimmed) {
        let sql = if type_filter.is_some() {
            r#"
            SELECT i.id
            FROM items_fts f
            JOIN items i ON i.id = f.id
            WHERE items_fts MATCH ?1
              AND i.is_trash = 0
              AND i.is_archived = 0
              AND i.item_type = ?2
            ORDER BY bm25(items_fts, 10.0, 2.0, 4.0), i.updated_at DESC
            LIMIT ?3
            "#
        } else {
            r#"
            SELECT i.id
            FROM items_fts f
            JOIN items i ON i.id = f.id
            WHERE items_fts MATCH ?1
              AND i.is_trash = 0
              AND i.is_archived = 0
            ORDER BY bm25(items_fts, 10.0, 2.0, 4.0), i.updated_at DESC
            LIMIT ?2
            "#
        };

        if let Ok(mut stmt) = conn.prepare(sql) {
            let rows_res = if let Some(tf) = type_filter {
                stmt.query_map(params![fts_q, tf, lim], row_to_id)
            } else {
                stmt.query_map(params![fts_q, lim], row_to_id)
            };
            if let Ok(rows) = rows_res {
                for id in rows.flatten() {
                    seen.push(id);
                }
            }
        }
    }

    // 2. Substring fallback (handles mid-word matches or punctuation queries like `[[` / `#tag`)
    if seen.len() < limit {
        let like_pattern = format!("%{}%", trimmed.to_lowercase());
        let sql = if type_filter.is_some() {
            r#"
            SELECT id FROM items
            WHERE is_trash = 0
              AND is_archived = 0
              AND item_type = ?2
              AND (
                lower(title) LIKE ?1
                OR lower(body_text) LIKE ?1
                OR lower(tags_text) LIKE ?1
              )
            ORDER BY updated_at DESC
            LIMIT ?3
            "#
        } else {
            r#"
            SELECT id FROM items
            WHERE is_trash = 0
              AND is_archived = 0
              AND (
                lower(title) LIKE ?1
                OR lower(body_text) LIKE ?1
                OR lower(tags_text) LIKE ?1
              )
            ORDER BY updated_at DESC
            LIMIT ?2
            "#
        };
        if let Ok(mut stmt) = conn.prepare(sql) {
            let rows_res = if let Some(tf) = type_filter {
                stmt.query_map(params![like_pattern, tf, lim], row_to_id)
            } else {
                stmt.query_map(params![like_pattern, lim], row_to_id)
            };
            if let Ok(rows) = rows_res {
                for id in rows.flatten() {
                    if !seen.contains(&id) {
                        seen.push(id);
                        if seen.len() >= limit {
                            break;
                        }
                    }
                }
            }
        }
    }

    seen
}
