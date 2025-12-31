package game

import "core:slice"
import rl "vendor:raylib"
import "vendor:raylib/rlgl"

process_sort :: proc(sort: ^Sort) -> (is_completed: bool) {
	assert(sort != nil)
	switch &algo in sort.algo {
	case nil:
		defer {
			for &bar in sort.values {
				advance_sort(sort, &bar.rect)
			}
		}
		for &bar, i in sort.values {
			count := len(sort.values)
			w := calc_bar_width(count)
			x := rect_end_pos_x(count, i)
			bar.rect.end = rl.Rectangle{x, 1 - bar.height, w, bar.height}
		}
		return true
	case InsersionSort:
		MOVE_HEAD_DUR :: 0.1
		SWAP_DUR :: 0.1
		COMPARE_DUR :: 0.1
		MOVE_NEXT_DUR :: 0.1
		defer {
			algo.step_time += g.input.dt * (1 + sort.speed) * (1 + g.speed)
			for &bar in sort.values {
				advance_sort(sort, &bar.rect)
			}
			advance_sort(sort, &algo.assist_opacity)
			advance_sort(sort, &algo.head_cursor)
			advance_sort(sort, &algo.insert_rect)
			advance_sort(sort, &algo.compare_rect)
		}
		for &bar, i in sort.values {
			bar.rect.end = insert_sort_fin_rect(sort.values[:], i)
		}

		switch algo.state {
		case .Initialization:
			// DONE
			// MoveHead, Fin
			head_rect := insert_sort_fin_rect(sort.values[:], algo.head)
			insert_rect := insert_sort_fin_rect(sort.values[:], algo.insert)
			compare_rect := insert_sort_fin_rect(sort.values[:], algo.compare)
			insertion_sort_target(
				&algo,
				1,
				head_rect.x + head_rect.width / 2,
				extend_rect(insert_rect, 0.01),
				extend_rect(compare_rect, 0.01),
			)
			// init finished
			if algo.step_time > algo.step_dur {
				if algo.head + 1 >= len(sort.values) {
					algo.step_dur = 1
					sort.algo = nil
					for &bar in sort.values {
						bar.rect.start = eval_anim(bar.rect)
						bar.rect.t = 0
						bar.rect.dur = 1
					}
				} else {
					// move on
					return insertion_sort_change_state(sort, &algo, .MoveHead, MOVE_HEAD_DUR)
				}
			}
		case .MoveHead:
			// DONE
			// Compare
			head_rect := insert_sort_fin_rect(sort.values[:], algo.head)
			insert_rect := insert_sort_fin_rect(sort.values[:], algo.insert)
			compare_rect := insert_sort_fin_rect(sort.values[:], algo.compare)
			insertion_sort_target(
				&algo,
				1,
				head_rect.x + head_rect.width / 2,
				extend_rect(insert_rect, 0.01),
				extend_rect(compare_rect, 0.01),
			)
			if algo.step_time > algo.step_dur {
				return insertion_sort_change_state(sort, &algo, .Compare, COMPARE_DUR)
			}
		case .Swap:
			// MoveNext, MoveHead, Fin
			head_rect := insert_sort_fin_rect(sort.values[:], algo.head)
			insert_rect := insert_sort_fin_rect(sort.values[:], algo.insert - 1)
			compare_rect := insert_sort_fin_rect(sort.values[:], algo.compare + 1)
			insertion_sort_target(
				&algo,
				1,
				head_rect.x + head_rect.width / 2,
				extend_rect(insert_rect, 0.01),
				extend_rect(compare_rect, 0.01),
			)
			if algo.step_time > algo.step_dur {
				if algo.compare <= 0 {
					if algo.head + 1 >= len(sort.values) {
						sort.algo = nil
						for &bar in sort.values {
							bar.rect.start = eval_anim(bar.rect)
							bar.rect.t = 0
							bar.rect.dur = 1
						}
					} else {
						// reached start
						algo.head += 1
						algo.insert = algo.head
						algo.compare = algo.head - 1
						return insertion_sort_change_state(sort, &algo, .MoveHead, MOVE_HEAD_DUR)
					}
				} else {
					algo.insert -= 1
					algo.compare -= 1
					return insertion_sort_change_state(sort, &algo, .MoveNext, MOVE_NEXT_DUR)
				}
			}
		case .Compare:
			// Swap, MoveHead, Fin
			if algo.step_time > algo.step_dur {
				if sort.values[algo.compare].value > sort.values[algo.insert].value {
					slice.swap(sort.values[:], algo.compare, algo.insert)
					return insertion_sort_change_state(sort, &algo, .Swap, SWAP_DUR)
				} else {
					if algo.head + 1 >= len(sort.values) {
						sort.algo = nil
						for &bar in sort.values {
							bar.rect.start = eval_anim(bar.rect)
							bar.rect.t = 0
							bar.rect.dur = 1
						}
					} else {
						// move on
						algo.head += 1
						algo.insert = algo.head
						algo.compare = algo.head - 1
						return insertion_sort_change_state(sort, &algo, .MoveHead, MOVE_HEAD_DUR)
					}
				}
			}
		case .MoveNext:
			// Compare
			head_rect := insert_sort_fin_rect(sort.values[:], algo.head)
			insert_rect := insert_sort_fin_rect(sort.values[:], algo.insert)
			compare_rect := insert_sort_fin_rect(sort.values[:], algo.compare)
			insertion_sort_target(
				&algo,
				1,
				head_rect.x + head_rect.width / 2,
				extend_rect(insert_rect, 0.01),
				extend_rect(compare_rect, 0.01),
			)
			if algo.step_time > algo.step_dur {
				return insertion_sort_change_state(sort, &algo, .Compare, COMPARE_DUR)
			}
		}
	case:
		unreachable()
	}
	return true
}
draw_sort :: proc(sort: ^Sort) {
	assert(sort != nil)
	switch algo in sort.algo {
	case nil:
		rlgl.PushMatrix()
		rlgl.Translatef(g.main_sort.frame.x, g.main_sort.frame.y, 0)
		rlgl.Scalef(g.main_sort.frame.width, g.main_sort.frame.height, 1)
		for bar in sort.values {
			rl.DrawRectangleRec(eval_anim(bar.rect), rl.BLACK)
		}
		rlgl.PopMatrix()
	case InsersionSort:
		rlgl.PushMatrix()
		rlgl.Translatef(g.main_sort.frame.x, g.main_sort.frame.y, 0)
		rlgl.Scalef(g.main_sort.frame.width, g.main_sort.frame.height, 1)
		{
			CURSOR_WIDTH :: 0.1
			cursor := eval_anim(algo.head_cursor)
			draw_sort_cursor(
				extend_rect(
					{
						cursor - INSERTION_SORT_CURSOR_SIZE / 4,
						1 - INSERTION_SORT_CURSOR_SIZE,
						INSERTION_SORT_CURSOR_SIZE / 2,
						INSERTION_SORT_CURSOR_SIZE,
					},
					-0.000,
				),
				{255, 0, 0, u8(255 * eval_anim(algo.assist_opacity))},
			)
		}
		rl.DrawRectangleRec(eval_anim(algo.compare_rect), rl.ORANGE)
		rl.DrawRectangleRec(eval_anim(algo.insert_rect), rl.RED)
		for bar in sort.values {
			rl.DrawRectangleRec(eval_anim(bar.rect), rl.BLACK)
		}
		rlgl.PopMatrix()
	case:
		unreachable()
	}
}

INSERTION_SORT_CURSOR_SIZE :: 0.1
insert_sort_fin_rect :: proc(vals: []BarValue, idx: int) -> rl.Rectangle {
	PADDING :: 0.03
	count := len(vals)
	// w := calc_bar_width(count)
	w: f32
	{
		gap_count := f32(count) - 1
		used_w: f32 = 1 - 2 * PADDING
		w = used_w / (f32(count) + gap_count * BAR_GAP)
	}
	// x := rect_end_pos_x(count, idx)
	x: f32
	{
		x = w * f32(idx) * (1 + BAR_GAP) + PADDING
		// 	w := calc_bar_width(count)
		// return w * f32(index) * (1 + BAR_GAP)
	}
	// rect := rl.Rectangle{x, 1 - vals[idx].height, w, vals[idx].height}

	bar := vals[idx]
	// count := len(vals)
	// return extend_rect(rect, -PADDING, -PADDING, -PADDING - INSERTION_SORT_CURSOR_SIZE, -PADDING)
	// gap_size: f32 = BAR_GAP
	// w: f32
	// {
	// 	gap_count := f32(count) - 1
	// 	w = 1 / (f32(count) + gap_count * gap_size) * (1 - PADDING)
	// }
	// x := w * f32(idx) * (1 + gap_size) + PADDING
	// return rl.Rectangle {
	// 	x,
	// 	(1 - bar.height) * (1 - INSERTION_SORT_CURSOR_SIZE) + PADDING,
	// 	w,
	// 	bar.height * (1 - INSERTION_SORT_CURSOR_SIZE),
	// }
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
	algo.assist_opacity.start = eval_anim(algo.assist_opacity)
	algo.head_cursor.start = eval_anim(algo.head_cursor)
	algo.insert_rect.start = eval_anim(algo.insert_rect)
	algo.compare_rect.start = eval_anim(algo.compare_rect)
}
insertion_sort_change_state :: proc(
	sort: ^Sort,
	algo: ^InsersionSort,
	state: InsersionSortState,
	dur: f32,
) -> (
	is_completed: bool,
) {
	for &bar, i in sort.values {
		bar.rect.start = eval_anim(bar.rect)
		bar.rect.end = insert_sort_fin_rect(sort.values[:], i)
		bar.rect.t = 0
		bar.rect.dur = dur
	}
	algo.step_time -= algo.step_dur
	algo.step_dur = dur // dur
	algo.state = state
	insertion_sort_start(algo)
	insertion_sort_dur(algo, algo.step_dur, algo.step_dur, algo.step_dur, algo.step_dur)
	insertion_sort_t(algo, 0, 0, 0, 0)
	return algo.step_time < algo.step_dur
}
