package game

import "sort"
import "core:math/rand"
import rl "vendor:raylib"

BAR_GAP :: sort.BAR_GAP

output :: proc() {
	rand.reset(g.input.output_rng_seed)
	// rl.UpdateMusicStream(R.get(g.knife))
	switch g.recording.state {
	case .Normal:
		rl.ClearBackground(rl.DARKGRAY)
	case .Record:
		rl.ClearBackground(rl.DARKGREEN)
	case .Replay:
		rl.ClearBackground(rl.DARKGRAY)
	}
	rl.BeginMode2D(g.camera)
	defer {
		rl.EndMode2D()
		rl.DrawRectangleRec(g.letter_box_start, rl.BLACK)
		rl.DrawRectangleRec(g.letter_box_end, rl.BLACK)
	}
	rl.DrawRectangleRec(exd(g.main_sort.frame, 10), rl.GRAY)
	sort.draw_sort(&g.main_sort)

	clay_raylib_render(&g.ui_cmds)
	draw_mouse_cursor()
}
calc_bar_width :: proc(count: int, gap: f32 = BAR_GAP) -> f32 {
	gap_count := f32(count) - 1
	return 1 / (f32(count) + gap_count * BAR_GAP)
}
draw_sort_cursor :: proc(bound: rl.Rectangle, color: rl.Color) {
	rl.DrawTriangle(
		{bound.x + bound.width / 2, bound.y},
		{bound.x, bound.y + bound.height},
		{bound.x + bound.width, bound.y + bound.height},
		color,
	)
}
