package sort

import "core:slice"
import rl "vendor:raylib"
_ :: rl

BubbleSortState :: enum {
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
BubbleSort :: struct {
	end:             Cursor,
	window:          Window, // the sorted end of the bubble
	bubble, compare: HighlightedBar,
	state:           BubbleSortState,
	next_state:      BubbleSortState,
	bar_frame:       rl.Rectangle,
}
@(rodata)
BUBBLE_DURATIONS: [BubbleSortState]f32 = {
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
process_bubble_sort :: proc(sort: ^Sort, algo: ^BubbleSort) -> (is_completed: bool) {
	is_completed = true

	if len(sort.vals) < 1 {
		reset_sort(sort)
		return true
	}
	// initialize
	if algo.state == .Uninitialized {
		sort.step_dur = 0
		sort.step_time = 0
		algo.next_state = .Initialize
		rect := sort.vals[0].rect
		algo.bubble.rect = rect
		algo.compare.rect = rect
		algo.end.target.start = {rect.start.x + rect.start.width / 2, rect.start.y}
		algo.window.start = len(sort.vals)
		algo.window.end = len(sort.vals)
		algo.bar_frame = exd({0, 0, 1, 1}, -0.1)
		bubble_sort_begin_next_state(sort, algo)
		return false
	}

	defer {
		advance_sort(sort)
		advance_window(sort, &algo.window)
		advance_cursor(sort, &algo.end)
		advance_highlight_bar(sort, &algo.bubble)
		advance_highlight_bar(sort, &algo.compare)
	}

	// describe the animation here
	brect := sort.vals[algo.bubble.idx].rect
	crect := sort.vals[algo.compare.idx].rect
	b := &algo.bubble
	c := &algo.compare
	e := &algo.end
	win := &algo.window
	if algo.state != .Initialize {
		win.start = e.idx
	}
	go_after(&b.rect, &brect)
	go_after(&c.rect, &crect)

	#partial switch algo.state {
	case .Finish:
		for &bar, i in sort.vals {
			bar.rect.start = bar_rect(sort, i, algo.bar_frame)
			peak := bar.rect.start
			peak.y -= 0.1
			bar.rect.end = peak
			bar.rect.type = .JumpQuad
		}

		b.extend.dur = BUBBLE_DURATIONS[.Finish] * 0.3
		b.extend.end = {}

		c.extend.dur = BUBBLE_DURATIONS[.Finish] * 0.3
		c.extend.end = {}

		e.width.dur = BUBBLE_DURATIONS[.Finish] * 0.3
		e.width.end = {}
		e.width.type = .Root2
		e.height.dur = BUBBLE_DURATIONS[.Finish] * 0.3
		e.height.end = {}
		e.height.type = .Quad
		e.color.dur = BUBBLE_DURATIONS[.Finish] * 0.2
		e.color.end = {}

		algo.window.color.type = .SmoothStep3
		algo.window.color.end = {255, 255, 255, 0}
	case:
		for &bar, i in sort.vals {
			bar.rect.end = bar_rect(sort, i, algo.bar_frame)
			bar.rect.type = .SmoothStep3
		}

		b.extend.type = .SmoothStep3
		b.extend.end = [4]f32{HIGHLIGHT_EXD, HIGHLIGHT_EXD, HIGHLIGHT_EXD, HIGHLIGHT_EXD}
		b.color.type = .SmoothStep3
		algo.bubble.color.end = rl.RED

		c.extend.type = .SmoothStep3
		c.extend.end = [4]f32{HIGHLIGHT_EXD, HIGHLIGHT_EXD, HIGHLIGHT_EXD, HIGHLIGHT_EXD}
		c.color.type = .SmoothStep3
		c.color.end = rl.ORANGE

		cursor_point_at(sort, &algo.end)
		e.margin.type = .SmoothStep3
		e.margin.end = 0.02
		e.height.type = .SmoothStep3
		e.height.end = 0.07
		e.width.type = .SmoothStep3
		e.width.end = 0.05
		e.color.type = .SmoothStep3
		e.color.end = rl.RED

		algo.window.rect.end = window_rect(sort, algo.window, algo.bar_frame, true)
		algo.window.extend.type = .SmoothStep3
		algo.window.extend.end =
			[4]f32{WINDOW_EXD, WINDOW_EXD, WINDOW_EXD, WINDOW_EXD}
		algo.window.color.type = .SmoothStep3
		algo.window.color.end = {255, 255, 255, 127}
	}

	if sort.step_time >= sort.step_dur {
		bubble_sort_begin_next_state(sort, algo)
		tmp := sort.step_time < sort.step_dur
		// the step time will be updated in defer
		sort.step_time -= sort.dt * (1 + sort.speed)
		return tmp
	}
	return true
}
draw_bubble_sort :: proc(sort: ^Sort, algo: ^BubbleSort) {
	push_rect_matrix(sort.frame)
	rl.DrawRectangleRec(
		exd(eval(algo.window.rect), eval(algo.window.extend)),
		eval(algo.window.color),
	)
	rl.DrawRectangleRec(
		exd(eval(algo.compare.rect), eval(algo.compare.extend)),
		eval(algo.compare.color),
	)
	rl.DrawRectangleRec(
		exd(eval(algo.bubble.rect), eval(algo.bubble.extend)),
		eval(algo.bubble.color),
	)
	{
		w := eval(algo.end.width)
		h := eval(algo.end.height)
		pos := eval(algo.end.target)
		m := eval(algo.end.margin)
		rl.DrawTriangle(
			{pos.x, pos.y + m},
			{pos.x - w / 2, pos.y + h + m},
			{pos.x + w / 2, pos.y + h + m},
			eval(algo.end.color),
		)
	}
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
// returns the next state
bubble_sort_begin_next_state :: proc(sort: ^Sort, algo: ^BubbleSort) {
	algo.state = algo.next_state
	for &bar in sort.vals {
		bar.rect.start = eval(bar.rect)
		bar.rect.t = 0
		bar.rect.dur = BUBBLE_DURATIONS[algo.state]
	}
	sort.step_time -= sort.step_dur
	sort.step_dur = BUBBLE_DURATIONS[algo.state]

	highlight_reset(&algo.bubble, BUBBLE_DURATIONS[algo.state])
	highlight_reset(&algo.compare, BUBBLE_DURATIONS[algo.state])
	window_reset(&algo.window, BUBBLE_DURATIONS[algo.state])
	cursor_reset(&algo.end, BUBBLE_DURATIONS[algo.state])

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
		div := f32(len(sort.vals) - 1)
		div = div != 0 ? div : 1
		for &bar, i in sort.vals {
			bar.rect.dur = BUBBLE_DURATIONS[algo.state] / 2
			bar.rect.t -= f32(i) / div
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
