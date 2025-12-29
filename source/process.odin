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
			bar.pos.start = interp(bar.pos.start, bar.pos.end, bar.pos.t, RANDOMIZE_DURATION.type)
			bar.pos.end = f32(i)
			bar.pos.t = 0
		}
	}

	if g.input.start_sort {
		if len(g.values) > 1 {
			g.is_sorting = true
			g.sim = InsersionSort{}
		}
	}
	switch &sim in g.sim {
	case Randomize:
		for &bar in g.values {
			bar.pos.t += g.input.dt * (1 + g.speed) / RANDOMIZE_DURATION.dur
		}
	case InsersionSort:
		assert(len(g.values) > 1)
		switch sim.state {
		case .Initialization:
			step_dt := g.input.dt * (1 + g.speed) / INITIALIZATION_DURATION.dur
			sim.step_t += step_dt
			for &bar in g.values {
				bar.pos.t += step_dt
			}
			if sim.step_t > 1 {
				// Ended
				sim.state = .MoveHead
				sim.step_t = 0
			}
		case .MoveHead:
			step_dt := g.input.dt * (1 + g.speed) / MOVE_HEAD_DURATION.dur
			sim.step_t += step_dt
			for &bar in g.values {
				bar.pos.t += step_dt
			}
			if sim.step_t > 1 {
				sim.state = .MoveHead
				sim.step_t = 0
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
