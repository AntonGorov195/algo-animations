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
	.FindLeft           = DEFAULT_STEP_DUR,
	.FindRight          = DEFAULT_STEP_DUR,
	.SwapLeftRight      = DEFAULT_STEP_DUR,
	.AddLeftRightStacks = DEFAULT_STEP_DUR,
	.Finish             = DEFAULT_STEP_DUR,
	.Reset              = 0,
}
QuickSortState :: enum {
	Uninitialized,
	Initialize,
	CheckStackLength,
	PopStack,
	ChoosePivot,
	SwapPivot,
	FindLeft,
	FindRight,
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
		algo.prev = algo.idx
		quick_sort_begin_next_state(sort, algo)
		return sort.step_time < sort.step_dur
	}
	advance_sort(sort)
	return true
}
draw_quick_sort :: proc(sort: ^Sort, algo: ^QuickSort) {
	push_rect_matrix(sort.frame)
	draw_bars(sort.vals[:])
	pop_rect_matrix()
}
quick_sort_begin_next_state :: proc(sort: ^Sort, algo: ^QuickSort) {
	algo.state = algo.next_state
	sort.step_time -= sort.step_dur
	sort.step_dur = QUICK_SORT_DUR[algo.state]

	reset_bars(sort, QUICK_SORT_DUR[algo.state])

	switch algo.state {
	case .Initialize:
		append(&algo.stack, QuickSortSlice{start = 0, end = len(sort.vals)})
		algo.next_state = .CheckStackLength
	case .CheckStackLength:
		if len(algo.stack) == 0 {
			algo.next_state = .Finish
		} else {
			algo.next_state = .PopStack
		}
	case .PopStack:
		algo.win = pop(&algo.stack)
		algo.stack_len = len(algo.stack)
		algo.next_state = .ChoosePivot
	case .ChoosePivot:
		algo.pivot = (algo.win.end - algo.win.start) / 2 + algo.win.start
		algo.next_state = .SwapPivot
	case .SwapPivot:
		less_count: int
		for i in algo.win.start ..< algo.win.end {
			if sort.vals[i].value < sort.vals[algo.pivot].value {
				less_count += 1
			}
		}
		slice.swap(sort.vals[:], less_count + algo.win.start, algo.pivot)
		algo.pivot = less_count + algo.win.start
		if algo.pivot > algo.win.start && algo.pivot < algo.win.end - 1 {
			algo.left = algo.win.start
			algo.right = algo.win.end - 1
			algo.next_state = .FindLeft
		} else {
			algo.next_state = .AddLeftRightStacks
		}
	case .FindLeft:
		if algo.left < algo.pivot {
			if sort.vals[algo.left].value < sort.vals[algo.pivot].value {
				algo.left += 1
				algo.next_state = .FindLeft
			} else {
				algo.next_state = .FindRight
			}
		} else {
			algo.next_state = .AddLeftRightStacks
		}
	case .FindRight:
		if sort.vals[algo.right].value > sort.vals[algo.pivot].value {
			algo.right -= 1
			algo.next_state = .FindRight
		} else {
			algo.next_state = .SwapLeftRight
		}
	case .SwapLeftRight:
		slice.swap(sort.vals[:], algo.left, algo.right)
		algo.next_state = .FindLeft
	case .AddLeftRightStacks:
	case .Finish:
		algo.next_state = .Reset
	case .Reset:
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
