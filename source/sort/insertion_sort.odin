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
	.Finish        = DEFAULT_STEP_DUR * 3,
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
	// highlight rect
	hr :: proc(rect: rl.Rectangle, color: rl.Color, extend: f32 = HIGHLIGHT_EXD) {
		rl.DrawRectangleRec(exd(rect, extend), color)
	}
	csr :: proc(
		tip: [2]f32,
		width: f32 = CUSOR_WIDTH,
		height: f32 = CUSOR_HEIGHT,
		color: rl.Color = CURSOR_COLOR,
	) {
		draw_cursor_tip(tip, width, height, color)
	}

	t := sort.step_time / sort.step_dur
	push_rect_matrix(sort.frame)
	switch algo.state {
	case .Initialize:
		compare_color := COMPARE_COLOR
		compare_color.a = u8(interp(f32(0), f32(compare_color.a), t))
		hr(htra(sort, algo.compare), compare_color)
		insert_color := SELECTED_COLOR
		insert_color.a = u8(interp(f32(0), f32(insert_color.a), t))
		hr(htra(sort, algo.insert), insert_color)
		cursor_color := CURSOR_COLOR
		cursor_color.a = u8(interp(f32(0), f32(cursor_color.a), t))
		csr(tiptra(sort, algo.head), color = cursor_color)
		draw_bars(sort.vals[:])
	case .Start:
		hr(htra(sort, algo.compare), COMPARE_COLOR)
		hr(htrai(sort, algo.prev.insert, algo.insert, t), SELECTED_COLOR)
		csr(tiptrai(sort, algo.prev.head, algo.head, t))
		draw_bars(sort.vals[:])
	case .Compare:
	// ---
	case .Swap:
		hr(htra(sort, algo.compare), COMPARE_COLOR)
		hr(htra(sort, algo.insert), SELECTED_COLOR)
		csr(tiptar(sort, algo.head, algo.bar_frame))
		draw_bars(sort.vals[:])
	case .MoveCompare:
		hr(htrai(sort, algo.prev.compare, algo.compare, t), COMPARE_COLOR)
		hr(htra(sort, algo.insert), SELECTED_COLOR)
		csr(tiptar(sort, algo.head, algo.bar_frame))
		draw_bars(sort.vals[:])
	case .MoveHead:
		hr(htrai(sort, algo.prev.compare, algo.compare, t), COMPARE_COLOR)
		hr(htrai(sort, algo.prev.insert, algo.insert, t), SELECTED_COLOR)
		csr(tiptari(sort, algo.prev.head, algo.head, algo.bar_frame, t))
		draw_bars(sort.vals[:])
	case .Finish:
		compare_color := COMPARE_COLOR
		compare_color.a = u8(interp(f32(compare_color.a), f32(0), 3 * t))
		hr(htra(sort, algo.compare), compare_color)
		insert_color := SELECTED_COLOR
		insert_color.a = u8(interp(f32(insert_color.a), f32(0), 3 * t))
		hr(htra(sort, algo.insert), insert_color)
		cursor_color := CURSOR_COLOR
		cursor_color.a = u8(interp(f32(cursor_color.a), f32(0), 3 * t))
		csr(tiptra(sort, algo.head), color = cursor_color)
		for bar, i in sort.vals {
			t := t
			t *= 2
			t -= f32(i) / f32(len(sort.vals))
			t = min(1, max(0, t))
			rect := eval(bar.rect)
			rect = exd(rect, -0.25 * rect.width * (-4 * t * (t - 1)))
			rl.DrawRectangleRec(rect, bar.real_place == i ? rl.GREEN : rl.BLACK)
		}
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
draw_cursor_tip :: proc(tip: [2]f32, width, height: f32, color: rl.Color) {
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
