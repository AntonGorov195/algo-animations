package game

import "core:log"
import "core:math/rand"
import "core:slice"
import R "resources"
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

	if g.input.start_bubble_sort {
		g.sorts[0].algo = sort.BubbleSort{}
	}
	if g.input.start_insertion_sort {
		g.sorts[0].algo = sort.InsertionSort{}
	}
	if g.input.start_quick_sort {
		g.sorts[0].algo = sort.QuickSort{}
	}
	if g.input.start_merge_sort {
		g.sorts[0].algo = sort.MergeSort{}
	}
	if g.input.start_super_sort {
		if len(g.sorts) == 4 {
			g.sorts[0].algo = sort.BubbleSort{}
			g.sorts[1].algo = sort.InsertionSort{}
			g.sorts[2].algo = sort.QuickSort{}
			g.sorts[3].algo = sort.MergeSort{}
		} else {
			log.debug("invalid sort count for super sort")
		}
	}
	g.sorts[0].texture = R.get(g.bubble_texture)
	g.sorts[1].texture = R.get(g.insert_texture)
	g.sorts[2].texture = R.get(g.quick_texture)
	g.sorts[3].texture = R.get(g.merge_texture)
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
