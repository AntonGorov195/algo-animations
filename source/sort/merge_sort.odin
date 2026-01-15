package sort

import rl "vendor:raylib"

@(rodata)
MERGE_SORT_DUR: [MergeSortState]f32 = {}
MergeSortState :: enum {
	Uninitialized,
	Initialize,
	Finish,
	Reset,
}
MergeSortSlice :: struct {
	start, end: int,
}
MergeSort :: struct {
	state:      MergeSortState,
	next_state: QuickSortState,
	windows:    [dynamic]MergeSortSlice,
	buffer:     [dynamic]int, //
	prev:       QuickSortIndices,
	using idx:  QuickSortIndices,
	from_frame: rl.Rectangle,
	to_frame:   rl.Rectangle,
}
MergeSortIndices :: struct {
	current_window: int,
	window_size:    int, // double each time.
}
process_merge_sort :: proc(sort: ^Sort, algo: ^MergeSort) -> (is_completed: bool) {
	is_completed = true

	if len(sort.vals) < 1 {
		reset_sort(sort)
		return true
	}

	// if algo.state == .Uninitialized {
	// 	sort.step_dur = 0
	// 	sort.step_time = 0
	// 	algo.bar_frame = exd({0, 0, 1, 1}, -0.1)
	// 	algo.next_state = .Initialize
	// 	quick_sort_begin_next_state(sort, algo)
	// 	return false
	// }

	// for &bar, i in sort.vals {
	// 	bar.rect.end = bar_target_rect(sort, i, algo.bar_frame)
	// }
	if sort.step_time >= sort.step_dur {
		// algo.prev = algo.idx
		// quick_sort_begin_next_state(sort, algo)
		return sort.step_time < sort.step_dur
	}
	advance_sort(sort)
	return true
}
draw_merge_sort :: proc(sort: ^Sort, algo: ^MergeSort) {
	push_rect_matrix(sort.frame)
	draw_bars(sort.vals[:])
	pop_rect_matrix()
}

// DEMO
merge_sort_demo :: proc(values: []f32) {
	count := len(values)
	if count == 0 {
		return
	}
	buffer := make([]f32, count, context.temp_allocator)
	window_size := 1
	for window_size < count {
		// can get 2 full sized window
		// can get 1 full size another one is partial
		// 1 partial - mem copy into buffer

		lwin: int
		for lwin < count {
			lwin_end := lwin
			rwin := lwin_end
			rwin_end := rwin + window_size
			lwin_end = min(lwin_end, count)
			rwin = min(lwin_end, count)
			rwin_end = min(lwin_end, count)
			merge_sort_demo_merge(
				values[lwin:lwin_end],
				values[rwin:rwin_end],
				buffer[lwin:rwin_end],
			)
			lwin = rwin_end
		}
		for i in 0 ..< count {
			values[i] = buffer[i]
		}
		window_size *= 2
	}
}
merge_sort_demo_merge :: proc(l, r: []f32, out: []f32) {
	assert(len(l) + len(r) == len(out))
	i, j: int
	cursor: int
	for {
		if i >= len(l) {
			// drain right
			for ; j < len(r); j += 1 {
				out[cursor] = r[j]
				cursor += 1
			}
			break
		}
		if j >= len(r) {
			// drain left
			for ; i < len(l); i += 1 {
				out[cursor] = l[i]
				cursor += 1
			}
			break
		}
		if l[i] < r[j] {
			out[cursor] = l[i]
			i += 1
		} else {
			out[cursor] = r[j]
			j += 1
		}
		cursor += 1
	}
}
