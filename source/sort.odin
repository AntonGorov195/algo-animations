package game

import rl "vendor:raylib"
import "vendor:raylib/rlgl"

SortAlgo :: union {
	InsersionSort,
	BubbleSort,
	QuickSort,
}
SortingWindow :: struct {
	rect:       Animated(rl.Rectangle),
	color:      Animated(rl.Color),
	start, end: int,
}
SortHighlightedBar :: struct {
	idx:   int,
	rect:  Animated(rl.Rectangle),
	color: Animated(rl.Color),
}
SortCursor :: struct {
	idx:    int,
	color:  Animated(rl.Color),
	tip:    Animated([2]f32),
	width:  Animated(f32),
	height: Animated(f32),
}
Sort :: struct {
	algo:        SortAlgo,
	speed:       f32,
	frame:       rl.Rectangle, // where the animation will happened in screen coords
	val_rect:    Animated(rl.Rectangle), // [0, 1]
	win_padding: Animated(f32),
	values:      [dynamic]BarValue,
}

BAR_GAP :: 0.4
PIVOT_COLOR :: rl.BLUE
COMPARE_COLOR :: rl.ORANGE
SELECTED_COLOR :: rl.RED
HIGHLIGHT_EXD :: 0.01
WINDOW_EXD :: 0.01
DEFAULT_STEP_DUR :: 0.1

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
		return process_insertion_sort(sort, &algo)
	case BubbleSort:
		return process_bubble_sort(sort, &algo)
	case QuickSort:
		return process_quick_sort(sort, &algo)
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
	case QuickSort:
		draw_quick_sort(sort, &algo)
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
reset_sort :: proc(sort: ^Sort) {
	sort.algo = nil
	for &bar in sort.values {
		bar.rect.start = eval(bar.rect)
		bar.rect.t = 0
		bar.rect.dur = 1
	}
}
sort_window_rect :: proc(sort: ^Sort) -> rl.Rectangle {
	return {}
}
// returns the intended end result of the bars value
bar_value_rect :: proc(sort: ^Sort, idx: int) -> rl.Rectangle {
	return {}
}