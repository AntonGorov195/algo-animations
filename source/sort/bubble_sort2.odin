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
	.Finish        = DEFAULT_STEP_DUR * 10,
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
		algo.next_state = .Initialize

		algo.bubble.rect = sort.vals[0].rect
		algo.bubble.extend.type = .SmoothStep3
		algo.bubble.extend = to_anim([4]f32{0.01, 0.01, 0.01, 0.01})
		algo.bubble.color.type = .SmoothStep3
		algo.bubble.color = to_anim(rl.RED)

		algo.compare.rect = sort.vals[0].rect
		algo.compare.extend.type = .SmoothStep3
		algo.compare.extend = to_anim([4]f32{0.01, 0.01, 0.01, 0.01})
		algo.compare.color.type = .SmoothStep3
		algo.compare.color = to_anim(rl.ORANGE)

		bubble_sort_begin_next_state(sort, algo)
		return false
	}

	defer {
		advance_sort(sort)
		advance_cursor(sort, &algo.end)
		advance_highlight_bar(sort, &algo.bubble)
		advance_highlight_bar(sort, &algo.compare)
	}

	// describe the animation here
	for &bar, i in sort.vals {
		if algo.state == .Finish {
			bar.rect.start = bar_rect(sort, i, {0.25, 0.25, 0.5, 0.5})
			peak := bar.rect.start
			peak.y -= 0.25
			bar.rect.end = peak
			bar.rect.type = .JumpQuad
		} else {
			bar.rect.end = bar_rect(sort, i, {0.25, 0.25, 0.5, 0.5})
			bar.rect.type = .SmoothStep3
		}
	}
	highlight(sort, &algo.bubble)
	highlight(sort, &algo.compare)
	cursor(sort, &algo.end)

	if sort.step_time >= sort.step_dur {
		bubble_sort_begin_next_state(sort, algo)
		tmp := sort.step_time < sort.step_dur
		// the step time will be updated in defer
		sort.step_time -= sort.dt * (1 + sort.speed)
		return tmp
	}
	return true
}
draw_bubble_sort2 :: proc(sort: ^Sort, algo: ^BubbleSort2) {
	push_rect_matrix(sort.frame)
	rl.DrawRectangleRec(
		exd(eval(algo.compare.rect), eval(algo.compare.extend)),
		eval(algo.compare.color),
	)
	rl.DrawRectangleRec(
		exd(eval(algo.bubble.rect), eval(algo.bubble.extend)),
		eval(algo.bubble.color),
	)
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
	sort.step_time -= sort.step_dur
	sort.step_dur = BUBBLE2_DUR[algo.state]

	highlight_reset(&algo.bubble, BUBBLE2_DUR[algo.state])
	highlight_reset(&algo.compare, BUBBLE2_DUR[algo.state])
	cursor_reset(&algo.end, BUBBLE2_DUR[algo.state])

	curr := &algo.bubble.idx
	comp := &algo.compare.idx
	end := &algo.end.idx
	switch algo.state {
	case .Initialize:
		// set transparecy
		algo.next_state = .Start
		return
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
		curr^ += 1
		if algo.bubble.idx < algo.end.idx {
			comp^ = curr^ + 1
			algo.next_state = .Compare
			return
		}
		algo.next_state = .EndBubble
		return
	case .EndBubble:
		end^ -= 1
		curr^ = 0
		comp^ = 1
		if algo.end.idx > 0 {
			algo.next_state = .Compare
			return
		}
		comp^ = 0
		algo.next_state = .Finish
		return
	case .Finish:
		for &bar, i in sort.vals {
			bar.rect.dur = BUBBLE2_DUR[algo.state] / 2
			bar.rect.t -= f32(i) / f32(len(sort.vals))
		}
		algo.next_state = .Reset
		return
	case .Reset:
		reset_sort(sort)
	case .Uninitialized:
		fallthrough
	case:
		unreachable()
	}
}
