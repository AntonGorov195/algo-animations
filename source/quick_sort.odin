package game

import "core:slice"
import rl "vendor:raylib"

QuickSortState :: enum {
	Initialize,
	CheckStackLength,
	PopStack,
	ChoosePivot,
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
	stack:      [dynamic]QuickSortSlice,
	currect:    QuickSortSlice,
	pivot:      int,
	less_count: int,
	left:       int,
	right:      int,
	state:      QuickSortState,
	step_time:  f32,
	step_dur:   f32,
	// partition_left_cursor:  Animated(f32),
	// partition_right_cursor: Animated(f32),
	// pivot_rect:             Animated(rl.Rectangle),
}

process_quick_sort :: proc(sort: ^Sort, algo: ^QuickSort) -> (is_completed: bool) {
	is_completed = true
	defer {
		algo.step_time += g.input.dt * (1 + sort.speed) * (1 + g.speed)
		for &bar in sort.values {
			advance_sort(sort, &bar.rect)
		}
	}
	return
}
draw_quick_sort :: proc(sort: ^Sort, algo: ^QuickSort) {

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
			for vals[left_i] < pivot {
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
