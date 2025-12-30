package game

import "core:math/rand"
import "core:slice"
import "vendor:clay"
import rl "vendor:raylib"

// RANDOMIZE_DURATION :: AnimationData {
// 	dur  = 0.1,
// 	type = .SmoothStep3,
// }
// INITIALIZATION_DURATION :: AnimationData {
// 	dur  = 0.3,
// 	type = .SmoothStep3,
// }
// MOVE_HEAD_DURATION :: AnimationData {
// 	dur  = 1.1,
// 	type = .SmoothStep5,
// }
// SWAP_DURATION :: AnimationData {
// 	dur  = 0.8,
// 	type = .SmoothStep3,
// }
// COMPARE_DURATION :: AnimationData {
// 	dur  = 1,
// 	type = .SmoothStep3,
// }

process :: proc() {
	clay.SetPointerState(g.input.mouse_pos, false)
	rand.reset(g.input.process_rng_seed)
	if rl.IsKeyPressed(.F3) {
		dev_cmd()
	}

	if g.input.randomize {
		g.main_sort.algo = nil
		rand.shuffle(g.main_sort.values[:])
		for &bar, _ in g.main_sort.values {
			current := eval_anim(bar.rect)
			bar.rect.start = current
			bar.rect.t = 0
		}
	}

	if g.input.start_sort {
		if len(g.main_sort.values) > 1 {
			g.is_sorting = true
			// queue animation for initializing the insertion sort display.
			g.main_sort.algo = InsersionSort {
				step_dur = 1,
				assist_opacity = {dur = 1, end = 1, type = .SmoothStep3},
			}
		}
	}
	process_sort(&g.main_sort)
	// switch &sort in g.sort {
	// case nil:
	// 	sort.step_t += g.input.dt * (1 + g.speed) / sort.step_dur
	// 	for &bar in g.values {
	// 		advance_anim(&bar.rect)
	// 	}
	// case InsersionSort:
	// 	sort.step_t += g.input.dt * (1 + g.speed) / sort.step_dur
	// 	for &bar in g.values {
	// 		advance_anim(&bar.rect)
	// 	}
	// 	advance_anim(&sort.assist_opacity)
	// 	advance_anim(&sort.head_cursor)
	// 	advance_anim(&sort.insert_rect)
	// 	advance_anim(&sort.compare_rect)
	// 	switch sort.state {
	// 	case .Initialization:
	// 		// ended
	// 		if sort.step_t >= 1 {
	// 			assert(sort.head == 0)
	// 			assert(sort.insert == 0)
	// 			assert(sort.compare == 0)
	// 			sort.state = .MoveHead // start comparing the two
	// 			// queue animation here
	// 		}
	// 	case .MoveHead:
	// 	// Two cases
	// 	// 	1. move head forward
	// 	// 	2. the head is already at the last element, finalize the animation
	// 	case .Swap:
	// 		if sort.step_t >= 1 {
	// 			// sort.state = .MoveNext // continue sort
	// 			// sort.state = .MoveHead // reached the start of the list
	// 		}
	// 	case .Compare:
	// 		if sort.step_t >= 1 {
	// 			// Depending on the result of the compare
	// 			// sort.state = .Swap //
	// 			// sort.state = .MoveHead // start comparing the two
	// 		}
	// 	case .MoveNext:
	// 	}
	// case:
	// 	unreachable()
	// }
	clean_sound_pool()
}
insertion_sort_demo :: proc(values: []f32) {
	// start
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
	// end
}
// process_insertion_sort :: proc(sim: ^InsersionSort) {
// 	advance :: proc(sim: ^InsersionSort, anim := AnimationData{}) {
// 		step_dt := g.input.dt * (1 + g.speed) / anim.dur
// 		sim.step_t += step_dt
// 		sim.head.t += step_dt
// 		sim.insert.t += step_dt
// 		sim.compare.t += step_dt
// 		for &bar in g.values {
// 			bar.pos.t += step_dt
// 		}
// 	}
// 	assert(len(g.values) > 1)
// 	advance(sim, insert_sort_anim[sim.state])
// 	switch sim.state {
// 	case .Initialization:
// 		if sim.step_t > 1 {
// 			// Ended
// 			sim.state = .MoveHead
// 			sim.step_t = 0
// 			sim.head = {
// 				start = interp(
// 					sim.head.start,
// 					sim.head.end,
// 					sim.head.t,
// 					INITIALIZATION_DURATION.type,
// 				),
// 				end   = 1,
// 				t     = 0,
// 			}
// 			sim.head_idx = 1

// 			sim.insert = {
// 				start = interp(
// 					sim.insert.start,
// 					sim.insert.end,
// 					sim.insert.t,
// 					INITIALIZATION_DURATION.type,
// 				),
// 				end   = 1,
// 				t     = 0,
// 			}
// 			sim.insert_idx = 1
// 		}
// 	case .MoveHead:
// 		if sim.step_t > 1 {
// 			sim.state = .Compare
// 			sim.step_t = 0
// 		}
// 	case .Swap:
// 		if sim.step_t > 1 {
// 			// sim.state = .Compare
// 			sim.state = .MoveNext
// 			sim.step_t = 0
// 		}
// 	case .Compare:
// 		if sim.step_t > 1 {
// 			sim.state = .Compare
// 			// sim.state = .MoveHead
// 			sim.step_t = 0
// 		}
// 	case .MoveNext:
// 		if sim.step_t > 1 {
// 			sim.state = .Compare
// 			sim.step_t = 0
// 		}
// 	}
// }
// insertion_sort_compare :: proc(sim: ^InsersionSort) {
// 	assert(sim != nil)
// 	assert(sim.head_idx > 0)
// 	assert(sim.head_idx < len(g.values))
// 	assert(sim.insert_idx > 0)
// 	assert(sim.insert_idx < len(g.values))
// 	assert(sim.compare_idx > 0)
// 	assert(sim.compare_idx < len(g.values))
// 	if g.values[sim.compare_idx].value > g.values[sim.insert_idx].value {

// 	} else {

// 	}
// 	// 	sim.state = .Swap
// 	// 	sim.step_t = 0
// 	// 	slice.swap(g.values[:], sim.insert_idx, sim.compare_idx)
// 	// 	sim.insert_idx -= 1
// 	// 	sim.compare_idx -= 1

// 	// 	sim.head = bar_change_index(sim.head, sim.head_idx, COMPARE_DURATION)
// 	// 	sim.insert = bar_change_index(sim.insert, sim.insert_idx, COMPARE_DURATION)
// 	// 	sim.compare = bar_change_index(sim.compare, sim.compare_idx, COMPARE_DURATION)
// 	// } else {
// 	// 	sim.state = .MoveHead
// 	// 	sim.step_t = 0
// 	// 	sim.head_idx += 1
// 	// 	if sim.head_idx >= len(g.values) {
// 	// 		g.sim = Randomize{}
// 	// 		return
// 	// 	}
// 	// 	sim.head = bar_change_index(sim.head, sim.head_idx, COMPARE_DURATION)

// 	// 	sim.insert_idx = sim.head_idx
// 	// 	sim.insert = bar_change_index(sim.insert, sim.insert_idx, COMPARE_DURATION)

// 	// 	sim.compare_idx = sim.insert_idx - 1
// 	// 	sim.compare = bar_change_index(sim.compare, sim.compare_idx, COMPARE_DURATION)
// 	// }
// }
advance_sort :: proc(sort: ^Sort, anim: ^Animated($T)) {
	anim.t += g.input.dt * (1 + sort.speed) * (1 + g.speed) / anim.dur
}
