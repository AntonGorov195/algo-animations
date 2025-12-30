package game

import "core:math/rand"
import "core:slice"
import "vendor:clay"
import rl "vendor:raylib"

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
			bar.rect.type = .Linear
			bar.rect.dur = 0.1
		}
	}

	if g.input.start_sort {
		if len(g.main_sort.values) > 1 {
			DUR :: 0.3
			g.main_sort.step_dur = DUR
			g.main_sort.step_t = 0
			g.is_sorting = true
			for &bar, _ in g.main_sort.values {
				current := eval_anim(bar.rect)
				bar.rect.start = current
				bar.rect.dur = DUR
				bar.rect.t = 0
				bar.rect.type = .SmoothStep5
			}
			// queue animation for initializing the insertion sort display.
			algo := InsersionSort {
				step_dur = DUR,
				assist_opacity = {dur = DUR, end = 1, type = .SmoothStep3},
				head_cursor = {
					dur = DUR,
					start = g.main_sort.values[0].rect.start.x +
					g.main_sort.values[0].rect.start.width / 2,
					type = g.main_sort.values[0].rect.type,
				},
				insert_rect = {
					dur = DUR,
					start = extend_rect(eval_anim(g.main_sort.values[0].rect), 0),
					type = g.main_sort.values[0].rect.type,
				},
				compare_rect = {
					dur = DUR,
					start = extend_rect(eval_anim(g.main_sort.values[0].rect), 0),
					type = g.main_sort.values[0].rect.type,
				},
			}

			g.main_sort.algo = algo
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

advance_sort :: proc(sort: ^Sort, anim: ^Animated($T)) {
	anim.t += g.input.dt * (1 + sort.speed) * (1 + g.speed) / anim.dur
}