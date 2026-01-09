package sort

import "core:slice"
import rl "vendor:raylib"

InsersionSortState :: enum {
	Uninitialized,
	Initialize,
	Start,
	Compare,
	Swap,
	MoveCompare,
	MoveHead,
	Finish,
	Reset,
}
InsersionIndices :: struct {
	head, insert, compare: int,
}
InsersionSort :: struct {
	// head:                      Cursor,
	// prev_insert, prev_compare: HighlightedBar,
	// insert, compare:           HighlightedBar,
	// hidden:                    Window, // after head
	using idx:  InsersionIndices,
	prev:       InsersionIndices,
	state:      InsersionSortState,
	next_state: InsersionSortState,
	bar_frame:  rl.Rectangle,
}
@(rodata)
INSERTION_DURATIONS: [InsersionSortState]f32 = {
	.Uninitialized = 0,
	.Initialize    = DEFAULT_STEP_DUR,
	.Start         = DEFAULT_STEP_DUR,
	.Compare       = 0,
	.Swap          = DEFAULT_STEP_DUR,
	.MoveCompare   = DEFAULT_STEP_DUR,
	.MoveHead      = DEFAULT_STEP_DUR,
	.Finish        = DEFAULT_STEP_DUR,
	.Reset         = 0,
}
process_insertion_sort :: proc(sort: ^Sort, algo: ^InsersionSort) -> (is_completed: bool) {
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
		insertion_sort_begin_next_state(sort, algo)
		return false
	}

	defer {

	}
	for &bar, i in sort.vals {
		bar.rect.end = bar_target_rect(sort, i, algo.bar_frame)
	}
	if sort.step_time >= sort.step_dur {
		algo.prev = algo.idx
		insertion_sort_begin_next_state(sort, algo)
		return sort.step_time < sort.step_dur
	}
	advance_sort(sort)
	return true
}
draw_insertion_sort :: proc(sort: ^Sort, algo: ^InsersionSort) {
	push_rect_matrix(sort.frame)
	switch algo.state {
	case .Initialize:
		opacity := interp(0, 255, sort.step_time / sort.step_dur, DEFAULT_INTERPOLATION_TYPE)
		rl.DrawRectangleRec(
			exd(eval(sort.vals[algo.insert].rect), 0.01),
			{255, 161, 0, u8(opacity)},
		)
		rl.DrawRectangleRec(
			exd(eval(sort.vals[algo.insert].rect), 0.01),
			{230, 41, 55, u8(opacity)},
		)
		draw_moving_cursor(sort, algo.prev.head, algo.head, 0.03, 0.08, rl.RED)
		draw_bars(sort.vals[:])
		r := window_rect(sort, start = 1, end = len(sort.vals))
		rl.DrawRectangleRec(r, {0, 0, 0, u8(opacity)})
	case .Start:
		rl.DrawRectangleRec(exd(eval(sort.vals[algo.compare].rect), 0.01), rl.ORANGE)
		draw_moving_highlighter(sort, algo.prev.insert, algo.insert, 0.01, rl.RED)
		draw_moving_cursor(sort, algo.prev.head, algo.head, 0.03, 0.08, rl.RED)
		draw_bars(sort.vals[:])
		r := window_rect(sort, start = 2, end = len(sort.vals))
		rl.DrawRectangleRec(r, rl.BLACK)
	case .Compare:
	// ---
	case .Swap:
		draw_highlighter(sort, algo.compare, rl.ORANGE)
		draw_highlighter(sort, algo.insert, rl.RED)
		draw_cursor(sort, bar_target_rect(sort, algo.head, algo.bar_frame), 0.03, 0.08, rl.RED)
		draw_bars(sort.vals[:])
	case .MoveCompare:
		draw_moving_highlighter(sort, algo.prev.compare, algo.compare, 0.01, rl.ORANGE)
		rl.DrawRectangleRec(exd(eval(sort.vals[algo.insert].rect), 0.01), rl.RED)
		draw_cursor(sort, bar_target_rect(sort, algo.head, algo.bar_frame), 0.03, 0.08, rl.RED)
		draw_bars(sort.vals[:])
	case .MoveHead:
		draw_moving_highlighter(sort, algo.prev.compare, algo.compare, 0.01, rl.ORANGE)
		draw_moving_highlighter(sort, algo.prev.insert, algo.insert, 0.01, rl.RED)
		draw_moving_cursor(sort, algo.prev.head, algo.head, 0.03, 0.08, rl.RED)
		draw_bars(sort.vals[:])
	case .Finish:
		draw_highlighter(sort, algo.compare, rl.ORANGE)
		draw_highlighter(sort, algo.insert, rl.RED)
		draw_cursor(sort, bar_target_rect(sort, algo.head, algo.bar_frame), 0.03, 0.08, rl.RED)
		draw_bars(sort.vals[:])
	case .Reset:
		reset_sort(sort)
	case .Uninitialized:
		unreachable()
	case:
		unreachable()
	}

	pop_rect_matrix()
}
moving_highlighter_rect :: proc(sort: ^Sort, prev, current: int) -> rl.Rectangle {
	r := interp(
		eval(sort.vals[prev].rect),
		eval(sort.vals[current].rect),
		sort.step_time / sort.step_dur,
		DEFAULT_INTERPOLATION_TYPE,
	)
	return r
}
draw_moving_highlighter :: proc(sort: ^Sort, prev, current: int, extrude: f32, color: rl.Color) {
	r := moving_highlighter_rect(sort, prev, current)
	rl.DrawRectangleRec(exd(r, extrude), color)
}
draw_highlighter :: proc(sort: ^Sort, idx: int, color: rl.Color, extrude: f32 = 0.01) {
	rl.DrawRectangleRec(exd(eval(sort.vals[idx].rect), extrude), color)
}
draw_moving_cursor :: proc(sort: ^Sort, prev, current: int, width, height: f32, color: rl.Color) {
	tip: [2]f32
	{
		r := interp(
			eval(sort.vals[prev].rect),
			eval(sort.vals[current].rect),
			sort.step_time / sort.step_dur,
			DEFAULT_INTERPOLATION_TYPE,
		)
		tip.x = r.x + r.width / 2
		tip.y = r.y + r.height
	}
	rl.DrawTriangle(
		{tip.x, tip.y},
		{tip.x - width / 2, tip.y + height},
		{tip.x + width / 2, tip.y + height},
		color,
	)
}
draw_cursor :: proc(sort: ^Sort, rect: rl.Rectangle, width, height: f32, color: rl.Color) {
	tip := [2]f32{rect.x + rect.width / 2, rect.y + rect.height}
	rl.DrawTriangle(
		{tip.x, tip.y},
		{tip.x - width / 2, tip.y + height},
		{tip.x + width / 2, tip.y + height},
		color,
	)
}
insertion_sort_begin_next_state :: proc(sort: ^Sort, algo: ^InsersionSort) {
	algo.state = algo.next_state
	sort.step_time -= sort.step_dur
	sort.step_dur = INSERTION_DURATIONS[algo.state]

	reset_bars(sort, INSERTION_DURATIONS[algo.state])

	head := &algo.head
	insert := &algo.insert
	compare := &algo.compare
	switch algo.state {
	case .Initialize:
		algo.next_state = .Start
	case .Start:
		if len(sort.vals) == 1 {
			algo.next_state = .Finish
		} else {
			head^ = 1
			insert^ = 1
			compare^ = 0
			algo.next_state = .Compare
		}
	case .Compare:
		if sort.vals[compare^].value > sort.vals[insert^].value {
			algo.next_state = .Swap
		} else {
			if head^ == len(sort.vals) - 1 {
				algo.next_state = .Finish
			} else {
				algo.next_state = .MoveHead
			}
		}
	case .Swap:
		slice.swap(sort.vals[:], insert^, compare^)
		insert^ -= 1
		compare^ += 1
		algo.next_state = .MoveCompare
	case .MoveCompare:
		if insert^ == 0 {
			// Move compare
			if head^ == len(sort.vals) - 1 {
				algo.next_state = .Finish
			} else {
				compare^ -= 1
				algo.next_state = .MoveHead
			}
		} else {
			compare^ = insert^ - 1
			algo.next_state = .Compare
		}
	case .MoveHead:
		head^ += 1
		insert^ = head^
		compare^ = insert^ - 1
		algo.next_state = .Compare
	case .Finish:
		div := f32(len(sort.vals) - 1)
		div = div != 0 ? div : 1
		for &bar, i in sort.vals {
			bar.rect.dur = INSERTION_DURATIONS[algo.state] / 2
			bar.rect.t -= f32(i) / div
		}
		algo.next_state = .Reset
		return
	case .Reset:
		reset_sort(sort)
	case .Uninitialized:
		fallthrough
	case:
	}
}
// --- DEMO ---
insertion_sort_demo :: proc(values: []f32) {
	// Initialize
	head, insert, compare: int
	if len(values) == 0 || len(values) == 1 {
		// algorithm works without this.
		// but visuals look better with this condition.
		return
	}
	// Start
	head = 1
	insert = 1
	compare = 1
	for head < len(values) {
		// Move head
		insert = head
		compare = head - 1
		for values[compare] > values[insert] { 	// compare
			// swap
			slice.swap(values, insert, compare)
			insert -= 1
			compare += 1
			if insert == 0 {
				// Move compare
				compare -= 1
				break
			} else {
				// Move compare
				compare = insert - 1
			}
		}
		// move head
		head += 1
	}
	// finish
}
