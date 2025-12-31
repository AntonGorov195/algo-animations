package game

import "core:math/rand"
import rl "vendor:raylib"
import "vendor:raylib/rlgl"

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
	rl.DrawRectangleRounded(extend_rect(g.main_sort.frame, 30), 0.08, 5, rl.GRAY)
	draw_sort(&g.main_sort)

	clay_raylib_render(&g.ui_cmds)
	// draw_mouse_cursor()
}
draw_bar_graph_component :: proc(bars: []BarValue) {
	for bar in bars {
		rl.DrawRectangleRec(eval_anim(bar.rect), rl.GREEN)
	}
}
calc_bar_width :: proc(count: int, gap: f32 = BAR_GAP) -> f32 {
	gap_count := f32(count) - 1
	return 1 / (f32(count) + gap_count * BAR_GAP)
}
draw_insert_sort :: proc(data: ^InsersionSort) {

	push_bar_matrix :: proc() {
		rlgl.PushMatrix()
		rlgl.Translatef((SCREEN_WIDTH - SIM_WINDOW.x) / 2, (SCREEN_HEIGHT - SIM_WINDOW.y) / 2, 0)
		rlgl.Scalef(SIM_WINDOW.x, SIM_WINDOW.y * 0.8, 1)
	}
	pop_bar_matrix :: proc() {
		rlgl.PopMatrix()
	}

	push_bar_cursor_matrix :: proc() {
		rlgl.PushMatrix()
		rlgl.Translatef(
			(SCREEN_WIDTH - SIM_WINDOW.x) / 2,
			(SCREEN_HEIGHT - SIM_WINDOW.y) / 2 + SIM_WINDOW.y * 0.8,
			0,
		)
		rlgl.Scalef(SIM_WINDOW.x, SIM_WINDOW.y * 0.2, 1)
	}
	pop_bar_cursor_matrix :: proc() {
		rlgl.PopMatrix()
	}

	defer {
		push_bar_matrix()
		// draw_bar_graph_component(g.values[:])
		pop_bar_matrix()
	}

	// #partial switch data.state {
	// case .Initialization:
	// 	opacity := interp(0, 255, data.step_t, INITIALIZATION_DURATION.type)

	// 	push_bar_matrix()
	// 	rect: rl.Rectangle
	// 	rect = bar_animated_rect(g.values[:], data.insert, MOVE_HEAD_DURATION)
	// 	rl.DrawRectangleRec(extend_rect(rect, 0.02), {255, 0, 0, u8(opacity)})

	// 	rect = bar_animated_rect(g.values[:], data.compare, MOVE_HEAD_DURATION)
	// 	rl.DrawRectangleRec(extend_rect(rect, 0.02), {255, 0, 0, u8(opacity)})
	// 	pop_bar_matrix()

	// 	push_bar_cursor_matrix()
	// 	draw_bar_cursor_component(rl.RED, g.values[:], data.head, MOVE_HEAD_DURATION)
	// 	pop_bar_cursor_matrix()
	// case .MoveHead:
	// 	push_bar_matrix()
	// 	rect: rl.Rectangle
	// 	rect = bar_animated_rect(g.values[:], data.insert, MOVE_HEAD_DURATION)
	// 	rl.DrawRectangleRec(extend_rect(rect, 0.02), {255, 0, 0, 255})

	// 	rect = bar_animated_rect(g.values[:], data.compare, MOVE_HEAD_DURATION)
	// 	rl.DrawRectangleRec(extend_rect(rect, 0.02), {255, 0, 0, 255})
	// 	pop_bar_matrix()

	// 	push_bar_cursor_matrix()
	// 	draw_bar_cursor_component(rl.RED, g.values[:], data.head, MOVE_HEAD_DURATION)
	// 	pop_bar_cursor_matrix()
	// case .Swap:
	// 	push_bar_matrix()
	// 	rect: rl.Rectangle
	// 	rect = bar_animated_rect(g.values[:], data.insert, MOVE_HEAD_DURATION)
	// 	rl.DrawRectangleRec(extend_rect(rect, 0.02), {255, 0, 0, 255})

	// 	rect = bar_animated_rect(g.values[:], data.compare, MOVE_HEAD_DURATION)
	// 	rl.DrawRectangleRec(extend_rect(rect, 0.02), {255, 0, 0, 255})
	// 	pop_bar_matrix()

	// 	push_bar_cursor_matrix()
	// 	draw_bar_cursor_component(rl.RED, g.values[:], data.head, MOVE_HEAD_DURATION)
	// 	pop_bar_cursor_matrix()
	// }
}
draw_sort_cursor :: proc(bound: rl.Rectangle, color: rl.Color) {
	rl.DrawTriangle(
		{bound.x + bound.width / 2, bound.y},
		{bound.x, bound.y + bound.height},
		{bound.x + bound.width, bound.y + bound.height},
		color,
	)
}
