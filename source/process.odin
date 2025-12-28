package game

import "core:math/rand"
import "vendor:clay"
import rl "vendor:raylib"

process :: proc() {
	clay.SetPointerState(g.input.mouse_pos, false)
	rand.reset(g.input.process_rng_seed)
	if rl.IsKeyPressed(.F3) {
		dev_cmd()
	}
	switch sim in g.sim {
	case InsersionSort:
		for &bar in sim.values {
			if bar.dur != 0 {
				bar.t += g.input.dt / bar.dur
			} else {
				bar.t = 1
			}
		}
		if g.input.randomize {
			rand.shuffle(sim.values[:])
			for &bar, i in sim.values {
				bar.start = bar_get_pos(&bar)
				bar.end = f32(i)
				bar.t = 0
			}
		}
	}
	clean_sound_pool()
}
