package sort

import rl "vendor:raylib"
import "vendor:raylib/rlgl"

Algo :: union {
	InsersionSort,
	BubbleSort,
	QuickSort,
}
Window :: struct {
	start, end: int,
	extend:     Animated([4]f32), // padding
	rect:       Animated(rl.Rectangle),
	color:      Animated(rl.Color),
}
HighlightedBar :: struct {
	idx:    int,
	extend: Animated([4]f32), // padding
	rect:   Animated(rl.Rectangle),
	color:  Animated(rl.Color),
}
Cursor :: struct {
	idx:    int,
	target: Animated([2]f32),
	width:  Animated(f32),
	height: Animated(f32),
	margin: Animated(f32), // margin between the target and tip
	color:  Animated(rl.Color),
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
HIGHLIGHT_EXD :: 0.007
WINDOW_EXD :: 0.015
DEFAULT_STEP_DUR :: 0.2

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
			bar.rect.dur = DEFAULT_STEP_DUR
			bar.rect.type = .SmoothStep3
			bar.rect.end = bar_rect(sort, i, {0, 0, 1, 1})
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
		for bar in sort.vals[window.start:window.end] {
			h = max(h, bar.height)
		}
		h *= rect.height 
	}
	y: f32 = rect.height - h + rect.y
	return {x, y, w, h}
}
bar_rect :: proc(sort: ^Sort, idx: int, rect: rl.Rectangle) -> rl.Rectangle {
	bar := sort.vals[idx]
	count := f32(len(sort.vals))
	gap_count := count - 1
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
extend_rect_sides_vec :: proc(rect: rl.Rectangle, sides: [4]f32) -> rl.Rectangle {
	return exd(rect, sides.x, sides.y, sides.z, sides.w)
}
exd :: proc {
	extend_rect_all,
	extend_rect_sides,
	extend_rect_sides_vec,
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
advance_highlight_bar :: proc(sort: ^Sort, highlight: ^HighlightedBar) {
	dt := sort.dt * (1 + sort.speed)
	highlight.rect.t += dt / highlight.rect.dur
	highlight.extend.t += dt / highlight.extend.dur
	highlight.color.t += dt / highlight.color.dur
}
advance_cursor :: proc(sort: ^Sort, cursor: ^Cursor) {
	dt := sort.dt * (1 + sort.speed)
	cursor.margin.t += dt / cursor.margin.dur
	cursor.color.t += dt / cursor.color.dur
	cursor.target.t += dt / cursor.target.dur
	cursor.width.t += dt / cursor.width.dur
	cursor.height.t += dt / cursor.height.dur
}
advance_window :: proc(sort: ^Sort, window: ^Window) {
	dt := sort.dt * (1 + sort.speed)
	window.rect.t += dt / window.rect.dur
	window.extend.t += dt / window.extend.dur
	window.color.t += dt / window.color.dur
}
advance_sort :: proc(sort: ^Sort) {
	dt := sort.dt * (1 + sort.speed)
	sort.step_time += dt
	for &bar in sort.vals {
		bar.rect.t += dt / bar.rect.dur
	}
}
cursor_point_at :: proc(sort: ^Sort, cursor: ^Cursor) {
	target := sort.vals[cursor.idx].rect
	cursor.target.end.x = target.end.x + target.end.width / 2
	cursor.target.end.y = target.end.y + target.end.height
	cursor.target.t = target.t
	cursor.target.dur = target.dur
	cursor.target.type = target.type
}
highlight_with_color :: proc(sort: ^Sort, highlight: ^HighlightedBar, color: rl.Color) {
	target := sort.vals[highlight.idx].rect
	highlight.rect.end = target.end
	highlight.rect.t = target.t
	highlight.rect.dur = target.dur
	highlight.rect.type = target.type

	highlight.color.end = color
}
highlight_bar :: proc(sort: ^Sort, highlight: ^HighlightedBar) {
	highlight_with_color(sort, highlight, highlight.color.end)
}
highlight :: proc {
	highlight_bar,
	highlight_with_color,
}
highlight_reset :: proc(h: ^HighlightedBar, dur: f32) {
	h.color.start = eval(h.color)
	h.extend.start = eval(h.extend)
	h.rect.start = eval(h.rect)

	h.color.t = 0
	h.extend.t = 0
	h.rect.t = 0

	h.color.dur = dur
	h.extend.dur = dur
	h.rect.dur = dur
}
cursor_reset :: proc(c: ^Cursor, dur: f32) {
	c.margin.start = eval(c.margin)
	c.color.start = eval(c.color)
	c.target.start = eval(c.target)
	c.width.start = eval(c.width)
	c.height.start = eval(c.height)

	c.margin.t = 0
	c.color.t = 0
	c.target.t = 0
	c.width.t = 0
	c.height.t = 0

	c.margin.dur = dur
	c.color.dur = dur
	c.target.dur = dur
	c.width.dur = dur
	c.height.dur = dur
}
window_reset :: proc(window: ^Window, dur: f32) {
	window.extend.start = eval(window.extend)
	window.rect.start = eval(window.rect)
	window.color.start = eval(window.color)

	window.extend.t = 0
	window.rect.t = 0
	window.color.t = 0

	window.extend.dur = dur
	window.rect.dur = dur
	window.color.dur = dur
}
