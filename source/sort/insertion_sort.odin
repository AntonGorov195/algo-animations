package sort

import "core:slice"
import rl "vendor:raylib"

InsersionSortState :: enum {
	Initialization,
	MoveHead,
	Swap,
	Compare,
	MoveNext,
}
InsersionSort :: struct {
	assist_opacity:            Animated(f32),
	head_cursor:               Animated(f32),
	insert_rect, compare_rect: Animated(rl.Rectangle),
	head, insert, compare:     int,
	state:                     InsersionSortState,
	step_time:                 f32,
	step_dur:                  f32,
}

INSERTION_SORT_CURSOR_SIZE :: 0.1
insert_sort_fin_rect :: proc(vals: []BarValue, idx: int) -> rl.Rectangle {
	PADDING :: 0.03
	count := len(vals)
	w: f32
	gap_count := f32(count) - 1
	used_w: f32 = 1 - 2 * PADDING
	w = used_w / (f32(count) + gap_count * BAR_GAP)
	x: f32
	x = w * f32(idx) * (1 + BAR_GAP) + PADDING

	bar := vals[idx]
	used_h: f32 = (1 - 2 * PADDING - INSERTION_SORT_CURSOR_SIZE)
	h := bar.height * used_h

	return {x, used_h + PADDING - h, w, h}
}
insertion_sort_target :: proc(
	algo: ^InsersionSort,
	assist_opacity: f32,
	head_cursor: f32,
	insert_rect: rl.Rectangle,
	compare_rect: rl.Rectangle,
) {
	algo.assist_opacity.end = assist_opacity
	algo.head_cursor.end = head_cursor
	algo.insert_rect.end = insert_rect
	algo.compare_rect.end = compare_rect
}
insertion_sort_dur :: proc(
	algo: ^InsersionSort,
	assist_opacity: f32,
	head_cursor: f32,
	insert_rect: f32,
	compare_rect: f32,
) {
	algo.assist_opacity.dur = assist_opacity
	algo.head_cursor.dur = head_cursor
	algo.insert_rect.dur = insert_rect
	algo.compare_rect.dur = compare_rect
}
insertion_sort_t :: proc(
	algo: ^InsersionSort,
	assist_opacity: f32,
	head_cursor: f32,
	insert_rect: f32,
	compare_rect: f32,
) {
	algo.assist_opacity.t = assist_opacity
	algo.head_cursor.t = head_cursor
	algo.insert_rect.t = insert_rect
	algo.compare_rect.t = compare_rect
}
insertion_sort_start :: proc(algo: ^InsersionSort) {
	algo.assist_opacity.start = eval(algo.assist_opacity)
	algo.head_cursor.start = eval(algo.head_cursor)
	algo.insert_rect.start = eval(algo.insert_rect)
	algo.compare_rect.start = eval(algo.compare_rect)
}
insertion_sort_change_state :: proc(
	sort: ^Sort,
	algo: ^InsersionSort,
	state: InsersionSortState,
	dur: f32,
) -> (
	is_completed: bool,
) {
	for &bar, i in sort.vals {
		bar.rect.start = eval(bar.rect)
		bar.rect.end = insert_sort_fin_rect(sort.vals[:], i)
		bar.rect.t = 0
		bar.rect.dur = dur
	}
	algo.step_time -= algo.step_dur
	algo.step_dur = dur // dur
	algo.state = state
	insertion_sort_start(algo)
	insertion_sort_dur(algo, algo.step_dur, algo.step_dur, algo.step_dur, algo.step_dur)
	insertion_sort_t(algo, 0, 0, 0, 0)
	tmp := algo.step_time < algo.step_dur
	algo.step_time -= sort.dt * (1 + sort.speed)
	return tmp
}
process_insertion_sort :: proc(sort: ^Sort, algo: ^InsersionSort) -> (is_completed: bool) {
	MOVE_HEAD_DUR :: 0.1
	SWAP_DUR :: 0.1
	COMPARE_DUR :: 0.1
	MOVE_NEXT_DUR :: 0.1
	defer {
		dt := sort.dt * (1 + sort.speed)
		algo.step_time += dt
		for &bar in sort.vals {
			bar.rect.t += dt / bar.rect.dur
		}
		algo.assist_opacity.t += dt / algo.assist_opacity.dur
		algo.head_cursor.t += dt / algo.head_cursor.dur
		algo.insert_rect.t += dt / algo.insert_rect.dur
		algo.compare_rect.t += dt / algo.compare_rect.dur
	}
	for &bar, i in sort.vals {
		bar.rect.end = insert_sort_fin_rect(sort.vals[:], i)
	}

	switch algo.state {
	case .Initialization:
		insertion_animate_step(sort, algo, algo.head, algo.insert, algo.compare)
		// init finished
		if algo.step_time > algo.step_dur {
			algo.head += 1
			algo.insert += 1
			if algo.head >= len(sort.vals) {
				reset_sort(sort)
			} else {
				// move on
				return insertion_sort_change_state(sort, algo, .MoveHead, MOVE_HEAD_DUR)
			}
		}
	case .MoveHead:
		// DONE
		// Compare
		insertion_animate_step(sort, algo, algo.head, algo.insert, algo.compare)
		if algo.step_time > algo.step_dur {
			return insertion_sort_change_state(sort, algo, .Compare, COMPARE_DUR)
		}
	case .Swap:
		// MoveNext, MoveHead, Fin
		insertion_animate_step(sort, algo, algo.head, algo.insert - 1, algo.compare + 1)
		if algo.step_time > algo.step_dur {
			if algo.compare <= 0 {
				if algo.head + 1 >= len(sort.vals) {
					reset_sort(sort)
				} else {
					// reached start
					algo.head += 1
					algo.insert = algo.head
					algo.compare = algo.head - 1
					return insertion_sort_change_state(sort, algo, .MoveHead, MOVE_HEAD_DUR)
				}
			} else {
				algo.insert -= 1
				algo.compare -= 1
				return insertion_sort_change_state(sort, algo, .MoveNext, MOVE_NEXT_DUR)
			}
		}
	case .Compare:
		// Swap, MoveHead, Fin
		if algo.step_time > algo.step_dur {
			if sort.vals[algo.compare].value > sort.vals[algo.insert].value {
				slice.swap(sort.vals[:], algo.compare, algo.insert)
				return insertion_sort_change_state(sort, algo, .Swap, SWAP_DUR)
			} else {
				if algo.head + 1 >= len(sort.vals) {
					reset_sort(sort)
				} else {
					// move on
					algo.head += 1
					algo.insert = algo.head
					algo.compare = algo.head - 1
					return insertion_sort_change_state(sort, algo, .MoveHead, MOVE_HEAD_DUR)
				}
			}
		}
	case .MoveNext:
		// Compare
		insertion_animate_step(sort, algo, algo.head, algo.insert, algo.compare)
		if algo.step_time > algo.step_dur {
			return insertion_sort_change_state(sort, algo, .Compare, COMPARE_DUR)
		}
	}
	return true
}
draw_insertion_sort :: proc(sort: ^Sort, algo: ^InsersionSort) {
	push_rect_matrix(sort.frame)
	{ 	// cursor
		CURSOR_WIDTH :: 0.1
		cursor := eval(algo.head_cursor)
		draw_sort_cursor(
			exd(
				{
					cursor - INSERTION_SORT_CURSOR_SIZE / 4,
					1 - INSERTION_SORT_CURSOR_SIZE,
					INSERTION_SORT_CURSOR_SIZE / 2,
					INSERTION_SORT_CURSOR_SIZE,
				},
				-0.000,
			),
			{255, 0, 0, u8(255 * eval(algo.assist_opacity))},
		)
	}
	rl.DrawRectangleRec(eval(algo.compare_rect), rl.ORANGE)
	rl.DrawRectangleRec(eval(algo.insert_rect), rl.RED)
	draw_bars(sort.vals[:])
	pop_rect_matrix()
}
draw_bars :: proc(bars: []BarValue) {
	for bar, i in bars {
		rl.DrawRectangleRec(eval(bar.rect), bar.real_place == i ? rl.GREEN : rl.BLACK)
	}
}
insertion_animate_step :: proc(sort: ^Sort, algo: ^InsersionSort, head, insert, compare: int) {
	head_rect := insert_sort_fin_rect(sort.vals[:], head)
	insert_rect := insert_sort_fin_rect(sort.vals[:], insert)
	compare_rect := insert_sort_fin_rect(sort.vals[:], compare)
	insertion_sort_target(
		algo,
		1,
		head_rect.x + head_rect.width / 2,
		exd(insert_rect, 0.01),
		exd(compare_rect, 0.01),
	)
}
