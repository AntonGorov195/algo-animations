package game

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
	for &bar in g.values {
		rl.DrawRectangleRec(bar_rec(&bar), rl.RED)
	}
	switch sim in g.sim {
	case InsersionSort:

	}

	clay_raylib_render(&g.ui_cmds)
	draw_cursor()
}
draw_cursor :: proc() {
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
bar_rec :: proc(bar: ^BarValue) -> rl.Rectangle {
	WIDTH :: 50
	GAP :: 10
	i := bar_get_pos(bar)
	x := i * (GAP + WIDTH)
	return {x, GRAPH_HEIGHT - bar.height * GRAPH_HEIGHT + 30, WIDTH, bar.height * GRAPH_HEIGHT}
}
bar_get_pos :: proc(bar: ^BarValue) -> f32 {
	return interp(bar.start, bar.end, bar.t, IT.SmoothStep3)
}
