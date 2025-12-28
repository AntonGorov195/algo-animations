package game

import "core:math/rand"
import rl "vendor:raylib"

input :: proc() {
	input: Input
	when CONST_FPS <= 0 {
		input.dt = rl.GetFrameTime()
	} else {
		input.dt = 1. / CONST_FPS
	}
	input.mouse_pos = rl.GetMousePosition() // This is fixed thanks to: rl.SetMouseOffset/Scale
	input.mouse_pos.x = clamp(input.mouse_pos.x, 0, SCREEN_WIDTH)
	input.mouse_pos.y = clamp(input.mouse_pos.y, 0, SCREEN_HEIGHT)
	if rl.IsMouseButtonPressed(.LEFT) {
		input.click = true
	}
	if rl.IsKeyPressed(.E) {
		input.randomize = true
	}
	input.process_rng_seed = rand.uint64()
	input.output_rng_seed = rand.uint64()
	g.input = input
}
