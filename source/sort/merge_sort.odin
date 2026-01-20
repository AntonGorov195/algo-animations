package sort

import rl "vendor:raylib"

@(rodata)
MERGE_SORT_DUR: [MergeSortState]f32 = {
	.Uninitialized    = 0,
	.Initialize       = DEFAULT_STEP_DUR,
	.CheckWindowSize  = 0,
	.ResetWindowSlide = 0,
	.CheckWindowSlide = 0,
	.SetupWindow      = DEFAULT_STEP_DUR / 2,
	.StartMerge       = DEFAULT_STEP_DUR / 2,
	.InsertMerge      = DEFAULT_STEP_DUR / 2,
	.CheckDrainLeft   = 0,
	.DrainLeft        = DEFAULT_STEP_DUR / 2,
	.CheckDrainRight  = 0,
	.DrainRight       = DEFAULT_STEP_DUR / 2,
	.WriteToBuffer    = DEFAULT_STEP_DUR / 2,
	.MergeNext        = DEFAULT_STEP_DUR / 2,
	.MoveWindowStart  = 0,
	.CopyBuffer       = DEFAULT_STEP_DUR * 4,
	.Finish           = DEFAULT_STEP_DUR * 10,
	.Reset            = 0,
}
MergeSortState :: enum {
	Uninitialized,
	Initialize,
	CheckWindowSize,
	ResetWindowSlide,
	CheckWindowSlide,
	SetupWindow,
	StartMerge,
	InsertMerge,
	CheckDrainLeft,
	DrainLeft,
	CheckDrainRight,
	DrainRight,
	WriteToBuffer,
	MergeNext,
	MoveWindowStart,
	CopyBuffer,
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
	window_size:  int, // double each time.
	lwin:         int,
	lwin_end:     int,
	rwin:         int,
	rwin_end:     int,
	i, j, cursor: int, // merge
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
		algo.from_frame = exd({0, 0, 1, 0.5}, -0.09)
		algo.to_frame = exd({0, 0.5, 1, 0.5}, -0.1)
		algo.next_state = .Initialize
		algo.buffer = make([dynamic]BarValue, len(sort.vals))
		for &bar in sort.vals {
			bar.in_merge_sort_buf = false
			bar.merge_buf_idx = 0
		}
		merge_sort_begin_next_state(sort, algo)
		return false
	}

	for &bar, i in sort.vals {
		if bar.in_merge_sort_buf {
			bar.rect.end = htarn(&bar, len(sort.vals), bar.merge_buf_idx, algo.to_frame)
			algo.buffer[bar.merge_buf_idx].rect = bar.rect
		} else {
			bar.rect.end = htar(sort, i, algo.from_frame)
		}
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
	d :: proc(sort: ^Sort, algo: ^MergeSort) {
		t := sort.step_time / sort.step_dur
		{
			s := tiptar(sort, min(algo.prev.i, len(algo.buffer) - 1), algo.from_frame)
			e := tiptar(sort, min(algo.i, len(algo.buffer) - 1), algo.from_frame)
			csr(interp(s, e, t), width = CUSOR_WIDTH / 2)
		}
		{
			s := tiptar(sort, min(algo.prev.j, len(algo.buffer) - 1), algo.from_frame)
			e := tiptar(sort, min(algo.j, len(algo.buffer) - 1), algo.from_frame)
			csr(interp(s, e, t), width = CUSOR_WIDTH / 2)
		}
		{
			s := tiptar(sort, min(algo.prev.cursor, len(algo.buffer) - 1), algo.to_frame)
			e := tiptar(sort, min(algo.cursor, len(algo.buffer) - 1), algo.to_frame)
			csr(interp(s, e, t))
		}
		wnd(algo.from_frame, STACK_WINDOW_COLOR)
		wnd(algo.to_frame, STACK_WINDOW_COLOR)
		draw_bars(sort, sort.vals[:])
	}
	t := sort.step_time / sort.step_dur
	push_rect_matrix(sort.frame)
	switch algo.state {
	case .Initialize:
		window_color := STACK_WINDOW_COLOR
		window_color.a = u8(interp(f32(0), f32(window_color.a), t))
		wnd(algo.from_frame, window_color)
		wnd(algo.to_frame, window_color)
		draw_bars(sort, sort.vals[:])
	case .CheckWindowSize:
	// ---
	case .ResetWindowSlide:
		// ---
		wnd(algo.from_frame, STACK_WINDOW_COLOR)
		wnd(algo.to_frame, STACK_WINDOW_COLOR)
		draw_bars(sort, sort.vals[:])
	case .CheckWindowSlide:
	// ---
	case .SetupWindow:
		d(sort, algo)
	case .StartMerge:
		d(sort, algo)
	case .InsertMerge:
		d(sort, algo)
	case .CheckDrainLeft:
		d(sort, algo)
	case .DrainLeft:
		d(sort, algo)
	case .CheckDrainRight:
		d(sort, algo)
	case .DrainRight:
		d(sort, algo)
	case .WriteToBuffer:
		d(sort, algo)
	case .MergeNext:
		d(sort, algo)
	case .MoveWindowStart:
		d(sort, algo)
	case .CopyBuffer:
		d(sort, algo)
	case .Finish:
		window_color := STACK_WINDOW_COLOR
		window_color.a = u8(interp(f32(window_color.a), f32(0), t))
		wnd(algo.from_frame, window_color)
		wnd(algo.to_frame, window_color)
		draw_bars(sort, sort.vals[:])
	case .Reset:
		reset_sort(sort)
	case .Uninitialized:
		fallthrough
	case:
		unreachable()
	}
	// switch algo.state {
	// case .Initialize:
	// 	window_color := STACK_WINDOW_COLOR
	// 	window_color.a = u8(interp(f32(0), f32(window_color.a), t))
	// 	wnd(algo.from_frame, window_color)
	// 	wnd(algo.to_frame, window_color)
	// case .CheckWindowSize:
	// case .CheckWindowSlide:
	// case .StartWindowSlide:
	// case .StartMerge:
	// case .CompareMerge:
	// case .InsertMerge:
	// case .DrainLeft:
	// case .DrainRight:
	// case .CopyBuffer:
	// case .Finish:
	// case .Reset:
	// 	reset_sort(sort)
	// case .Uninitialized:
	// 	fallthrough
	// case:
	// 	unreachable()
	// }
	// draw_bars(sort.vals[:])
	pop_rect_matrix()
}
merge_sort_begin_next_state :: proc(sort: ^Sort, algo: ^MergeSort) {
	algo.state = algo.next_state
	sort.step_time -= sort.step_dur
	sort.step_dur = MERGE_SORT_DUR[algo.state]
	reset_bars(sort, MERGE_SORT_DUR[algo.state])
	if sort.step_dur != 0 {
		algo.prev = algo.idx
	}

	switch algo.state {
	case .Initialize:
		count := len(sort.vals)
		assert(len(algo.buffer) == count)
		algo.window_size = 1

		algo.next_state = .CheckWindowSize
	case .CheckWindowSize:
		count := len(sort.vals)
		if algo.window_size < count {
			// start window slide
			algo.next_state = .ResetWindowSlide
		} else {
			algo.next_state = .Finish
		}
	case .ResetWindowSlide:
		algo.lwin = 0
		algo.next_state = .CheckWindowSlide
	case .CheckWindowSlide:
		count := len(sort.vals)
		if algo.lwin < count {
			algo.next_state = .SetupWindow
		} else {
			algo.next_state = .CopyBuffer
		}
	case .SetupWindow:
		count := len(sort.vals)
		algo.lwin_end = algo.lwin + algo.window_size
		algo.rwin = algo.lwin_end
		algo.rwin_end = algo.rwin + algo.window_size
		algo.lwin_end = min(algo.rwin, count)
		algo.rwin = min(algo.rwin, count)
		algo.rwin_end = min(algo.rwin_end, count)
		if algo.rwin_end - algo.rwin == 0 {
			// early break when the second window is empty
			algo.next_state = .CopyBuffer
		} else {
			algo.next_state = .StartMerge
		}
	case .StartMerge:
		// merge
		algo.i = algo.lwin
		algo.j = algo.rwin
		algo.cursor = algo.lwin
		algo.next_state = .InsertMerge
	case .InsertMerge:
		if algo.i >= algo.lwin_end {
			// drain right
			algo.next_state = .CheckDrainRight
		} else if algo.j >= algo.rwin_end {
			// drain left
			algo.next_state = .CheckDrainLeft
		} else {
			// compare
			algo.next_state = .WriteToBuffer
		}
	case .MoveWindowStart:
		algo.lwin = algo.rwin_end
		algo.next_state = .CheckWindowSlide
	case .CheckDrainLeft:
		if algo.i < algo.lwin_end {
			algo.next_state = .DrainLeft
		} else {
			algo.next_state = .MoveWindowStart
		}
	case .DrainLeft:
		sort.vals[algo.i].in_merge_sort_buf = true
		sort.vals[algo.i].merge_buf_idx = algo.cursor
		algo.buffer[algo.cursor] = sort.vals[algo.i]
		algo.cursor += 1
		algo.i += 1
		algo.next_state = .CheckDrainLeft
	case .CheckDrainRight:
		if algo.j < algo.rwin_end {
			algo.next_state = .DrainRight
		} else {
			algo.next_state = .MoveWindowStart
		}
	case .DrainRight:
		sort.vals[algo.j].in_merge_sort_buf = true
		sort.vals[algo.j].merge_buf_idx = algo.cursor
		algo.buffer[algo.cursor] = sort.vals[algo.j]
		algo.cursor += 1
		algo.j += 1
		algo.next_state = .CheckDrainRight
	case .WriteToBuffer:
		if sort.vals[algo.i].value < sort.vals[algo.j].value {
			sort.vals[algo.i].in_merge_sort_buf = true
			sort.vals[algo.i].merge_buf_idx = algo.cursor
			algo.buffer[algo.cursor] = sort.vals[algo.i]
			algo.i += 1
			algo.next_state = .MergeNext
		} else {
			// insert right
			sort.vals[algo.j].in_merge_sort_buf = true
			sort.vals[algo.j].merge_buf_idx = algo.cursor
			algo.buffer[algo.cursor] = sort.vals[algo.j]
			algo.j += 1
			algo.next_state = .MergeNext
		}
	case .MergeNext:
		// move cursor
		algo.cursor += 1
		algo.next_state = .InsertMerge
	case .CopyBuffer:
		// copy from buffer to values
		count := len(sort.vals)
		for i in 0 ..< count {
			b := algo.buffer[i]
			sort.vals[i] = b
			sort.vals[i].in_merge_sort_buf = false
			// b.in_merge_sort_buf = false
			// b.merge_buf_idx = 0
			// b.rect = sort.vals[i].rect
			// sort.vals[i] = b
			// algo.buffer[i] = {}
		}
		reset_bars(sort, MERGE_SORT_DUR[algo.state])
		algo.window_size *= 2
		algo.next_state = .CheckWindowSize
	case .Finish:
		algo.next_state = .Reset
	case .Reset:
		reset_sort(sort)
	case .Uninitialized:
		fallthrough
	case:
		unreachable()
	}
}
// DEMO
merge_sort_demo :: proc(values: []f32) {
	// init
	count := len(values)
	if count == 0 {
		return
	}
	buffer := make([]f32, count, context.temp_allocator)
	window_size := 1
	// check if window size is reached end
	for window_size < count {
		// start window slide
		lwin: int
		for lwin < count {
			// select window bounds
			// setup window
			lwin_end := lwin + window_size
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
