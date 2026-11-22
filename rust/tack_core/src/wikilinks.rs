use serde::{Deserialize, Serialize};

#[derive(Serialize)]
#[serde(rename_all = "camelCase")]
pub struct ParsedWikiLinkOut {
    pub raw_match: String,
    pub is_embed: bool,
    pub target: String,
    pub anchor: Option<String>,
    pub alias: Option<String>,
}

/// Parses a single `[[...]]` or `![[...]]` token matching `WikiLinkService.parseToken`.
fn parse_token(token: &str) -> Option<ParsedWikiLinkOut> {
    let trimmed = token.trim();
    let is_embed = trimmed.starts_with("![[");
    if !is_embed && !trimmed.starts_with("[[") {
        return None;
    }
    if !trimmed.ends_with("]]") {
        return None;
    }
    let start = if is_embed { 3 } else { 2 };
    if trimmed.len() <= start + 2 {
        return None;
    }
    let inner = trimmed[start..trimmed.len() - 2].trim();
    if inner.is_empty() {
        return None;
    }

    let (target_and_anchor, alias) = match inner.find('|') {
        Some(idx) => {
            let a = inner[idx + 1..].trim();
            (
                inner[..idx].trim(),
                if a.is_empty() { None } else { Some(a.to_string()) },
            )
        }
        None => (inner, None),
    };

    let (target, anchor) = match target_and_anchor.find('#') {
        Some(idx) => {
            let anc = target_and_anchor[idx + 1..].trim();
            (
                target_and_anchor[..idx].trim(),
                if anc.is_empty() {
                    None
                } else {
                    Some(anc.to_string())
                },
            )
        }
        None => (target_and_anchor, None),
    };

    if target.is_empty() {
        return None;
    }

    Some(ParsedWikiLinkOut {
        raw_match: trimmed.to_string(),
        is_embed,
        target: target.to_string(),
        anchor,
        alias,
    })
}

/// Zero-regex single-pass scanner extracting all `[[...]]` and `![[...]]` links
/// outside fenced ` ``` ` code blocks.
pub fn extract_all_links(content: &str) -> Vec<ParsedWikiLinkOut> {
    if content.is_empty() {
        return Vec::new();
    }
    let mut links = Vec::new();
    let mut in_fence = false;

    for line in content.split('\n') {
        if line.trim_start().starts_with("```") {
            in_fence = !in_fence;
            continue;
        }
        if in_fence {
            continue;
        }

        let bytes = line.as_bytes();
        let mut i = 0usize;
        while i + 3 < bytes.len() {
            let is_embed = bytes[i] == b'!' && bytes[i + 1] == b'[' && bytes[i + 2] == b'[';
            let is_link = !is_embed && bytes[i] == b'[' && bytes[i + 1] == b'[';
            if is_embed || is_link {
                let open_end = i + if is_embed { 3 } else { 2 };
                let mut j = open_end;
                let mut closed = false;
                while j + 1 < bytes.len() {
                    if bytes[j] == b'[' || bytes[j] == b'\n' {
                        break;
                    }
                    if bytes[j] == b']' {
                        if bytes[j + 1] == b']' {
                            let raw = &line[i..j + 2];
                            if let Some(parsed) = parse_token(raw) {
                                links.push(parsed);
                            }
                            i = j + 2;
                            closed = true;
                        }
                        break;
                    }
                    j += 1;
                }
                if !closed {
                    i = open_end;
                }
            } else {
                i += 1;
            }
        }
    }

    links
}

#[derive(Deserialize)]
#[serde(rename_all = "camelCase")]
struct BacklinksRequest {
    current_id: String,
    current_title: String,
    aliases: Vec<String>,
    candidates: Vec<CandidateItem>,
}

#[derive(Deserialize)]
#[serde(rename_all = "camelCase")]
struct CandidateItem {
    id: String,
    title: String,
    is_trash: bool,
    is_whiteboard: bool,
    body: String,
    #[serde(default)]
    canvas_nodes: Vec<CanvasNodeRef>,
}

#[derive(Deserialize)]
#[serde(rename_all = "camelCase")]
struct CanvasNodeRef {
    id: String,
    text: String,
    linked_note_id: Option<String>,
}

#[derive(Serialize)]
#[serde(rename_all = "camelCase")]
struct BacklinkEntryOut {
    source_id: String,
    context_snippet: String,
    is_canvas_node_link: bool,
    canvas_node_id: Option<String>,
    unlinked_match_offset: Option<usize>,
    unlinked_match_length: Option<usize>,
}

#[derive(Serialize)]
#[serde(rename_all = "camelCase")]
struct BacklinksResponse {
    linked: Vec<BacklinkEntryOut>,
    unlinked: Vec<BacklinkEntryOut>,
}

fn truncate_chars(s: &str, max_chars: usize) -> String {
    let mut chars = s.chars();
    let collected: String = chars.by_ref().take(max_chars).collect();
    if chars.next().is_some() {
        format!("{collected}...")
    } else {
        collected
    }
}

fn extract_context_around(body: &str, needle: &str) -> String {
    let lower_needle = needle.to_lowercase();
    for line in body.split('\n') {
        if line.to_lowercase().contains(&lower_needle) {
            return truncate_chars(line.trim(), 96);
        }
    }
    for line in body.split('\n') {
        let t = line.trim();
        if !t.is_empty() {
            return truncate_chars(t, 96);
        }
    }
    String::new()
}

fn is_word_or_bracket(ch: char) -> bool {
    ch.is_alphanumeric() || ch == '_' || ch == '[' || ch == ']'
}

/// Finds first whole-word case-insensitive occurrence of `needle` in `body`
/// outside `[[...]]` brackets, returning `(utf16_start, utf16_len, snippet)`.
fn find_unlinked_mention(body: &str, needle: &str) -> Option<(usize, usize, String)> {
    let lower_body = body.to_lowercase();
    let lower_needle = needle.to_lowercase();
    if lower_needle.is_empty() {
        return None;
    }

    // Only safe to map byte indices directly when lowercasing preserves char count;
    // build char-boundary scan for 100% Unicode correctness.
    let body_chars: Vec<(usize, char)> = body.char_indices().collect();
    let needle_chars: Vec<char> = lower_needle.chars().collect();
    let n_len = needle_chars.len();
    if body_chars.len() < n_len {
        return None;
    }

    let body_lower_chars: Vec<char> = body
        .chars()
        .map(|c| c.to_lowercase().next().unwrap_or(c))
        .collect();

    if body_lower_chars.len() != body_chars.len() {
        // Fallback for rare multi-char lowercase expansions
        if let Some(pos) = lower_body.find(&lower_needle) {
            let utf16_start = body[..pos.min(body.len())].encode_utf16().count();
            let utf16_len = needle.encode_utf16().count();
            return Some((utf16_start, utf16_len, extract_context_around(body, needle)));
        }
        return None;
    }

    for i in 0..=(body_lower_chars.len() - n_len) {
        if body_lower_chars[i..i + n_len] == needle_chars[..] {
            let prev_ok = i == 0 || !is_word_or_bracket(body_chars[i - 1].1);
            let next_ok =
                i + n_len >= body_chars.len() || !is_word_or_bracket(body_chars[i + n_len].1);
            if prev_ok && next_ok {
                let start_byte = body_chars[i].0;
                let end_byte = if i + n_len < body_chars.len() {
                    body_chars[i + n_len].0
                } else {
                    body.len()
                };
                let utf16_start = body[..start_byte].encode_utf16().count();
                let utf16_len = body[start_byte..end_byte].encode_utf16().count();

                // Extract snippet: 32 chars before, 48 chars after
                let snip_from_char = i.saturating_sub(32);
                let snip_to_char = (i + n_len + 48).min(body_chars.len());
                let snip_start_byte = body_chars[snip_from_char].0;
                let snip_end_byte = if snip_to_char < body_chars.len() {
                    body_chars[snip_to_char].0
                } else {
                    body.len()
                };
                let raw = body[snip_start_byte..snip_end_byte]
                    .replace('\n', " ")
                    .trim()
                    .to_string();
                let prefix = if snip_from_char > 0 { "..." } else { "" };
                let suffix = if snip_to_char < body_chars.len() {
                    "..."
                } else {
                    ""
                };
                return Some((utf16_start, utf16_len, format!("{prefix}{raw}{suffix}")));
            }
        }
    }

    None
}

pub fn compute_backlinks_json(req_json: &str) -> String {
    let Ok(req) = serde_json::from_str::<BacklinksRequest>(req_json) else {
        return r#"{"linked":[],"unlinked":[]}"#.to_string();
    };

    let current_title = req.current_title.trim();
    let lower_title = current_title.to_lowercase();
    let lower_aliases: Vec<String> = req.aliases.iter().map(|a| a.to_lowercase()).collect();

    let matches_target = |raw_target: &str| -> bool {
        if raw_target == req.current_id {
            return true;
        }
        let lower = raw_target.to_lowercase();
        lower == lower_title || lower_aliases.iter().any(|a| a == &lower)
    };

    let can_match_unlinked = current_title.chars().count() >= 3
        && lower_title != "untitled note"
        && lower_title != "new sticky"
        && lower_title != "new whiteboard";

    let mut linked = Vec::new();
    let mut unlinked = Vec::new();

    for cand in &req.candidates {
        if cand.is_trash || cand.id == req.current_id {
            continue;
        }

        if cand.is_whiteboard {
            for node in &cand.canvas_nodes {
                let is_direct_pin = node.linked_note_id.as_deref() == Some(req.current_id.as_str());
                let mentions_via_link = extract_all_links(&node.text)
                    .iter()
                    .any(|l| matches_target(&l.target));
                if is_direct_pin || mentions_via_link {
                    linked.push(BacklinkEntryOut {
                        source_id: cand.id.clone(),
                        context_snippet: if is_direct_pin {
                            format!("Pinned as Spec Card on \"{}\"", cand.title)
                        } else {
                            format!("Referenced in canvas node: \"{}\"", node.text)
                        },
                        is_canvas_node_link: true,
                        canvas_node_id: Some(node.id.clone()),
                        unlinked_match_offset: None,
                        unlinked_match_length: None,
                    });
                    break;
                }
            }
            continue;
        }

        if cand.body.trim().is_empty() {
            continue;
        }

        let links = extract_all_links(&cand.body);
        if let Some(matched) = links.iter().find(|l| matches_target(&l.target)) {
            linked.push(BacklinkEntryOut {
                source_id: cand.id.clone(),
                context_snippet: extract_context_around(&cand.body, &matched.target),
                is_canvas_node_link: false,
                canvas_node_id: None,
                unlinked_match_offset: None,
                unlinked_match_length: None,
            });
        } else if can_match_unlinked {
            if let Some((offset, len, snippet)) = find_unlinked_mention(&cand.body, current_title) {
                unlinked.push(BacklinkEntryOut {
                    source_id: cand.id.clone(),
                    context_snippet: snippet,
                    is_canvas_node_link: false,
                    canvas_node_id: None,
                    unlinked_match_offset: Some(offset),
                    unlinked_match_length: Some(len),
                });
            }
        }
    }

    serde_json::to_string(&BacklinksResponse { linked, unlinked })
        .unwrap_or_else(|_| r#"{"linked":[],"unlinked":[]}"#.to_string())
}
