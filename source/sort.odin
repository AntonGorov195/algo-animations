package game

import rl "vendor:raylib"
import "vendor:raylib/rlgl"

process_sort :: proc(sort: ^Sort) {
	assert(sort != nil)
	switch &algo in sort.algo {
	case nil:
		for &bar, i in sort.values {
			count := len(sort.values)
			w := calc_bar_width(count)
			x := rect_end_pos_x(count, i)

			bar.rect.dur = 0.1
			bar.rect.type = .Linear
			bar.rect.end = rl.Rectangle{x, 1 - bar.height, w, bar.height}
			advance_sort(sort, &bar.rect)
		}
	case InsersionSort:
		for &bar in sort.values {
			advance_sort(sort, &bar.rect)
		}
		advance_sort(sort, &algo.assist_opacity)
		advance_sort(sort, &algo.head_cursor)
		advance_sort(sort, &algo.insert_rect)
		advance_sort(sort, &algo.compare_rect)

		switch algo.state {
		case .Initialization:
			for &bar, i in sort.values {
				count := len(sort.values)
				w := calc_bar_width(count)
				x := rect_end_pos_x(count, i)
                
				bar.rect.dur = 0.1
				bar.rect.type = .Linear
				bar.rect.end = rl.Rectangle{x, (1 - bar.height) * 0.8, w, bar.height * 0.8}
				advance_sort(sort, &bar.rect)
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
		for bar in sort.values {
			rl.DrawRectangleRec(eval_anim(bar.rect), rl.GREEN)
		}
		rlgl.PopMatrix()
	case:
		unreachable()
	}
}
