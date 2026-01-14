package sort

import "core:log"
_ :: log
import "core:slice"
import rl "vendor:raylib"

QUICK_SORT_DUR: [QuickSortState]f32 = {
	.Uninitialized      = 0,
	.Initialize         = DEFAULT_STEP_DUR,
	.CheckStackLength   = 0,
	.PopStack           = DEFAULT_STEP_DUR,
	.ChoosePivot        = DEFAULT_STEP_DUR,
	.SwapPivot          = DEFAULT_STEP_DUR,
	.PartitionStart     = DEFAULT_STEP_DUR,
	.CompareLeft        = 0,
	.NextLeft           = DEFAULT_STEP_DUR,
	.CompareRight       = 0,
	.NextRight          = DEFAULT_STEP_DUR,
	.SwapLeftRight      = DEFAULT_STEP_DUR,
	.AddLeftRightStacks = DEFAULT_STEP_DUR * 2,
	.Finish             = DEFAULT_STEP_DUR * 3,
	.Reset              = 0,
}
QuickSortState :: enum {
	Uninitialized,
	Initialize,
	CheckStackLength,
	PopStack,
	ChoosePivot,
	SwapPivot,
	PartitionStart,
	CompareLeft,
	NextLeft,
	CompareRight,
	NextRight,
	SwapLeftRight,
	AddLeftRightStacks,
	Finish,
	Reset,
}
QuickSortSlice :: struct {
	// rect:       Animated(rl.Rectangle),
	start, end: int,
	from:       int, // pivot
}
QuickSort :: struct {
	stack:      [dynamic]QuickSortSlice,
	prev:       QuickSortIndices,
	using idx:  QuickSortIndices,
	state:      QuickSortState,
	next_state: QuickSortState,
	bar_frame:  rl.Rectangle,
}
QuickSortIndices :: struct {
	pivot, left, right, stack_len: int,
	win:                           QuickSortSlice,
}
process_quick_sort :: proc(sort: ^Sort, algo: ^QuickSort) -> (is_completed: bool) {
	is_completed = true

	if len(sort.vals) < 1 {
		reset_sort(sort)
		return true
	}

	if algo.state == .Uninitialized {
		sort.step_dur = 0
		sort.step_time = 0
		algo.bar_frame = exd({0, 0, 1, 1}, -0.1)
		algo.next_state = .Initialize
		quick_sort_begin_next_state(sort, algo)
		return false
	}

	for &bar, i in sort.vals {
		bar.rect.end = bar_target_rect(sort, i, algo.bar_frame)
	}
	if sort.step_time >= sort.step_dur {
		// algo.prev = algo.idx
		quick_sort_begin_next_state(sort, algo)
		return sort.step_time < sort.step_dur
	}
	advance_sort(sort)
	return true
}
draw_quick_sort :: proc(sort: ^Sort, algo: ^QuickSort) {
	hr :: proc(rect: rl.Rectangle, color: rl.Color, extend: f32 = HIGHLIGHT_EXD) {
		rl.DrawRectangleRec(exd(rect, extend), color)
	}
	csr :: proc(
		tip: [2]f32,
		width: f32 = CUSOR_WIDTH,
		height: f32 = CUSOR_HEIGHT,
		color: rl.Color = CURSOR_COLOR,
	) {
		draw_cursor_tip(tip, width, height, color)
	}
	wnd :: proc(rect: rl.Rectangle, color: rl.Color, extend: f32 = WINDOW_EXD) {
		rl.DrawRectangleRec(exd(rect, extend), color)
	}

	t := sort.step_time / sort.step_dur
	push_rect_matrix(sort.frame)
	log.debug(algo.state)
	switch algo.state {
	case .Initialize:
		window_color := STACK_WINDOW_COLOR
		window_color.a = u8(interp(f32(0), f32(window_color.a), t))
		wnd(wintra(sort, 0, len(sort.vals)), window_color)
		draw_bars(sort.vals[:])
	case .CheckStackLength:
	// ---
	case .PopStack:
		for w in algo.stack {
			wnd(wintra(sort, w.start, w.end), STACK_WINDOW_COLOR)
		}
		window_color := interp(STACK_WINDOW_COLOR, SELECT_WINDOW_COLOR, t)
		wnd(wintra(sort, algo.win.start, algo.win.end), window_color)
		draw_bars(sort.vals[:])
	case .ChoosePivot:
		for w in algo.stack {
			wnd(wintra(sort, w.start, w.end), STACK_WINDOW_COLOR)
		}
		wnd(wintra(sort, algo.win.start, algo.win.end), SELECT_WINDOW_COLOR)
		hr(htra(sort, algo.pivot), PIVOT_COLOR)
		draw_bars(sort.vals[:])
	case .SwapPivot:
		for w in algo.stack {
			wnd(wintra(sort, w.start, w.end), STACK_WINDOW_COLOR)
		}
		wnd(wintra(sort, algo.win.start, algo.win.end), SELECT_WINDOW_COLOR)
		hr(htra(sort, algo.pivot), PIVOT_COLOR)
		draw_bars(sort.vals[:])
	case .PartitionStart:
		for w in algo.stack {
			wnd(wintra(sort, w.start, w.end), STACK_WINDOW_COLOR)
		}
		cmp_color := COMPARE_COLOR
		cmp_color.a = u8(interp(f32(0), f32(cmp_color.a), t))
		wnd(wintra(sort, algo.win.start, algo.win.end), SELECT_WINDOW_COLOR)
		hr(htra(sort, algo.left), cmp_color)
		hr(htra(sort, algo.right), cmp_color)
		hr(htra(sort, algo.pivot), PIVOT_COLOR)
		draw_bars(sort.vals[:])
	case .CompareLeft:
	// ---
	case .NextLeft:
		for w in algo.stack {
			wnd(wintra(sort, w.start, w.end), STACK_WINDOW_COLOR)
		}
		wnd(wintra(sort, algo.win.start, algo.win.end), SELECT_WINDOW_COLOR)
		hr(htrai(sort, algo.prev.left, algo.left, t), COMPARE_COLOR)
		hr(htrai(sort, algo.prev.right, algo.right, t), COMPARE_COLOR)
		hr(htra(sort, algo.pivot), PIVOT_COLOR)
		draw_bars(sort.vals[:])
	case .CompareRight:
	// ---
	case .NextRight:
		for w in algo.stack {
			wnd(wintra(sort, w.start, w.end), STACK_WINDOW_COLOR)
		}
		wnd(wintra(sort, algo.win.start, algo.win.end), SELECT_WINDOW_COLOR)
		hr(htrai(sort, algo.prev.left, algo.left, t), SELECTED_COLOR)
		hr(htrai(sort, algo.prev.right, algo.right, t), COMPARE_COLOR)
		hr(htra(sort, algo.pivot), PIVOT_COLOR)
		draw_bars(sort.vals[:])
	case .SwapLeftRight:
		for w in algo.stack {
			wnd(wintra(sort, w.start, w.end), STACK_WINDOW_COLOR)
		}
		wnd(
			wintar(sort, algo.win.start, algo.win.end, algo.bar_frame, match_height = true),
			SELECT_WINDOW_COLOR,
		)
		hr(htra(sort, algo.left), SELECTED_COLOR)
		hr(htra(sort, algo.right), SELECTED_COLOR)
		hr(htra(sort, algo.pivot), PIVOT_COLOR)
		draw_bars(sort.vals[:])
	case .AddLeftRightStacks:
		for w in algo.stack[:algo.prev.stack_len] {
			wnd(wintra(sort, w.start, w.end), STACK_WINDOW_COLOR)
		}
		for w in algo.stack[algo.prev.stack_len:] {
			wnd(
				interp(
					exd(htra(sort, algo.pivot), WINDOW_EXD),
					wintra(sort, w.start, w.end),
					t * 1.1,
				),
				STACK_WINDOW_COLOR,
			)
		}
		window_color := interp(
			SELECT_WINDOW_COLOR,
			rl.Color{SELECT_WINDOW_COLOR.r, SELECT_WINDOW_COLOR.g, SELECT_WINDOW_COLOR.b, 0},
			t,
		)
		wnd(wintra(sort, algo.win.start, algo.win.end), window_color)
		{
			color := COMPARE_COLOR
			color.a = u8(interp(255, 0, t))
			hr(htra(sort, algo.left), color)
			hr(htra(sort, algo.right), color)
		}
		hr(htra(sort, algo.pivot), PIVOT_COLOR)
		draw_bars(sort.vals[:])
	case .Finish:
		for bar, i in sort.vals {
			t := t
			t *= 2
			t -= f32(i) / f32(len(sort.vals))
			t = min(1, max(0, t))
			rect := eval(bar.rect)
			rect = exd(rect, -0.25 * rect.width * (-4 * t * (t - 1)))
			rl.DrawRectangleRec(rect, bar.real_place == i ? rl.GREEN : rl.BLACK)
		}
	case .Reset:
	case .Uninitialized:
		fallthrough
	case:
		unreachable()
	}
	pop_rect_matrix()
}
quick_sort_begin_next_state :: proc(sort: ^Sort, algo: ^QuickSort) {
	algo.state = algo.next_state
	sort.step_time -= sort.step_dur
	sort.step_dur = QUICK_SORT_DUR[algo.state]

	reset_bars(sort, QUICK_SORT_DUR[algo.state])

	switch algo.state {
	case .Initialize:
		algo.prev = algo.idx
		append(&algo.stack, QuickSortSlice{start = 0, end = len(sort.vals)})
		algo.stack_len = len(algo.stack)
		algo.next_state = .CheckStackLength
	case .CheckStackLength:
		algo.prev = algo.idx
		if len(algo.stack) == 0 {
			algo.next_state = .Finish
		} else {
			algo.next_state = .PopStack
		}
	case .PopStack:
		algo.prev = algo.idx
		algo.win = pop(&algo.stack)
		algo.stack_len = len(algo.stack)
		assert(algo.win.end - algo.win.start > 0)
		if algo.win.end - algo.win.start == 1 {
			algo.next_state = .CheckStackLength
		} else {
			algo.next_state = .ChoosePivot
		}
	case .ChoosePivot:
		algo.prev = algo.idx
		algo.pivot = (algo.win.end - algo.win.start) / 2 + algo.win.start
		algo.next_state = .SwapPivot
	case .SwapPivot:
		algo.prev = algo.idx
		less_count: int
		for i in algo.win.start ..< algo.win.end {
			if sort.vals[i].value < sort.vals[algo.pivot].value {
				less_count += 1
			}
		}
		slice.swap(sort.vals[:], less_count + algo.win.start, algo.pivot)
		algo.pivot = less_count + algo.win.start
		if algo.pivot == algo.win.start {
			algo.next_state = .AddLeftRightStacks
			append(
				&algo.stack,
				QuickSortSlice{from = algo.pivot, start = algo.pivot + 1, end = algo.win.end},
			)
			algo.stack_len = len(algo.stack)
		} else if algo.pivot == algo.win.end - 1 {
			algo.next_state = .AddLeftRightStacks
			append(
				&algo.stack,
				QuickSortSlice{from = algo.pivot, start = algo.win.start, end = algo.pivot},
			)
			algo.stack_len = len(algo.stack)
		} else {
			algo.left = algo.win.start
			algo.right = algo.win.end - 1
			algo.next_state = .PartitionStart
		}
	case .PartitionStart:
		algo.prev = algo.idx
		algo.next_state = .CompareLeft
	case .CompareLeft:
		algo.prev = algo.idx
		if algo.left < algo.pivot {
			if sort.vals[algo.left].value < sort.vals[algo.pivot].value {
				algo.left += 1
				algo.next_state = .NextLeft
			} else {
				algo.next_state = .CompareRight
			}
		} else {
			algo.next_state = .AddLeftRightStacks
			append(
				&algo.stack,
				QuickSortSlice{from = algo.pivot, start = algo.pivot + 1, end = algo.win.end},
			)
			append(
				&algo.stack,
				QuickSortSlice{from = algo.pivot, start = algo.win.start, end = algo.pivot},
			)
			algo.stack_len = len(algo.stack)
		}
	case .NextLeft:
		algo.next_state = .CompareLeft
	case .CompareRight:
		algo.prev = algo.idx
		if sort.vals[algo.right].value > sort.vals[algo.pivot].value {
			algo.right -= 1
			algo.next_state = .NextRight
		} else {
			algo.next_state = .SwapLeftRight
		}
	case .NextRight:
		algo.next_state = .CompareRight
	case .SwapLeftRight:
		algo.prev = algo.idx
		slice.swap(sort.vals[:], algo.left, algo.right)
		algo.next_state = .CompareLeft
	case .AddLeftRightStacks:
		algo.next_state = .CheckStackLength
	case .Finish:
		algo.prev = algo.idx
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
quick_sort_demo :: proc(values: []f32) {
	// initialize stack
	stack := make([dynamic][]f32, context.temp_allocator)
	append(&stack, values)

	for len(stack) > 0 {
		// pop slice
		vals := pop(&stack)
		count := len(vals)
		if count <= 1 {
			continue
		}
		// find pivot
		pivot_i := count / 2
		pivot := vals[pivot_i]
		less_count: int
		// find how many are on the left side
		for value in vals {
			if value < pivot {
				less_count += 1
			}
		}
		// swap the pivot to the correct position
		slice.swap(vals, less_count, pivot_i)
		pivot_i = less_count
		// start search
		left_i: int
		right_i := count - 1
		// start partition
		for left_i < pivot_i {
			// find a left
			if vals[left_i] < pivot {
				left_i += 1
				continue
			}

			// find right
			for vals[right_i] > pivot {
				right_i -= 1
			}
			// swap
			slice.swap(vals, left_i, right_i)
			less_count -= 1
		}
		// append right
		append(&stack, vals[pivot_i + 1:])
		// append left
		append(&stack, vals[:pivot_i])
	}
	// fin
}
