package game

import "core:math/rand"
import "core:slice"
import "vendor:clay"
import rl "vendor:raylib"

RANDOMIZE_DURATION :: AnimationData {
	dur  = 0.1,
	type = .Linear,
}
INITIALIZATION_DURATION :: AnimationData {
	dur  = 0.3,
	type = .SmoothStep3,
}
MOVE_HEAD_DURATION :: AnimationData {
	dur  = 0.1,
	type = .SmoothStep3,
}
SWAP_DURATION :: AnimationData {
	dur  = 0.8,
	type = .SmoothStep3,
}
COMPARE_DURATION :: AnimationData {
	dur  = 1,
	type = .SmoothStep3,
}

process :: proc() {
	clay.SetPointerState(g.input.mouse_pos, false)
	rand.reset(g.input.process_rng_seed)
	if rl.IsKeyPressed(.F3) {
		dev_cmd()
	}

	if g.input.randomize {
		g.sim = Randomize{}
		rand.shuffle(g.values[:])
		for &bar, i in g.values {
			bar.i.start = interp(bar.i.start, bar.i.end, bar.i.t, RANDOMIZE_DURATION.type)
			bar.i.end = f32(i)
			bar.i.t = 0
		}
	}

	if g.input.start_sort {
		if len(g.values) > 1 {
			g.is_sorting = true
			g.sim = InsersionSort {
				head = {end = 1, start = 1},
			}
		}
	}
	switch &sim in g.sim {
	case Randomize:
		for &bar in g.values {
			bar.i.t += g.input.dt * (1 + g.speed) / RANDOMIZE_DURATION.dur
		}
	case InsersionSort:
		assert(len(g.values) > 1)
		switch sim.state {
		case .Initialization:
			sim.step_t += g.input.dt * (1 + g.speed) / INITIALIZATION_DURATION.dur
			if sim.step_t > 1 {
				sim.state = .MoveHead
			}
			for &bar in g.values {
				bar.i.t += g.input.dt * (1 + g.speed) / INITIALIZATION_DURATION.dur
			}
		case .MoveHead:
			sim.step_t += g.input.dt * (1 + g.speed) / MOVE_HEAD_DURATION.dur
			if sim.step_t > 1 {
				sim.state = .MoveHead
				sim.step_t = 0
			}
			for &bar in g.values {
				bar.i.t += g.input.dt * (1 + g.speed) / MOVE_HEAD_DURATION.dur
			}
		case .Swap:
		case .Compare:
		}
	case:
		unreachable()
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
