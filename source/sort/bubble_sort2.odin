package sort

import "core:slice"
import rl "vendor:raylib"
_ :: rl

BubbleSortState2 :: enum {
	Uninitialized,
	Initialize,
	Start,
	Compare,
	Swap,
	MoveCompare,
	MoveNext,
	EndBubble,
	Finish,
	Reset,
}
BubbleSort2 :: struct {
	end:             Cursor,
	window:          Window, // the sorted end of the bubble
	bubble, compare: HighlightedBar,
	state:           BubbleSortState2,
	next_state:      BubbleSortState2,
}
@(rodata)
BUBBLE2_DUR: [BubbleSortState2]f32 = {
	.Uninitialized = 0,
	.Initialize    = DEFAULT_STEP_DUR,
	.Start         = DEFAULT_STEP_DUR,
	.Compare       = 0, // no animation for comparing
	.Swap          = DEFAULT_STEP_DUR,
	.MoveCompare   = DEFAULT_STEP_DUR,
	.MoveNext      = DEFAULT_STEP_DUR,
	.EndBubble     = DEFAULT_STEP_DUR,
	.Finish        = DEFAULT_STEP_DUR,
	.Reset         = 0,
}
// Look at the demo to understand this
process_bubble_sort2 :: proc(sort: ^Sort, algo: ^BubbleSort2) -> (is_completed: bool) {
	is_completed = true

	if len(sort.vals) < 1 {
		reset_sort(sort)
		return true
	}
	// initialize
	if algo.state == .Uninitialized {
		bubble2_sort_change_state(sort, algo, .Start)
		return false
	}

	defer {
		advance_sort(sort)
		advance_cursor(sort, &algo.end)
		advance_highlight_bar(sort, &algo.bubble)
		advance_highlight_bar(sort, &algo.compare)
	}

	// describe the animation here
	highlight(sort, &algo.bubble)
	highlight(sort, &algo.compare)
	cursor(sort, &algo.end)

	if sort.step_time >= sort.step_dur {
		bubble_sort_begin_next_state(sort, algo)
	}
	return true
}
draw_bubble_sort2 :: proc(sort: ^Sort, algo: ^BubbleSort2) {
	push_rect_matrix(sort.frame)
	draw_bars(sort.vals[:])
	pop_rect_matrix()
}
// This looks weird because it emulates the animation.
// begin is executed, then waits for end
bubble_sort_demo :: proc(values: []f32) {
	// begin initialization
	end: int
	current: int
	compare: int
	// end initialization
	// begin start
	if len(values) == 0 || len(values) == 1 {
		// algorithm works without this.
		// but visuals look better with this condition.
		return
	}
	current = 0
	compare = 1
	end = len(values) - 1
	// end start
	for end > 1 {
		for {
			// begin compare
			if values[current] > values[compare] {
				// end compare
				// begin swap
				slice.swap(values, current, compare)
				current += 1
				compare -= 1
				// end swap
				// begin move compare
				if current < end {
					compare = current + 1
					// end move compare
					continue
				} else {
					compare = current
					// end move compare
					break
				}
			} else {
				// end compare
				// begin move next
				current += 1
				if current < end {
					compare = current + 1
					// end move next
					continue
				}
				// end move next
				break
			}

		}
		// begin bubbling finished
		end -= 1
		current = 0
		compare = 1
		// end bubbling finished
	}
	// begin finish
	// make all accessories transparent.
	// end finish
	// DONE
}
bubble2_sort_change_state :: proc(
	sort: ^Sort,
	algo: ^BubbleSort2,
	state: BubbleSortState2,
) -> (
	is_completed: bool,
) {
	for &bar, i in sort.vals {
		bar.rect.start = eval(bar.rect)
		bar.rect.end = bubble_sort_fin_rect(sort.vals[:], i)
		bar.rect.t = 0
		bar.rect.dur = BUBBLE2_DUR[state]
	}
	sort.step_time -= sort.step_dur
	sort.step_dur = BUBBLE2_DUR[state] // dur
	algo.state = state
	// bubble_sort_start(algo)
	// bubble_sort_dur(algo, algo.step_dur, algo.step_dur, algo.step_dur, algo.step_dur)
	// bubble_sort_t(algo, 0, 0, 0, 0)
	tmp := sort.step_time < sort.step_dur
	sort.step_time -= sort.dt * (1 + sort.speed)
	return tmp
}
// returns the next state
bubble_sort_begin_next_state :: proc(sort: ^Sort, algo: ^BubbleSort2) {
	algo.state = algo.next_state
	for &bar in sort.vals {
		bar.rect.start = eval(bar.rect)
		bar.rect.t = 0
		bar.rect.dur = BUBBLE2_DUR[algo.state]
	}
	highlight_reset(&algo.bubble, BUBBLE2_DUR[algo.state])
	highlight_reset(&algo.compare, BUBBLE2_DUR[algo.state])
	cursor_reset(&algo.end, BUBBLE2_DUR[algo.state])

	curr := &algo.bubble.idx
	comp := &algo.compare.idx
	end := &algo.end.idx
	switch algo.state {
	case .Initialize:
	// set transparecy
	case .Start:
		if len(sort.vals) == 1 {
			algo.next_state = .Finish
			return
		}
		curr^ = 0
		comp^ = 1
		end^ = len(sort.vals) - 1
		algo.next_state = .Compare
		return
	case .Compare:
		if sort.vals[curr^].value > sort.vals[comp^].value {
			algo.next_state = .Swap
			return
		}
		algo.next_state = .MoveNext
		return
	case .Swap:
		slice.swap(sort.vals[:], curr^, comp^)
		curr^ += 1
		comp^ -= 1
		algo.next_state = .MoveCompare
		return
	case .MoveCompare:
		if curr^ < end^ {
			comp^ = curr^ + 1
			algo.next_state = .Compare
			return
		}
		comp^ = curr^
		algo.next_state = .EndBubble
		return
	case .MoveNext:
		if algo.bubble.idx < algo.end.idx {
			algo.next_state = .Compare
			return
		}
		algo.next_state = .EndBubble
		return
	case .EndBubble:
		if algo.end.idx > 1 {
			algo.next_state = .Compare
			return
		}
		algo.next_state = .Finish
		return
	case .Finish:
		algo.next_state = .Reset
		return
	case .Uninitialized:
		fallthrough
	case .Reset:
		fallthrough
	case:
		unreachable()
	}
}
