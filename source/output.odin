package game

import "core:math/rand"
import rl "vendor:raylib"
import "vendor:raylib/rlgl"

output :: proc() {
	rand.reset(g.input.output_rng_seed)
	// rl.UpdateMusicStream(R.get(g.knife))
	switch g.recording.state {
	case .Normal:
		rl.ClearBackground(rl.GRAY)
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

	switch &sim in g.sim {
	case Randomize:
		rlgl.PushMatrix()
		rlgl.Translatef((SCREEN_WIDTH - SIM_WINDOW.x) / 2, (SCREEN_HEIGHT - SIM_WINDOW.y) / 2, 0)
		rlgl.Scalef(SIM_WINDOW.x, SIM_WINDOW.y, 1)
		draw_bar_graph_component(g.values[:])
		rlgl.PopMatrix()
	case InsersionSort:
		// rlgl.PushMatrix()
		// rlgl.Translatef((SCREEN_WIDTH - SIM_WINDOW.x) / 2, (SCREEN_HEIGHT - SIM_WINDOW.y) / 2, 0)
		// rlgl.Scalef(SIM_WINDOW.x, SIM_WINDOW.y * 0.8, 1)
		// draw_bar_graph_component(g.values[:])
		// rlgl.PopMatrix()

		// rlgl.PushMatrix()
		// rlgl.Translatef(
		// 	(SCREEN_WIDTH - SIM_WINDOW.x) / 2,
		// 	(SCREEN_HEIGHT - SIM_WINDOW.y) / 2 + SIM_WINDOW.y * 0.8,
		// 	0,
		// )
		// rlgl.Scalef(SIM_WINDOW.x, SIM_WINDOW.y * 0.2, 1)
		// draw_bar_cursor_component(g.values[:], sim.insert)
		// rlgl.PopMatrix()
		draw_insert_sort(&sim)
	case:
		unreachable()
	}

	clay_raylib_render(&g.ui_cmds)
	draw_mouse_cursor()
}
BAR_GAP :: 0.3
// x = [0, 1] y = [0, 1]
draw_bar_graph_component :: proc(bars: []BarValue, anim: AnimationData = {}) {
	// proportional to width of bar, 0 is no gap and 1 is equal to size of the bar
	for _, i in bars {
		rect := get_bar_rect(bars, i, anim)
		rl.DrawRectangleRec(rect, rl.GREEN)
	}
}
get_bar_rect :: proc(bars: []BarValue, index: int, anim: AnimationData = {}) -> rl.Rectangle {
	bar := bars[index]
	w := calc_bar_width(bars)
	fi := interp(bar.pos.start, bar.pos.end, bar.pos.t, anim.type)
	x := w * fi + w * BAR_GAP * fi
	h := bar.height
	return {x, 1 - h, w, h}
}
draw_bar_cursor_component :: proc(
	color: rl.Color,
	bars: []BarValue,
	pos: AnimatedFloat,
	anim: AnimationData = {},
) {
	CURSOR_WIDTH :: 0.05
	tip := calc_cursor_tip(bars, pos, anim)
	rl.DrawTriangle({tip, 0}, {tip - CURSOR_WIDTH, 1}, {tip + CURSOR_WIDTH, 1}, color)
}
calc_bar_width :: proc(bars: []BarValue) -> f32 {
	count := f32(len(bars))
	gap_count := count - 1
	return 1 / (count + gap_count * BAR_GAP)
}
calc_cursor_tip :: proc(bars: []BarValue, pos: AnimatedFloat, anim: AnimationData = {}) -> f32 {
	fi := interp(pos.start, pos.end, pos.t, anim.type)
	w := calc_bar_width(bars)
	x := w * fi + w * BAR_GAP * fi
	x += w / 2
	return x
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
		draw_bar_graph_component(g.values[:])
		pop_bar_matrix()
	}

	#partial switch data.state {
	case .Initialization:
		opacity := interp(0, 255, data.step_t, INITIALIZATION_DURATION.type)

		push_bar_matrix()
		rect: rl.Rectangle
		rect = bar_animated_rect(g.values[:], data.insert, MOVE_HEAD_DURATION)
		rl.DrawRectangleRec(extend_rect(rect, 0.02), {255, 0, 0, u8(opacity)})

		rect = bar_animated_rect(g.values[:], data.compare, MOVE_HEAD_DURATION)
		rl.DrawRectangleRec(extend_rect(rect, 0.02), {255, 0, 0, u8(opacity)})
		pop_bar_matrix()

		push_bar_cursor_matrix()
		draw_bar_cursor_component(rl.RED, g.values[:], data.head, MOVE_HEAD_DURATION)
		pop_bar_cursor_matrix()
	case .MoveHead:
		push_bar_matrix()
		rect: rl.Rectangle
		rect = bar_animated_rect(g.values[:], data.insert, MOVE_HEAD_DURATION)
		rl.DrawRectangleRec(extend_rect(rect, 0.02), {255, 0, 0, 255})

		rect = bar_animated_rect(g.values[:], data.compare, MOVE_HEAD_DURATION)
		rl.DrawRectangleRec(extend_rect(rect, 0.02), {255, 0, 0, 255})
		pop_bar_matrix()

		push_bar_cursor_matrix()
		draw_bar_cursor_component(rl.RED, g.values[:], data.head, MOVE_HEAD_DURATION)
		pop_bar_cursor_matrix()
	case .Swap:
		push_bar_matrix()
		rect: rl.Rectangle
		rect = bar_animated_rect(g.values[:], data.insert, MOVE_HEAD_DURATION)
		rl.DrawRectangleRec(extend_rect(rect, 0.02), {255, 0, 0, 255})

		rect = bar_animated_rect(g.values[:], data.compare, MOVE_HEAD_DURATION)
		rl.DrawRectangleRec(extend_rect(rect, 0.02), {255, 0, 0, 255})
		pop_bar_matrix()

		push_bar_cursor_matrix()
		draw_bar_cursor_component(rl.RED, g.values[:], data.head, MOVE_HEAD_DURATION)
		pop_bar_cursor_matrix()
	}
}
bar_animated_rect :: proc(
	bars: []BarValue,
	pos: AnimatedFloat,
	anim: AnimationData = {},
) -> rl.Rectangle {
	s := int(pos.start)
	e := int(pos.end)

	rect_s := get_bar_rect(g.values[:], s, MOVE_HEAD_DURATION)
	rect_e := get_bar_rect(g.values[:], e, MOVE_HEAD_DURATION)

	return interp(rect_s, rect_e, pos.t, MOVE_HEAD_DURATION.type)
}
