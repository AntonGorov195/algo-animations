package game

import "core:log"
_ :: log
import "core:slice"
import rl "vendor:raylib"

QuickSortDur: [QuickSortState]f32 = {
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
	start, end: int, // [start, end)
}
QuickSort :: struct {
	stack:        [dynamic]QuickSortSlice,
	currect:      QuickSortSlice,
	pivot:        int,
	pivot_rect:   Animated(rl.Rectangle),
	less_count:   int,
	left:         int,
	left_cursor:  Animated(f32),
	right:        int,
	right_cursor: Animated(f32),
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
	}
	for &bar, i in sort.values {
		bar.rect.end = quick_sort_fin_rect(sort.values[:], i)
	}
	// log.info(algo.state)
	switch algo.state {
	case .Initialize:
		append(&algo.stack, QuickSortSlice{start = 0, end = len(sort.values)})
		return quick_sort_change_state(sort, algo, .CheckStackLength, 0)
	case .CheckStackLength:
		if len(algo.stack) == 0 {
			delete(algo.stack) // may not be necessary depending on the allocator
			reset_sort(sort)
		} else {
			return quick_sort_change_state(sort, algo, .PopStack, 0)
		}
	case .PopStack:
		algo.currect = pop(&algo.stack)
		if algo.currect.start >= algo.currect.end - 1 {
			return quick_sort_change_state(sort, algo, .CheckStackLength, 0)
		} else {
			return quick_sort_change_state(sort, algo, .ChoosePivot, 0)
		}
	case .ChoosePivot:
		algo.pivot = qs_len(algo.currect) / 2
		return quick_sort_change_state(sort, algo, .CountLess, 0)
	case .CountLess:
		algo.less_count = 0
		vals := qs_to(sort.values[:], algo.currect)
		p := vals[algo.pivot]
		for value in vals {
			if value.value < p.value {
				algo.less_count += 1
			}
		}
		return quick_sort_change_state(sort, algo, .SwapPivot, 0)
	case .SwapPivot:
		vals := qs_to(sort.values[:], algo.currect)
		slice.swap(vals[:], algo.less_count, algo.pivot)
		algo.pivot = algo.less_count
		algo.left = 0
		algo.right = len(vals) - 1
		return quick_sort_change_state(sort, algo, .CheckPartitionEnd, 0)
	case .CheckPartitionEnd:
		if algo.left < algo.pivot {
			return quick_sort_change_state(sort, algo, .PartitionLeftSide, 0)
		} else {
			return quick_sort_change_state(sort, algo, .AddLeftRightStacks, 0)
		}
	case .PartitionLeftSide:
		vals := qs_to(sort.values[:], algo.currect)
		if vals[algo.left].value < vals[algo.pivot].value {
			algo.left += 1
			return quick_sort_change_state(sort, algo, .CheckPartitionEnd, 0)
		} else {
			return quick_sort_change_state(sort, algo, .PartitionRightSide, 0)
		}
	case .PartitionRightSide:
		vals := qs_to(sort.values[:], algo.currect)
		for vals[algo.right].value > vals[algo.pivot].value {
			algo.right -= 1
		}
		return quick_sort_change_state(sort, algo, .SwapLeftRight, 0)
	case .SwapLeftRight:
		vals := qs_to(sort.values[:], algo.currect)
		slice.swap(vals, algo.left, algo.right)
		return quick_sort_change_state(sort, algo, .CheckPartitionEnd, 0)
	case .AddLeftRightStacks:
		// append right
		// vals := qs_to(sort.values[:], algo.currect)
		append(
			&algo.stack,
			QuickSortSlice{start = algo.currect.start + algo.pivot + 1, end = algo.currect.end},
		)
		// append left
		append(
			&algo.stack,
			QuickSortSlice{start = algo.currect.start, end = algo.currect.start + algo.pivot},
		)
		return quick_sort_change_state(sort, algo, .CheckStackLength, 0)
	}
	return true
}
draw_quick_sort :: proc(sort: ^Sort, algo: ^QuickSort) {
	push_rect_matrix(sort.frame)
	for s in algo.stack {
		_ = s
		// r := quick_sort_fin_rect({BarValue{height = 1}}, 0)
		// rl.DrawRectangleRec(rl.Rect)
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
	dur: f32,
) -> (
	is_completed: bool,
) {
	for &bar, i in sort.values {
		bar.rect.start = eval_anim(bar.rect)
		bar.rect.end = quick_sort_fin_rect(sort.values[:], i)
		bar.rect.t = 0
		bar.rect.dur = dur
	}
	algo.step_time -= algo.step_dur
	algo.step_dur = QuickSortDur[state] // dur
	algo.state = state
	// quick_sort_start(algo)
	// quick_sort_dur(algo, algo.step_dur, algo.step_dur, algo.step_dur, algo.step_dur)
	// quick_sort_t(algo, 0, 0, 0, 0)
	tmp := algo.step_time < algo.step_dur
	algo.step_time -= g.input.dt * (1 + sort.speed) * (1 + g.speed)
	return tmp
}
QUICK_SORT_CURSOR_SIZE :: 0.1
QUICK_SORT_PADDING :: 0.03
quick_sort_fin_rect :: proc(vals: []BarValue, idx: int) -> rl.Rectangle {
	count := len(vals)
	w: f32
	gap_count := f32(count) - 1
	used_w: f32 = 1 - 2 * QUICK_SORT_PADDING
	w = used_w / (f32(count) + gap_count * BAR_GAP)
	x: f32
	x = w * f32(idx) * (1 + BAR_GAP) + QUICK_SORT_PADDING

	bar := vals[idx]
	used_h: f32 = (1 - 2 * QUICK_SORT_PADDING - QUICK_SORT_CURSOR_SIZE)
	h := bar.height * used_h

	return {x, used_h + QUICK_SORT_PADDING - h, w, h}
}
qs_len :: proc(slice: QuickSortSlice) -> int {
	return slice.end - slice.start
}
qs_to :: proc(values: []BarValue, slice: QuickSortSlice) -> []BarValue {
	return values[slice.start:slice.end]
}
// quick_sort_slice_rect :: proc(vals: []BarValue, slice: QuickSortSlice) -> rl.Rectangle {
// 	quick_sort_fin_rect()
// }
// quick_animate_step :: proc(sort: ^Sort, algo: ^QuickSort, head, insert, compare: int) {
// 	head_rect := insert_sort_fin_rect(sort.values[:], head)
// 	insert_rect := insert_sort_fin_rect(sort.values[:], insert)
// 	compare_rect := insert_sort_fin_rect(sort.values[:], compare)
// 	insertion_sort_target(
// 		algo,
// 		1,
// 		head_rect.x + head_rect.width / 2,
// 		extend_rect(insert_rect, 0.01),
// 		extend_rect(compare_rect, 0.01),
// 	)
// }
// quick_sort_target :: proc(
// 	algo: ^QuickSort,
// 	assist_opacity: f32,
// 	head_cursor: f32,
// 	insert_rect: rl.Rectangle,
// 	compare_rect: rl.Rectangle,
// ) {
// 	algo.assist_opacity.end = assist_opacity
// 	algo.head_cursor.end = head_cursor
// 	algo.insert_rect.end = insert_rect
// 	algo.compare_rect.end = compare_rect
// }
// quick_sort_dur :: proc(
// 	algo: ^QuickSort,
// 	assist_opacity: f32,
// 	head_cursor: f32,
// 	insert_rect: f32,
// 	compare_rect: f32,
// ) {
// 	algo.assist_opacity.dur = assist_opacity
// 	algo.head_cursor.dur = head_cursor
// 	algo.insert_rect.dur = insert_rect
// 	algo.compare_rect.dur = compare_rect
// }
// quick_sort_t :: proc(
// 	algo: ^QuickSort,
// 	assist_opacity: f32,
// 	head_cursor: f32,
// 	insert_rect: f32,
// 	compare_rect: f32,
// ) {
// 	algo.assist_opacity.t = assist_opacity
// 	algo.head_cursor.t = head_cursor
// 	algo.insert_rect.t = insert_rect
// 	algo.compare_rect.t = compare_rect
// }
// quick_sort_start :: proc(algo: ^QuickSort) {
// 	algo.assist_opacity.start = eval_anim(algo.assist_opacity)
// 	algo.head_cursor.start = eval_anim(algo.head_cursor)
// 	algo.insert_rect.start = eval_anim(algo.insert_rect)
// 	algo.compare_rect.start = eval_anim(algo.compare_rect)
// }