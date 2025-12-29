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

	switch sim in g.sim {
	case Randomize:
		rlgl.PushMatrix()
		rlgl.Translatef((SCREEN_WIDTH - SIM_WINDOW.x) / 2, (SCREEN_HEIGHT - SIM_WINDOW.y) / 2, 0)
		rlgl.Scalef(SIM_WINDOW.x, SIM_WINDOW.y, 1)
		draw_bar_graph_component(g.values[:])
		rlgl.PopMatrix()
	case InsersionSort:
		rlgl.PushMatrix()
		rlgl.Translatef((SCREEN_WIDTH - SIM_WINDOW.x) / 2, (SCREEN_HEIGHT - SIM_WINDOW.y) / 2, 0)
		rlgl.Scalef(SIM_WINDOW.x, SIM_WINDOW.y * 0.8, 1)
		draw_bar_graph_component(g.values[:])
		rlgl.PopMatrix()

		rlgl.PushMatrix()
		rlgl.Translatef(
			(SCREEN_WIDTH - SIM_WINDOW.x) / 2,
			(SCREEN_HEIGHT - SIM_WINDOW.y) / 2 + SIM_WINDOW.y * 0.8,
			0,
		)
		rlgl.Scalef(SIM_WINDOW.x, SIM_WINDOW.y * 0.2, 1)
		draw_bar_cursor_component(g.values[:], sim.insert)
		rlgl.PopMatrix()
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
	w := calc_bar_width(bars)
	for bar in bars {
		fi := interp(bar.pos.start, bar.pos.end, bar.pos.t, anim.type)
		x := w * fi + w * BAR_GAP * fi
		h := bar.height
		rl.DrawRectangleRec({x, 1 - h, w, h}, rl.GREEN)
	}
}
draw_bar_cursor_component :: proc(bars: []BarValue, pos: AnimatedFloat, anim: AnimationData = {}) {
	CURSOR_WIDTH :: 0.05
	tip := calc_cursor_tip(bars, pos, anim)
	rl.DrawTriangle({tip, 0}, {tip - CURSOR_WIDTH, 1}, {tip + CURSOR_WIDTH, 1}, rl.RED)
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
