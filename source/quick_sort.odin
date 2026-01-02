package game

import "core:log"
_ :: log
import "core:slice"
import rl "vendor:raylib"

quick_sort_state_dur: [QuickSortState]f32 = {
	.Initialize         = 0.1,
	.CheckStackLength   = 0.1,
	.PopStack           = 0.1,
	.ChoosePivot        = 0.1,
	.CountLess          = 0.1,
	.SwapPivot          = 0.1,
	.CheckPartitionEnd  = 0.1,
	.PartitionLeftSide  = 0.1,
	.PartitionRightSide = 0.1,
	.SwapLeftRight      = 0.1,
	.AddLeftRightStacks = 0.1,
}
QuickSortState :: enum {
	Initialize,
	CheckStackLength,
	PopStack,
	ChoosePivot,
	CountLess,
	SwapPivot,
	CheckPartitionEnd,
	PartitionLeftSide,
	PartitionRightSide,
	SwapLeftRight,
	AddLeftRightStacks,
}
QuickSortSlice :: struct {
	rect:       Animated(rl.Rectangle),
	start, end: int,
}
QuickSort :: struct {
	stack:        [dynamic]QuickSortSlice,
	current:      QuickSortSlice,
	pivot_rect:   Animated(rl.Rectangle),
	left_cursor:  Animated(f32),
	right_cursor: Animated(f32),
	pivot:        int,
	less_count:   int,
	left:         int,
	right:        int,
	state:        QuickSortState,
	step_time:    f32,
	step_dur:     f32,
}

process_quick_sort :: proc(sort: ^Sort, algo: ^QuickSort) -> (is_completed: bool) {
	defer {
		algo.step_time += g.input.dt * (1 + sort.speed) * (1 + g.speed)
		for &bar in sort.values {
			advance_sort(sort, &bar.rect)
		}
		advance_sort(sort, &algo.current.rect)
		for &s in algo.stack {
			advance_sort(sort, &s.rect)
		}
	}
	for &bar, i in sort.values {
		bar.rect.end = quick_sort_fin_rect(sort.values[:], i)
	}
	// algo.current.rect.end = quick_sort_slice_rect(sort.values[:], algo.current)
	switch algo.state {
	case .Initialize:
		if algo.step_time < algo.step_dur {
			return true
		}
		s := QuickSortSlice {
			start = 0,
			end   = len(sort.values),
		}
		r := Animated(rl.Rectangle) {
			start = {0.5, 0.5, 0, 0},
			end   = quick_sort_slice_rect(sort.values[:], s),
			dur   = quick_sort_state_dur[.Initialize],
			type  = .SmoothStep3,
		}
		s.rect = r
		append(&algo.stack, s)
		return quick_sort_change_state(sort, algo, .CheckStackLength)
	case .CheckStackLength:
		if algo.step_time < algo.step_dur {
			return true
		}
		if len(algo.stack) == 0 {
			delete(algo.stack) // may not be necessary depending on the allocator
			reset_sort(sort)
		} else {
			return quick_sort_change_state(sort, algo, .PopStack)
		}
	case .PopStack:
		if algo.step_time < algo.step_dur {
			return true
		}
		algo.current = pop(&algo.stack)
		algo.current.rect.start = quick_sort_slice_rect(sort.values[:], algo.current)
		algo.current.rect.end = quick_sort_slice_rect(sort.values[:], algo.current)
		if algo.current.start >= algo.current.end - 1 {
			return quick_sort_change_state(sort, algo, .CheckStackLength)
		} else {
			return quick_sort_change_state(sort, algo, .ChoosePivot)
		}
	case .ChoosePivot:
		if algo.step_time < algo.step_dur {
			return true
		}
		algo.pivot = qs_len(algo.current) / 2
		return quick_sort_change_state(sort, algo, .CountLess)
	case .CountLess:
		if algo.step_time < algo.step_dur {
			return true
		}
		algo.less_count = 0
		vals := qs_to(sort.values[:], algo.current)
		p := vals[algo.pivot]
		for value in vals {
			if value.value < p.value {
				algo.less_count += 1
			}
		}
		return quick_sort_change_state(sort, algo, .SwapPivot)
	case .SwapPivot:
		// end_rect := quick_sort_fin_rect(sort.values[:], algo.end)
		// bubble_rect := quick_sort_fin_rect(sort.values[:], algo.bubble)
		// compare_rect := quick_sort_fin_rect(sort.values[:], algo.compare)

		if algo.step_time < algo.step_dur {
			return true
		}
		vals := qs_to(sort.values[:], algo.current)
		slice.swap(vals[:], algo.less_count, algo.pivot)
		algo.pivot = algo.less_count
		algo.left = 0
		algo.right = len(vals) - 1
		return quick_sort_change_state(sort, algo, .CheckPartitionEnd)
	case .CheckPartitionEnd:
		if algo.step_time < algo.step_dur {
			return true
		}
		if algo.left < algo.pivot {
			return quick_sort_change_state(sort, algo, .PartitionLeftSide)
		} else {
			return quick_sort_change_state(sort, algo, .AddLeftRightStacks)
		}
	case .PartitionLeftSide:
		if algo.step_time < algo.step_dur {
			return true
		}
		vals := qs_to(sort.values[:], algo.current)
		if vals[algo.left].value < vals[algo.pivot].value {
			algo.left += 1
			return quick_sort_change_state(sort, algo, .CheckPartitionEnd)
		} else {
			return quick_sort_change_state(sort, algo, .PartitionRightSide)
		}
	case .PartitionRightSide:
		if algo.step_time < algo.step_dur {
			return true
		}
		vals := qs_to(sort.values[:], algo.current)
		for vals[algo.right].value > vals[algo.pivot].value {
			algo.right -= 1
		}
		return quick_sort_change_state(sort, algo, .SwapLeftRight)
	case .SwapLeftRight:
		if algo.step_time < algo.step_dur {
			return true
		}
		vals := qs_to(sort.values[:], algo.current)
		slice.swap(vals, algo.left, algo.right)
		return quick_sort_change_state(sort, algo, .CheckPartitionEnd)
	case .AddLeftRightStacks:
		if algo.step_time < algo.step_dur {
			return true
		}
		// append right
		// vals := qs_to(sort.values[:], algo.currect)
		append(
			&algo.stack,
			QuickSortSlice{start = algo.current.start + algo.pivot + 1, end = algo.current.end},
		)
		// append left
		append(
			&algo.stack,
			QuickSortSlice{start = algo.current.start, end = algo.current.start + algo.pivot},
		)
		return quick_sort_change_state(sort, algo, .CheckStackLength)
	}
	return true
}
draw_quick_sort :: proc(sort: ^Sort, algo: ^QuickSort) {
	push_rect_matrix(sort.frame)
	for s in algo.stack {
		rl.DrawRectangleRec(quick_sort_slice_rect(sort.values[:], s), {255, 255, 255, 63})
	}
	rl.DrawRectangleRec(quick_sort_slice_rect(sort.values[:], algo.current), {255, 255, 255, 63})
	if algo.state != .Initialize && algo.current.start + algo.pivot < len(sort.values) {
		rl.DrawRectangleRec(
			extend_rect(
				quick_sort_fin_rect(sort.values[:], algo.current.start + algo.pivot),
				0.008,
			),
			{0, 0, 255, 255},
		)
	}
	draw_bars(sort.values[:])
	pop_rect_matrix()
}
quick_sort_demo :: proc(values: []f32) {
	// initialize stack
	stack := make([dynamic][]f32, context.temp_allocator)
	append(&stack, values)

	// No need to animate this: check for end
	for len(stack) > 0 {
		// pop values
		vals := pop(&stack)
		count := len(vals)
		if count <= 1 {
			continue
		}
		// find pivot plave
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
quick_sort_change_state :: proc(
	sort: ^Sort,
	algo: ^QuickSort,
	state: QuickSortState,
) -> (
	is_completed: bool,
) {
	for &bar, i in sort.values {
		bar.rect.start = eval_anim(bar.rect)
		bar.rect.end = quick_sort_fin_rect(sort.values[:], i)
		bar.rect.t = 0
		bar.rect.dur = quick_sort_state_dur[state]
	}
	algo.step_time -= algo.step_dur
	algo.step_dur =  quick_sort_state_dur[state]// dur
	algo.state = state
	quick_sort_start(algo)
	quick_sort_dur(algo, algo.step_dur)
	quick_sort_t_zero(algo)
	tmp := algo.step_time < algo.step_dur
	algo.step_time -= g.input.dt * (1 + sort.speed) * (1 + g.speed)
	return tmp
}
QUICK_SORT_CURSOR_SIZE :: 0.1
QUICK_SORT_PADDING :: 0.03
QUICK_SORT_PARTITION_PADDING :: 0.00
quick_sort_fin_rect :: proc(vals: []BarValue, idx: int) -> rl.Rectangle {
	count := len(vals)
	w: f32
	gap_count := f32(count) - 1
	used_w: f32 = 1 - 2 * QUICK_SORT_PADDING - 2 * QUICK_SORT_PARTITION_PADDING
	w = used_w / (f32(count) + gap_count * BAR_GAP)
	x: f32
	x = w * f32(idx) * (1 + BAR_GAP) + QUICK_SORT_PADDING + QUICK_SORT_PARTITION_PADDING

	bar := vals[idx]
	used_h: f32 =
		(1 - 2 * QUICK_SORT_PADDING - 2 * QUICK_SORT_PARTITION_PADDING - QUICK_SORT_CURSOR_SIZE)
	h := bar.height * used_h

	return {x, used_h + QUICK_SORT_PADDING - h + QUICK_SORT_PARTITION_PADDING, w, h}
}
qs_len :: proc(slice: QuickSortSlice) -> int {
	return slice.end - slice.start
}
qs_to :: proc(values: []BarValue, slice: QuickSortSlice) -> []BarValue {
	return values[slice.start:slice.end]
}
quick_sort_slice_rect :: proc(vals: []BarValue, slice: QuickSortSlice) -> rl.Rectangle {
	count := len(vals)
	gap_count := f32(count) - 1
	used_w: f32 = 1 - 2 * QUICK_SORT_PADDING
	w := used_w / (f32(count) + gap_count * BAR_GAP)
	// w := used_w / (f32(count) + gap_count * BAR_GAP)
	// w = w * f32(qs_len(slice)) + f32(qs_len(slice) - 1)* (1 + BAR_GAP)
	x := w * f32(slice.start) * (1 + BAR_GAP) + QUICK_SORT_PADDING
	w = w * f32(qs_len(slice)) + w * f32(qs_len(slice) - 1) * BAR_GAP
	h := f32(1 - 2 * QUICK_SORT_PADDING - QUICK_SORT_CURSOR_SIZE)
	y: f32 = QUICK_SORT_PADDING
	return {x, y, w, h}
}
quick_sort_dur :: proc(algo: ^QuickSort, dur: f32) {
	for &s in algo.stack {
		s.rect.dur = dur
	}
	algo.current.rect.dur = dur
	algo.pivot_rect.dur = dur
	algo.left_cursor.dur = dur
	algo.right_cursor.dur = dur
}
quick_sort_t_zero :: proc(algo: ^QuickSort) {
	for &s in algo.stack {
		s.rect.t = 0
	}
	algo.current.rect.t = 0
	algo.pivot_rect.t = 0
	algo.left_cursor.t = 0
	algo.right_cursor.t = 0
}
quick_sort_start :: proc(algo: ^QuickSort) {
	for &s in algo.stack {
		s.rect.start = eval_anim(s.rect)
	}
	algo.current.rect.start = eval_anim(algo.current.rect)
	algo.pivot_rect.start = eval_anim(algo.pivot_rect)
	algo.left_cursor.start = eval_anim(algo.left_cursor)
	algo.right_cursor.start = eval_anim(algo.right_cursor)
}
