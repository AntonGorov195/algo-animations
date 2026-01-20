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
	.Finish        = DEFAULT_STEP_DUR * 8,
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
		algo.bar_frame = exd({0, 0, 1, 1}, -0.1)
		bubble_sort_begin_next_state(sort, algo)
		rect := sort.vals[0].rect
		algo.bubble.rect = rect
		algo.compare.rect = rect
		algo.end.target.start = {rect.start.x + rect.start.width / 2, rect.start.y}
		algo.window.start = len(sort.vals)
		algo.window.end = len(sort.vals)
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
		win.start = e.idx + 1
	}
	// 	win.rect.start = exd(r, -r.height / 2, -r.width / 2, -r.height / 2, -r.width / 2)
	go_after(&b.rect, &brect)
	go_after(&c.rect, &crect)

	#partial switch algo.state {
	case .Finish:
		for &bar, i in sort.vals {
			bar.rect.start = bar_target_rect(sort, i, algo.bar_frame)
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

		algo.window.start = 0
		algo.window.rect.end = window_target_rect(sort, algo.window, algo.bar_frame, true)
		algo.window.rect.dur = BUBBLE_DURATIONS[.Finish]  * 0.1
		algo.window.extend.type = DEFAULT_INTERPOLATION_TYPE
		algo.window.extend.end = [4]f32{WINDOW_EXD, WINDOW_EXD, WINDOW_EXD, WINDOW_EXD}
		algo.window.color.type = DEFAULT_INTERPOLATION_TYPE
		algo.window.color.dur = BUBBLE_DURATIONS[.Finish] 
		algo.window.color.end = {255, 255, 255, 0}
	case:
		for &bar, i in sort.vals {
			bar.rect.end = bar_target_rect(sort, i, algo.bar_frame)
			bar.rect.type = DEFAULT_INTERPOLATION_TYPE
		}

		b.extend.type = DEFAULT_INTERPOLATION_TYPE
		b.extend.end = [4]f32{HIGHLIGHT_EXD, HIGHLIGHT_EXD, HIGHLIGHT_EXD, HIGHLIGHT_EXD}
		b.color.type = DEFAULT_INTERPOLATION_TYPE
		algo.bubble.color.end = rl.RED

		c.extend.type = DEFAULT_INTERPOLATION_TYPE
		c.extend.end = [4]f32{HIGHLIGHT_EXD, HIGHLIGHT_EXD, HIGHLIGHT_EXD, HIGHLIGHT_EXD}
		c.color.type = DEFAULT_INTERPOLATION_TYPE
		c.color.end = rl.ORANGE

		cursor_point_at(sort, &algo.end)
		e.margin.type = DEFAULT_INTERPOLATION_TYPE
		e.margin.end = 0.02
		e.height.type = DEFAULT_INTERPOLATION_TYPE
		e.height.end = 0.07
		e.width.type = DEFAULT_INTERPOLATION_TYPE
		e.width.end = 0.05
		e.color.type = DEFAULT_INTERPOLATION_TYPE
		e.color.end = rl.RED

		if window_len(algo.window) == 0 {
			r := bar_target_rect(sort, win.end - 1, algo.bar_frame)
			algo.window.rect = sort.vals[win.end - 1].rect
			algo.window.rect.end = r
			algo.window.extend.type = DEFAULT_INTERPOLATION_TYPE
			algo.window.extend.end = [4]f32{}
		} else {
			algo.window.rect.end = window_target_rect(sort, algo.window, algo.bar_frame, true)
			algo.window.extend.type = DEFAULT_INTERPOLATION_TYPE
			algo.window.extend.end = [4]f32{WINDOW_EXD, WINDOW_EXD, WINDOW_EXD, WINDOW_EXD}
		}
		algo.window.color.type = DEFAULT_INTERPOLATION_TYPE
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
	draw_bars(sort, sort.vals[:])
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
	sort.step_time -= sort.step_dur
	sort.step_dur = BUBBLE_DURATIONS[algo.state]

	reset_bars(sort, BUBBLE_DURATIONS[algo.state])
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
reset_bars :: proc(sort: ^Sort, dur: f32) {
	for &bar in sort.vals {
		bar.rect.start = eval(bar.rect)
		bar.rect.t = 0
		bar.rect.dur = dur
	}
}
rect_end_pos_x :: proc(count: int, index: int) -> f32 {
	w := calc_bar_width(count)
	return w * f32(index) * (1 + BAR_GAP)
}
draw_sort_cursor :: proc(bound: rl.Rectangle, color: rl.Color) {
	rl.DrawTriangle(
		{bound.x + bound.width / 2, bound.y},
		{bound.x, bound.y + bound.height},
		{bound.x + bound.width, bound.y + bound.height},
		color,
	)
}
calc_bar_width :: proc(count: int, gap: f32 = BAR_GAP) -> f32 {
	gap_count := f32(count) - 1
	return 1 / (f32(count) + gap_count * BAR_GAP)
}
advance_highlight_bar :: proc(sort: ^Sort, highlight: ^HighlightedBar) {
	dt := sort.dt * (1 + sort.speed)
	highlight.rect.t += dt / highlight.rect.dur
	highlight.extend.t += dt / highlight.extend.dur
	highlight.color.t += dt / highlight.color.dur
}
advance_cursor :: proc(sort: ^Sort, cursor: ^Cursor) {
	dt := sort.dt * (1 + sort.speed)
	cursor.margin.t += dt / cursor.margin.dur
	cursor.color.t += dt / cursor.color.dur
	cursor.target.t += dt / cursor.target.dur
	cursor.width.t += dt / cursor.width.dur
	cursor.height.t += dt / cursor.height.dur
}
advance_window :: proc(sort: ^Sort, window: ^Window) {
	dt := sort.dt * (1 + sort.speed)
	window.rect.t += dt / window.rect.dur
	window.extend.t += dt / window.extend.dur
	window.color.t += dt / window.color.dur
}

cursor_point_at :: proc(sort: ^Sort, cursor: ^Cursor) {
	target := sort.vals[cursor.idx].rect
	cursor.target.end.x = target.end.x + target.end.width / 2
	cursor.target.end.y = target.end.y + target.end.height
	cursor.target.t = target.t
	cursor.target.dur = target.dur
	cursor.target.type = target.type
}
highlight_with_color :: proc(sort: ^Sort, highlight: ^HighlightedBar, color: rl.Color) {
	target := sort.vals[highlight.idx].rect
	highlight.rect.end = target.end
	highlight.rect.t = target.t
	highlight.rect.dur = target.dur
	highlight.rect.type = target.type

	highlight.color.end = color
}
highlight_bar :: proc(sort: ^Sort, highlight: ^HighlightedBar) {
	highlight_with_color(sort, highlight, highlight.color.end)
}
highlight :: proc {
	highlight_bar,
	highlight_with_color,
}
highlight_reset :: proc(h: ^HighlightedBar, dur: f32) {
	h.color.start = eval(h.color)
	h.extend.start = eval(h.extend)
	h.rect.start = eval(h.rect)

	h.color.t = 0
	h.extend.t = 0
	h.rect.t = 0

	h.color.dur = dur
	h.extend.dur = dur
	h.rect.dur = dur
}
cursor_reset :: proc(c: ^Cursor, dur: f32) {
	c.margin.start = eval(c.margin)
	c.color.start = eval(c.color)
	c.target.start = eval(c.target)
	c.width.start = eval(c.width)
	c.height.start = eval(c.height)

	c.margin.t = 0
	c.color.t = 0
	c.target.t = 0
	c.width.t = 0
	c.height.t = 0

	c.margin.dur = dur
	c.color.dur = dur
	c.target.dur = dur
	c.width.dur = dur
	c.height.dur = dur
}
window_reset :: proc(window: ^Window, dur: f32) {
	window.extend.start = eval(window.extend)
	window.rect.start = eval(window.rect)
	window.color.start = eval(window.color)

	window.extend.t = 0
	window.rect.t = 0
	window.color.t = 0

	window.extend.dur = dur
	window.rect.dur = dur
	window.color.dur = dur
}