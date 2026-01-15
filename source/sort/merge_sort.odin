package sort

import rl "vendor:raylib"

@(rodata)
MERGE_SORT_DUR: [MergeSortState]f32 = {
	.Uninitialized = 0,
	.Initialize = DEFAULT_STEP_DUR,
	.CheckWindowSize = DEFAULT_STEP_DUR,
	.Finish = DEFAULT_STEP_DUR,
	.Reset = 0,
}
MergeSortState :: enum {
	Uninitialized,
	Initialize,
	CheckWindowSize,
	Finish,
	Reset,
}
MergeSort :: struct {
	state:      MergeSortState,
	next_state: MergeSortState,
	buffer:     [dynamic]BarValue, //
	prev:       MergeSortIndices,
	using idx:  MergeSortIndices,
	from_frame: rl.Rectangle,
	to_frame:   rl.Rectangle,
}
MergeSortIndices :: struct {
	window_size:    int, // double each time.
}
process_merge_sort :: proc(sort: ^Sort, algo: ^MergeSort) -> (is_completed: bool) {
	is_completed = true

	if len(sort.vals) < 1 {
		reset_sort(sort)
		return true
	}

	if algo.state == .Uninitialized {
		sort.step_dur = 0
		sort.step_time = 0
		algo.from_frame = exd({0, 0, 1, 0.5}, -0.03)
		algo.to_frame = exd({0, 0.5, 1, 0.5}, -0.03)
		algo.next_state = .Initialize
		merge_sort_begin_next_state(sort, algo)
		return false
	}

	for &bar, i in sort.vals {
		bar.rect.end = bar_target_rect(sort, i, algo.from_frame)
	}
	if sort.step_time >= sort.step_dur {
		algo.prev = algo.idx
		merge_sort_begin_next_state(sort, algo)
		return sort.step_time < sort.step_dur
	}
	advance_sort(sort)
	return true
}
draw_merge_sort :: proc(sort: ^Sort, algo: ^MergeSort) {
	push_rect_matrix(sort.frame)
	wnd(algo.from_frame, STACK_WINDOW_COLOR)
	wnd(algo.to_frame, STACK_WINDOW_COLOR)
	draw_bars(sort.vals[:])
	pop_rect_matrix()
}
merge_sort_begin_next_state :: proc(sort: ^Sort, algo: ^MergeSort) {
	algo.state = algo.next_state
	sort.step_time -= sort.step_dur
	sort.step_dur = MERGE_SORT_DUR[algo.state]

	reset_bars(sort, MERGE_SORT_DUR[algo.state])
	switch algo.state {
	case .Initialize:
	case .CheckWindowSize:
	case .Finish:
	case .Reset:
		reset_sort(sort)
	case .Uninitialized:
		fallthrough
	case:
		unreachable()
	}
	// algo.prev = algo.idx
	// algo.next_state = .CheckStackLength
}
// DEMO
merge_sort_demo :: proc(values: []f32) {
	count := len(values)
	if count == 0 {
		return
	}
	buffer := make([]f32, count, context.temp_allocator)
	window_size := 1
	// check end
	for window_size < count {
		// begin window
		lwin: int
		for lwin < count {
			// select window bounds
			lwin_end := lwin+ window_size
			rwin := lwin_end
			rwin_end := rwin + window_size
			lwin_end = min(rwin, count)
			rwin = min(rwin, count)
			rwin_end = min(rwin_end, count)
			if rwin_end - rwin == 0 {
				// early break when the second window is empty
				break
			}
			// merge windows
			merge_sort_demo_merge(
				values[lwin:lwin_end],
				values[rwin:rwin_end],
				buffer[lwin:rwin_end],
			)
			// move window
			lwin = rwin_end
		}
		// copy from buffer to values
		for i in 0 ..< count {
			values[i] = buffer[i]
		}
		// change win size
		window_size *= 2
	}
	// fin
}
merge_sort_demo_merge :: proc(l, r: []f32, out: []f32) {
	assert(len(l) + len(r) == len(out))
	// start 
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
		// compare
		if l[i] < r[j] {
			// insert left
			out[cursor] = l[i]
			i += 1
		} else {
			// insert right
			out[cursor] = r[j]
			j += 1
		}
		// move cursor
		cursor += 1
	}
}
