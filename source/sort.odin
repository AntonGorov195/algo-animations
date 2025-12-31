package game

import R "resources"
import rl "vendor:raylib"
import "vendor:raylib/rlgl"

SELECTION_RECT_EXTENDS :: 0.003
BAR_GAP :: 0.03

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
		draw_bars(sort.values[:])
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
draw_bars :: proc(bars: []BarValue) {
	for bar, i in bars {
		new_year := R.get(g.new_year)
		w := f32(new_year.width) / f32(len(bars))
		rl.DrawTexturePro(
			new_year,
			{w * f32(bar.real_place), 0, w, f32(new_year.height)},
			eval_anim(bar.rect),
			{},
			0,
			bar.real_place == i ? {255, 255, 255, 255} : {127, 127, 127, 255},
		)
	}
}
reset_sort :: proc(sort: ^Sort) {
	play_sound(g.hohoho)
	sort.algo = nil
	for &bar in sort.values {
		bar.rect.start = eval_anim(bar.rect)
		bar.rect.t = 0
		bar.rect.dur = 1
	}
}
