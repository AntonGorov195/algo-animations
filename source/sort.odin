package game

import rl "vendor:raylib"
import "vendor:raylib/rlgl"

process_sort :: proc(sort: ^Sort) {
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
	case InsersionSort:
		defer {
            sort.step_t += g.input.dt * (1 + sort.speed) * (1 + g.speed) / sort.step_dur
			for &bar in sort.values {
				advance_sort(sort, &bar.rect)
			}
			advance_sort(sort, &algo.assist_opacity)
			advance_sort(sort, &algo.head_cursor)
			advance_sort(sort, &algo.insert_rect)
			advance_sort(sort, &algo.compare_rect)
		}

		switch algo.state {
		case .Initialization:
			for &bar, i in sort.values {
				bar.rect.end = insert_sort_fin_rect(sort.values[:], i)
			}
			algo.assist_opacity.end = 1
			{
				rect := insert_sort_fin_rect(sort.values[:], algo.head)
				algo.head_cursor.end = rect.x + rect.width / 2
			}
			algo.insert_rect.end = extend_rect(
				insert_sort_fin_rect(sort.values[:], algo.insert),
				0.01,
			)
			algo.compare_rect.end = extend_rect(
				insert_sort_fin_rect(sort.values[:], algo.compare),
				0.01,
			)
			// init finished
			if sort.step_t > 1 {

			}
		case .MoveHead:
		case .Swap:
		case .Compare:
		case .MoveNext:
		}
	case:
		unreachable()
	}
}
draw_sort :: proc(sort: ^Sort) {
	assert(sort != nil)
	switch algo in sort.algo {
	case nil:
		rlgl.PushMatrix()
		rlgl.Translatef((SCREEN_WIDTH - SIM_WINDOW.x) / 2, (SCREEN_HEIGHT - SIM_WINDOW.y) / 2, 0)
		rlgl.Scalef(SIM_WINDOW.x, SIM_WINDOW.y, 1)
		for bar in sort.values {
			rl.DrawRectangleRec(eval_anim(bar.rect), rl.GREEN)
		}
		rlgl.PopMatrix()
	case InsersionSort:
		rlgl.PushMatrix()
		rlgl.Translatef((SCREEN_WIDTH - SIM_WINDOW.x) / 2, (SCREEN_HEIGHT - SIM_WINDOW.y) / 2, 0)
		rlgl.Scalef(SIM_WINDOW.x, SIM_WINDOW.y, 1)
		{
			CURSOR_WIDTH :: 0.13
			cursor := eval_anim(algo.head_cursor)
			draw_sort_cursor(
				extend_rect(
					{
						cursor - CURSOR_WIDTH / 2,
						1 - INSERTION_SORT_CURSOR_SIZE,
						CURSOR_WIDTH,
						INSERTION_SORT_CURSOR_SIZE,
					},
					-0.03,
				),
				{255, 0, 0, u8(255 * eval_anim(algo.assist_opacity))},
			)
		}
		rl.DrawRectangleRec(eval_anim(algo.insert_rect), rl.RED)
		for bar in sort.values {
			rl.DrawRectangleRec(eval_anim(bar.rect), rl.GREEN)
		}
		rlgl.PopMatrix()
	case:
		unreachable()
	}
}

INSERTION_SORT_CURSOR_SIZE :: 0.2
insert_sort_fin_rect :: proc(vals: []BarValue, idx: int) -> rl.Rectangle {
	PADDING :: 0.01
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
