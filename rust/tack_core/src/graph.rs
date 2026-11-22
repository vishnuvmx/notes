/// Deterministic force-directed graph layout engine matching Tack's
/// `KnowledgeGraphScreen._runForceSimulation` physics with flat contiguous
/// `f32` buffers (zero per-step heap allocations).
pub fn layout_graph(
    positions: &mut [f32],
    node_count: usize,
    edges: &[i32],
    pinned_index: i32,
    center_x: f32,
    center_y: f32,
    canvas_size: f32,
    iterations: usize,
) {
    if node_count <= 1 {
        if node_count == 1 && positions.len() >= 2 {
            positions[0] = center_x;
            positions[1] = center_y;
        }
        return;
    }

    const REPULSION: f32 = 9200.0;
    const IDEAL_SPRING_LEN: f32 = 148.0;
    const SPRING_K: f32 = 0.045;
    const CENTER_PULL: f32 = 0.018;
    const MAX_FORCE_REPULSION: f32 = 55.0;
    const MAX_STEP_DELTA: f32 = 28.0;

    let min_bound = 120.0_f32;
    let max_bound = (canvas_size - 120.0).max(min_bound);

    // Pre-allocate flat force buffers once (zero allocations inside the loop).
    let mut fx = vec![0.0_f32; node_count];
    let mut fy = vec![0.0_f32; node_count];

    let edge_count = edges.len() / 3;
    let iters_f = iterations as f32;

    for step in 0..iterations {
        let cooling = 1.0 - (step as f32 / iters_f) * 0.72;
        fx.fill(0.0);
        fy.fill(0.0);

        // 1. Pairwise Coulomb repulsion (cache-local flat array scan)
        for i in 0..node_count {
            let ax = positions[i * 2];
            let ay = positions[i * 2 + 1];
            let mut acc_x = fx[i];
            let mut acc_y = fy[i];

            for j in (i + 1)..node_count {
                let mut dx = ax - positions[j * 2];
                let mut dy = ay - positions[j * 2 + 1];
                let mut dist_sq = dx * dx + dy * dy;
                if dist_sq < 16.0 {
                    dx = 4.0;
                    dy = 1.5;
                    dist_sq = 18.25;
                }
                let inv_dist = 1.0 / dist_sq.sqrt();
                let force_mag = (REPULSION / dist_sq).clamp(0.0, MAX_FORCE_REPULSION);
                let dfx = dx * inv_dist * force_mag;
                let dfy = dy * inv_dist * force_mag;

                acc_x += dfx;
                acc_y += dfy;
                fx[j] -= dfx;
                fy[j] -= dfy;
            }

            fx[i] = acc_x;
            fy[i] = acc_y;
        }

        // 2. Hooke spring attraction along edges
        for e in 0..edge_count {
            let src = edges[e * 3] as usize;
            let dst = edges[e * 3 + 1] as usize;
            let is_tag = edges[e * 3 + 2] != 0;
            if src >= node_count || dst >= node_count {
                continue;
            }

            let dx = positions[dst * 2] - positions[src * 2];
            let dy = positions[dst * 2 + 1] - positions[src * 2 + 1];
            let dist = (dx * dx + dy * dy).sqrt().max(1.0);
            let target_len = if is_tag {
                IDEAL_SPRING_LEN * 1.15
            } else {
                IDEAL_SPRING_LEN
            };
            let pull_scale = ((dist - target_len) * SPRING_K) / dist;
            let px = dx * pull_scale;
            let py = dy * pull_scale;

            fx[src] += px;
            fy[src] += py;
            fx[dst] -= px;
            fy[dst] -= py;
        }

        // 3. Center gravity + cooling integration + bounds clamp
        for i in 0..node_count {
            if pinned_index >= 0 && i == pinned_index as usize {
                positions[i * 2] = center_x;
                positions[i * 2 + 1] = center_y;
                continue;
            }
            let x = positions[i * 2];
            let y = positions[i * 2 + 1];
            let to_cx = (center_x - x) * CENTER_PULL;
            let to_cy = (center_y - y) * CENTER_PULL;

            let step_x = ((fx[i] + to_cx) * cooling).clamp(-MAX_STEP_DELTA, MAX_STEP_DELTA);
            let step_y = ((fy[i] + to_cy) * cooling).clamp(-MAX_STEP_DELTA, MAX_STEP_DELTA);

            positions[i * 2] = (x + step_x).clamp(min_bound, max_bound);
            positions[i * 2 + 1] = (y + step_y).clamp(min_bound, max_bound);
        }
    }
}
