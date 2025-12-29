package game

import "core:math/rand"
import "core:slice"
import "vendor:clay"
import rl "vendor:raylib"

RANDOMIZE_DURATION :: AnimationData {
	dur  = 0.1,
	type = .SmoothStep3,
}
INITIALIZATION_DURATION :: AnimationData {
	dur  = 0.3,
	type = .SmoothStep3,
}
MOVE_HEAD_DURATION :: AnimationData {
	dur  = 1.1,
	type = .SmoothStep5,
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
		process_insertion_sort(&sim)
	case:
		unreachable()
	}
	clean_sound_pool()
}
insertion_sort_demo :: proc(values: []f32) {
	head: int
	insert: int
	compared: int
	// move next
	for head = 1; head < len(values); head += 1 {
		insert = head
		compared = insert - 1
		// compate
		for values[compared] > values[insert] {
			// swap
			slice.swap(values, insert, compared)
			// move next
			insert -= 1
			compared -= 1
			if compared < 0 {
				break
			}
		}
	}
}
bar_change_index :: proc(prev: AnimatedFloat, idx: int, anim := AnimationData{}) -> AnimatedFloat {
	return {start = interp(prev.start, prev.end, prev.t, anim.type), end = f32(idx), t = 0}
}
process_insertion_sort :: proc(sim: ^InsersionSort) {
	advance :: proc(sim: ^InsersionSort, dur: f32) {
		step_dt := g.input.dt * (1 + g.speed) / dur
		sim.step_t += step_dt
		sim.head.t += step_dt
		sim.insert.t += step_dt
		sim.compare.t += step_dt
		for &bar in g.values {
			bar.pos.t += step_dt
		}
	}
	assert(len(g.values) > 1)
	switch sim.state {
	case .Initialization:
		advance(sim, INITIALIZATION_DURATION.dur)
		if sim.step_t > 1 {
			// Ended
			sim.state = .MoveHead
			sim.step_t = 0
			sim.head = {
				start = interp(
					sim.head.start,
					sim.head.end,
					sim.head.t,
					INITIALIZATION_DURATION.type,
				),
				end   = 1,
				t     = 0,
			}
			sim.head_idx = 1

			sim.insert = {
				start = interp(
					sim.insert.start,
					sim.insert.end,
					sim.insert.t,
					INITIALIZATION_DURATION.type,
				),
				end   = 1,
				t     = 0,
			}
			sim.insert_idx = 1
		}
	case .MoveHead:
		advance(sim, MOVE_HEAD_DURATION.dur)
		if sim.step_t > 1 {
			sim.state = .Compare
			sim.step_t = 0
		}
	case .Swap:
		advance(sim, SWAP_DURATION.dur)
		if sim.step_t > 1 {
			sim.state = .Compare
			sim.step_t = 0
		}
	case .Compare:
		advance(sim, COMPARE_DURATION.dur)
		insertion_sort_compare(sim)
	}
}
insertion_sort_compare :: proc(sim: ^InsersionSort) {
	assert(sim != nil)
	assert(sim.head_idx > 0)
	assert(sim.head_idx < len(g.values))
	assert(sim.insert_idx > 0)
	assert(sim.insert_idx < len(g.values))
	assert(sim.compare_idx > 0)
	assert(sim.compare_idx < len(g.values))
	if g.values[sim.compare_idx].value > g.values[sim.insert_idx].value {

	} else {

	}
	// 	sim.state = .Swap
	// 	sim.step_t = 0
	// 	slice.swap(g.values[:], sim.insert_idx, sim.compare_idx)
	// 	sim.insert_idx -= 1
	// 	sim.compare_idx -= 1

	// 	sim.head = bar_change_index(sim.head, sim.head_idx, COMPARE_DURATION)
	// 	sim.insert = bar_change_index(sim.insert, sim.insert_idx, COMPARE_DURATION)
	// 	sim.compare = bar_change_index(sim.compare, sim.compare_idx, COMPARE_DURATION)
	// } else {
	// 	sim.state = .MoveHead
	// 	sim.step_t = 0
	// 	sim.head_idx += 1
	// 	if sim.head_idx >= len(g.values) {
	// 		g.sim = Randomize{}
	// 		return
	// 	}
	// 	sim.head = bar_change_index(sim.head, sim.head_idx, COMPARE_DURATION)

	// 	sim.insert_idx = sim.head_idx
	// 	sim.insert = bar_change_index(sim.insert, sim.insert_idx, COMPARE_DURATION)

	// 	sim.compare_idx = sim.insert_idx - 1
	// 	sim.compare = bar_change_index(sim.compare, sim.compare_idx, COMPARE_DURATION)
	// }
}
