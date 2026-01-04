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
	bar_frame:       rl.Rectangle,
}
@(rodata)
BUBBLE2_DUR: [BubbleSortState2]f32 = {
	.Uninitialized = 0,
	.Initialize    = DEFAULT_STEP_DUR * 5,
	.Start         = DEFAULT_STEP_DUR * 3,
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
		{
			// Start the bubble highlight
			// I want it to start with the same rect as bar
			b := &algo.bubble
			b.rect.type = sort.vals[0].rect.type
			b.rect.t = sort.vals[0].rect.t
			b.rect.dur = sort.vals[0].rect.dur
			b.rect.start = sort.vals[0].rect.start
			b.rect.end = sort.vals[0].rect.end

			b.extend.type = .SmoothStep3
			b.extend.t = 0
			b.extend.dur = BUBBLE2_DUR[algo.state]
			b.extend.start = {}
			b.extend.end = [4]f32{HIGHLIGHT_EXD, HIGHLIGHT_EXD, HIGHLIGHT_EXD, HIGHLIGHT_EXD}

			b.color.type = .SmoothStep3
			b.color.t = 0
			b.color.dur = BUBBLE2_DUR[algo.state]
			b.color.start = {}
			b.color.end = rl.RED
		}
		{

			c := &algo.compare
			c.rect.type = sort.vals[0].rect.type
			c.rect.t = sort.vals[0].rect.t
			c.rect.dur = sort.vals[0].rect.dur
			c.rect.start = sort.vals[0].rect.start
			c.rect.end = sort.vals[0].rect.end

			c.extend.type = .SmoothStep3
			c.extend.t = 0
			c.extend.dur = BUBBLE2_DUR[algo.state]
			c.extend.start = {}
			c.extend.end = [4]f32{HIGHLIGHT_EXD, HIGHLIGHT_EXD, HIGHLIGHT_EXD, HIGHLIGHT_EXD}

			c.color.type = .SmoothStep3
			c.color.t = 0
			c.color.dur = BUBBLE2_DUR[algo.state]
			c.color.start = {}
			c.color.end = rl.ORANGE
		}
		{
			e := &algo.end
			rect := sort.vals[0].rect
			e.target.type = rect.type
			e.target.t = rect.t
			e.target.dur = rect.dur
			e.target.start = {rect.start.x + rect.start.width / 2, rect.start.y}
			e.target.end = {rect.end.x + rect.end.width / 2, rect.end.y}

			e.margin.type = .SmoothStep3
			e.margin.t = 0
			e.margin.dur = BUBBLE2_DUR[algo.state]
			e.margin.start = 0
			e.margin.end = 0.5

			e.height = to_anim(f32(0.07))
			e.width = to_anim(f32(0.05))
			e.width.type = .SmoothStep3
			e.color = to_anim(rl.RED)
		}
		algo.bar_frame = exd({0, 0, 1, 1}, -0.1)
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
			bar.rect.start = bar_rect(sort, i, algo.bar_frame)
			peak := bar.rect.start
			peak.y -= 0.2
			bar.rect.end = peak
			bar.rect.type = .JumpQuad
		} else {
			bar.rect.end = bar_rect(sort, i, algo.bar_frame)
			bar.rect.type = .SmoothStep3
		}
	}
	if algo.state == .Finish {
		algo.bubble.extend.type = .Cubic
		algo.bubble.extend.t = 0
		algo.bubble.extend.dur = BUBBLE2_DUR[.Finish]
		algo.bubble.extend.start = algo.bubble.extend.start
		algo.bubble.extend.end = {}

		algo.compare.extend.type = .Cubic
		algo.compare.extend.t = 0
		algo.compare.extend.dur = BUBBLE2_DUR[.Finish]
		algo.compare.extend.start = algo.compare.extend.start
		algo.compare.extend.end = {}

		algo.end.width.dur = BUBBLE2_DUR[.Finish]
		algo.end.width.end = {}
		algo.end.width.type = .Cubic
	}

	{
		target := sort.vals[algo.bubble.idx].rect
		b := &algo.bubble
		// go after target
		go_after(&b.rect, &target)

		// do nothing
		b.extend.type = b.extend.type
		b.extend.t = b.extend.t
		b.extend.dur = b.extend.dur
		b.extend.start = b.extend.start
		b.extend.end = b.extend.end

		// do nothing
		b.color.type = b.color.type
		b.color.t = b.color.t
		b.color.dur = b.color.dur
		b.color.start = b.color.start
		b.color.end = b.color.end
	}

	{

		// target := sort.vals[algo.compare.idx].rect
		// c := &algo.compare
		// c.rect.type = target.type
		// c.rect.t = target.t
		// c.rect.dur = target.dur
		// c.rect.start = c.rect.start
		// c.rect.end = target.end
	}
	// highlight(sort, &algo.bubble)
	// highlight(sort, &algo.compare)
	// cursor(sort, &algo.end)

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
		div := f32(len(sort.vals) - 1)
		div = div != 0 ? div : 1
		for &bar, i in sort.vals {
			bar.rect.dur = BUBBLE2_DUR[algo.state] / 2
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
// mimick timing.
//
