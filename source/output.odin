package game

import "vendor:raylib/rlgl"
import "core:math/rand"
import rl "vendor:raylib"

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
	rlgl.Scalef(1, 200, 1)
	rlgl.PushMatrix()
	switch sim in g.sim {
	case Randomize:
		for &bar in g.values {
			rl.DrawRectangleRec(bar_rec(&bar), rl.RED)
		}
	case InsersionSort:
		assert(len(g.values) > 1)
		for &bar in g.values {
			rl.DrawRectangleRec(bar_rec(&bar), rl.RED)
		}
		// draw_bar_cursor(&g.values[int(sim.insert)], INITIALIZATION_DURATION) 
		// draw_bar_cursor(&g.values[int(sim.compare)], INITIALIZATION_DURATION) 
	}
	rlgl.PopMatrix()

	clay_raylib_render(&g.ui_cmds)
	draw_mouse_cursor()
}
draw_mouse_cursor :: proc() {
	RADIUS :: 5
	WIDTH :: 7
	LENGTH :: 25
	OFFSET :: 7

	pos := g.input.mouse_pos
	rl.DrawCircleV(pos, RADIUS, rl.BLACK)
	// rlgl.PushMatrix()
	// rlgl.Translatef(pos.x, pos.y, 0)
	// rlgl.Rotatef(-360. / CURSOR_LINE_COUNT - 90 / CURSOR_LINE_COUNT, 0, 0, 1)
	// for _ in 0 ..< 5 {
	// 	rlgl.Rotatef(360. / CURSOR_LINE_COUNT, 0, 0, -1)
	// 	rl.DrawRectangleRec({OFFSET, -WIDTH / 2, LENGTH, WIDTH}, rl.BLACK)
	// 	rl.DrawRectangleLinesEx({OFFSET, -WIDTH / 2, LENGTH, WIDTH}, 1, rl.BLACK)
	// }
	// rlgl.PopMatrix()
}
draw_bar_pointer_at::proc(tip: [2]f32) {
	WIDTH :: 35
	HEIGHT :: 20
	TOP_MARGIN :: 5
	x := tip.x 
	y := tip.y + TOP_MARGIN 
	rl.DrawTriangle({x, y}, {x - WIDTH / 2, y + HEIGHT}, {x + WIDTH / 2, y + HEIGHT}, rl.RED)
}
letter_box :: proc() -> (camera: rl.Camera2D, start, end: rl.Rectangle) {
	camera.zoom = 1
	{
		real_screen_width := f32(rl.GetScreenWidth())
		real_screen_height := f32(rl.GetScreenHeight())
		real_aspect_ration := real_screen_width / real_screen_height

		if real_aspect_ration > SCREEN_ASPECT_RATIO { 	// wider
			zoom := real_screen_height / SCREEN_HEIGHT
			camera.zoom = zoom

			width := SCREEN_WIDTH * zoom
			offset_x := (real_screen_width - width) / 2
			camera.offset.x = offset_x

			start.x = 0
			start.y = 0
			start.width = offset_x
			start.height = real_screen_height

			end.x = width + offset_x
			end.y = 0
			end.width = offset_x
			end.height = real_screen_height

		} else if real_aspect_ration < SCREEN_ASPECT_RATIO { 	// taller
			zoom := real_screen_width / SCREEN_WIDTH
			camera.zoom = zoom

			height := SCREEN_HEIGHT * zoom
			offset_y := (real_screen_height - height) / 2
			camera.offset.y = offset_y

			start.x = 0
			start.y = 0
			start.width = real_screen_width
			start.height = offset_y

			end.x = 0
			end.y = height + offset_y
			end.width = real_screen_width
			end.height = offset_y
		}
	}
	return
}
BAR_WIDTH :: 50
BAR_GAP :: 10
bar_rec :: proc(bar: ^BarValue, anim := AnimationData{}) -> rl.Rectangle {
	pos := bar_bottom_left(bar, anim)
	return {pos.x, pos.y - bar.height * GRAPH_HEIGHT, BAR_WIDTH, bar.height * GRAPH_HEIGHT}
}
bar_bottom_left :: proc(bar: ^BarValue, anim := AnimationData{}) -> [2]f32 {
	i := interp(bar.pos.start, bar.pos.end, bar.pos.t, anim.type)
	x := i * (BAR_GAP + BAR_WIDTH)
	return {x, GRAPH_HEIGHT}
}
bar_cursor_point :: proc(bar: ^BarValue, anim := AnimationData{}) -> [2]f32 {
	pos := bar_bottom_left(bar, anim)
	return {pos.x + BAR_WIDTH / 2, pos.y}
}
