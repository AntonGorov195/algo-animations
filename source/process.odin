package game

import "core:log"
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
			bar.rect.type = .SmoothStep5
			bar.rect.dur = 1
		}
	}

	if g.input.start_insertion_sort {
		if len(g.main_sort.values) > 0 {
			DUR :: 0.1
			g.is_sorting = true
			for &bar, _ in g.main_sort.values {
				current := eval_anim(bar.rect)
				bar.rect.start = current
				bar.rect.dur = DUR
				bar.rect.t = 0
				bar.rect.type = .SmoothStep3
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
	if g.input.start_bubble_sort {
		if len(g.main_sort.values) > 0 {
			DUR :: 0.1
			g.is_sorting = true
			for &bar, _ in g.main_sort.values {
				current := eval_anim(bar.rect)
				bar.rect.start = current
				bar.rect.dur = DUR
				bar.rect.t = 0
				bar.rect.type = .SmoothStep3
			}
			// queue animation for initializing the insertion sort display.
			algo := BubbleSort {
				step_dur = DUR,
				assist_opacity = {dur = DUR, end = 1, type = .SmoothStep3},
				end_cursor = {
					dur = DUR,
					start = g.main_sort.values[0].rect.start.x +
					g.main_sort.values[0].rect.start.width / 2,
					type = g.main_sort.values[0].rect.type,
				},
				bubble_rect = {
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
	if g.input.start_quick_sort {
		if len(g.main_sort.values) > 0 {
			DUR :: 0.1
			g.is_sorting = true
			for &bar, _ in g.main_sort.values {
				current := eval_anim(bar.rect)
				bar.rect.start = current
				bar.rect.dur = DUR
				bar.rect.t = 0
				bar.rect.type = .SmoothStep3
			}
			// queue animation for initializing the insertion sort display.
			algo := QuickSort{}

			g.main_sort.algo = algo
		}
	}
	for i in 0 ..< 10_000 {
		if process_sort(&g.main_sort) {
			break
		}
		log.info(i)
	}
	clean_sound_pool()
}

bubble_sort_demo :: proc(values: []f32) {
	// init
	end: int
	current: int
	compare: int
	// move end
	for end = len(values) - 1; end > 0; end -= 1 {
		// bubble
		for current = 0; current < end; current += 1 {
			// compare
			compare = current + 1
			if values[current] > values[compare] {
				// swap
				slice.swap(values, current, compare)
			}
		}
	}
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

advance_sort :: proc(sort: ^Sort, anim: ^Animated($T)) {
	anim.t += g.input.dt * (1 + sort.speed) * (1 + g.speed) / anim.dur
}
