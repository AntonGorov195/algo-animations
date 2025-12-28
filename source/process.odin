package game

import "core:math/rand"
import "core:slice"
import "vendor:clay"
import rl "vendor:raylib"

INITIALIZATION_DURATION :: 0.3
MOVE_HEAD_DURATION :: 0.4
SWAP_DURATION :: 0.8
COMPARE_DURATION :: 1.

process :: proc() {
	clay.SetPointerState(g.input.mouse_pos, false)
	rand.reset(g.input.process_rng_seed)
	if rl.IsKeyPressed(.F3) {
		dev_cmd()
	}

	if g.input.randomize {
		g.sim = nil
		rand.shuffle(g.values[:])
		for &bar, i in g.values {
			bar.start = bar_get_pos(&bar)
			bar.end = f32(i)
			bar.t = 0
		}
	}
	for &bar in g.values {
		if !g.is_sorting {
			bar.t += g.input.dt * (1 + g.speed) / RANDOMIZE_DURATION
		} else {
			bar.t += g.input.dt * (1 + g.speed)
		}
	}
	if g.input.start_sort {
		g.is_sorting = true
		g.sim = InsersionSort{}
	}
	switch sim in g.sim {
	case InsersionSort:
		switch sim.state {
		case .Initialization:
		case .MoveHead:
		case .Swap:
		case .Compare:
		}
	}
	clean_sound_pool()
}
insertion_sort_demo :: proc(values: []f32) {
	head: f32
	insert: f32
	compared: f32
	// move next
	for head = 1; int(head) < len(values); head += 1 {
		insert = head
		compared = insert - 1
		// compate
		for values[int(compared)] > values[int(insert)] {
			// swap
			slice.swap(values, int(insert), int(compared))
			insert -= 1
			compared -= 1
		}
	}
}
