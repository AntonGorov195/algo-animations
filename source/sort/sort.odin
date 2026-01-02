package sort

import rl "vendor:raylib"
import "vendor:raylib/rlgl"

Algo :: union {
	InsersionSort,
	BubbleSort,
	QuickSort,
}
Window :: struct {
	rect:       Animated(rl.Rectangle),
	color:      Animated(rl.Color),
	start, end: int,
}
SortHighlightedBar :: struct {
	idx:   int,
	rect:  Animated(rl.Rectangle),
	color: Animated(rl.Color),
}
Cursor :: struct {
	idx:    int,
	color:  Animated(rl.Color),
	tip:    Animated([2]f32),
	width:  Animated(f32),
	height: Animated(f32),
}
Sort :: struct {
	dt:        f32, // process delta time, before speed.
	speed:     f32,
	algo:      Algo,
	frame:     rl.Rectangle, // where the animation will happened in screen coords
	vals:      [dynamic]BarValue,
	step_time: f32,
	step_dur:  f32,
}
BarValue :: struct {
	value:      f32,
	height:     f32, // original size
	color:      Animated(rl.Color),
	rect:       Animated(rl.Rectangle), // animated index
	real_place: int, // sorted index
}

BAR_GAP :: 0.4 // Proportional to bar width
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
			dt := sort.dt * (1 + sort.speed)
			for &bar in sort.vals {
				bar.rect.t += dt / bar.rect.dur
			}
		}
		for &bar, i in sort.vals {
			count := len(sort.vals)
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
		draw_bars(sort.vals[:])
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
	for &bar in sort.vals {
		bar.rect.start = eval(bar.rect)
		bar.rect.t = 0
		bar.rect.dur = 1
	}
}

// return the intended rect of the window
// 	rect - content rect of the bar graph.
// 	match_height - window has height of the max element in slice
window_rect :: proc(
	sort: ^Sort,
	window: Window,
	rect: rl.Rectangle,
	match_height := false,
	loc := #caller_location,
) -> rl.Rectangle {
	count := f32(len(sort.vals))
	window_size := f32(window_len(window))
	gap_count := f32(count) - 1
	w := rect.width / (count + gap_count * BAR_GAP)
	x := w * f32(window.start) * (1 + BAR_GAP) + rect.x
	w *= window_size + (window_size - 1) * BAR_GAP
	h := rect.height
	if match_height {
		h = 0
		for bar in sort.vals[window.start:window.end]{
			h = max(h, bar.height)
		}
	}
	y: f32 = rect.height - h + rect.y
	return {x, y, w, h}
}
bar_rect :: proc(sort: ^Sort, idx: int, rect: rl.Rectangle) -> rl.Rectangle {
	bar := sort.vals[idx]
	count := f32(len(sort.vals))
	gap_count := count
	w := rect.width / (count + gap_count * BAR_GAP)
	x := w * f32(idx) * (1 + BAR_GAP) + rect.x
	h := bar.height * rect.height
	y := rect.height - h + rect.y
	return {x, y, w, h}
}
window_len :: proc(window: Window) -> int {
	return window.end - window.start 
}
window_to_slice :: proc(
	sort: ^Sort,
	window: Window,
	loc := #caller_location,
) -> (
	result: []BarValue = {},
	err: Error,
) {
	validate_sort_window(sort, window) or_return
	return sort.vals[window.start:window.end], nil
}
extend_rect_all :: proc(rect: rl.Rectangle, ex: f32) -> rl.Rectangle {
	return extend_rect_sides(rect, ex, ex, ex, ex)
}
extend_rect_sides :: proc(rect: rl.Rectangle, top, right, bottom, left: f32) -> rl.Rectangle {
	return {rect.x - right, rect.y - top, rect.width + right + left, rect.height + top + bottom}
}
exd :: proc {
	extend_rect_all,
	extend_rect_sides,
}
rect_end_pos_x :: proc(count: int, index: int) -> f32 {
	w := calc_bar_width(count)
	return w * f32(index) * (1 + BAR_GAP)
}
draw_sort_cursor :: proc(bound: rl.Rectangle, color: rl.Color) {
	rl.DrawTriangle(
		{bound.x + bound.width / 2, bound.y},
		{bound.x, bound.y + bound.height},
		{bound.x + bound.width, bound.y + bound.height},
		color,
	)
}
calc_bar_width :: proc(count: int, gap: f32 = BAR_GAP) -> f32 {
	gap_count := f32(count) - 1
	return 1 / (f32(count) + gap_count * BAR_GAP)
}
