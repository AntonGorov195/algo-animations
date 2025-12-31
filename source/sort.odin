package game

import rl "vendor:raylib"
import "vendor:raylib/rlgl"

SortAlgo :: union {
	InsersionSort,
	BubbleSort,
}
Sort :: struct {
	algo:   SortAlgo,
	speed:  f32,
	frame:  rl.Rectangle, // where the animation will happened
	values: [dynamic]BarValue,
}

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
		process_insertion_sort(sort, &algo)
	case BubbleSort:
		process_bubble_sort(sort, &algo)
	case:
		unreachable()
	}
	return true
}
draw_sort :: proc(sort: ^Sort) {
	assert(sort != nil)
	switch &algo in sort.algo {
	case nil:
		push_rect_matrix(sort.frame)
		for bar in sort.values {
			rl.DrawRectangleRec(eval_anim(bar.rect), rl.BLACK)
		}
		rlgl.PopMatrix()
	case InsersionSort:
		draw_insertion_sort(sort, &algo)
	case BubbleSort:
		draw_bubble_sort(sort, &algo)
	case:
		unreachable()
	}
}
push_rect_matrix :: proc(rect: rl.Rectangle) {
	rlgl.PushMatrix()
	rlgl.Translatef(rect.x, rect.y, 0)
	rlgl.Scalef(rect.width, rect.height, 1)
}
pop_rect_matrix :: proc() {
	rlgl.PopMatrix()
}
