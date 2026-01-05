package game

import "core:math/rand"
import "core:slice"
import "sort"
import "vendor:clay"
import rl "vendor:raylib"

process :: proc() {
	clay.SetPointerState(g.input.mouse_pos, false)
	rand.reset(g.input.process_rng_seed)
	if rl.IsKeyPressed(.F3) {
		dev_cmd()
	}

	for &s in g.sorts {
		s.dt = g.input.dt
	}
	// g.main_sort.dt = g.input.dt
	if g.input.randomize {
		seed := rand.uint64()
		for &s in g.sorts {
			rand.reset(seed)
			rand.shuffle(s.vals[:])
			sort.reset_sort(&s)
		}
	}

	if g.input.start_bubble2_sort {
		g.sorts[0].algo = sort.BubbleSort{}
	}
	// if g.input.start_quick_sort {
	// 	if len(g.main_sort.vals) > 0 {
	// 		DUR :: 0.1
	// 		g.is_sorting = true
	// 		for &bar, _ in g.main_sort.vals {
	// 			current := sort.eval(bar.rect)
	// 			bar.rect.start = current
	// 			bar.rect.dur = DUR
	// 			bar.rect.t = 0
	// 			bar.rect.type = .SmoothStep3
	// 		}
	// 		// queue animation for initializing the insertion sort display.
	// 		algo := sort.QuickSort {
	// 			step_dur = sort.quick_sort_state_dur[.Initialize],
	// 		}
	// 		g.main_sort.algo = algo
	// 	}
	// }
	for &s in g.sorts {
		for _ in 0 ..< 10_000 {
			if sort.process_sort(&s) {
				break
			}
		}
	}
	clean_sound_pool()
}


insertion_sort_demo :: proc(values: []f32) {
	// start
	head: int
	insert: int
	compared: int

	// move head
	for head = 1; head < len(values); head += 1 {
		insert = head
		compared = insert - 1
		// compare
		for values[compared] > values[insert] {
			// swap
			slice.swap(values, insert, compared)
			if compared < 0 {
				break
			}
			// move next
			insert -= 1
			compared -= 1
		}
	}
	// end
}
