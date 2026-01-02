package sort

import "core:log"
import "core:math"
import rl "vendor:raylib"
import "vendor:raylib/rlgl"

InterpolationType :: enum {
	Linear, // default
	Quad,
	Cubic,
	Root2,
	Root3,
	SmoothStep3,
	SmoothStep5,
}

SortingErrorWindow :: struct {
	sort:    ^Sort,
	message: string, // temporary
	bounds:  [2]int,
}
SortingErrorIndexOutOfBound :: struct {
	sort:    ^Sort,
	message: string, // temporary
	bounds:  [2]int,
}
SortingErrorNoValues :: struct {
	sort:    ^Sort,
	message: string, // temporary
}
SortingError :: union {
	SortingErrorNoValues,
	SortingErrorIndexOutOfBound,
}
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
	dt:        f32, // process delta time, before speed.
	speed:     f32,
	algo:      SortAlgo,
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
// 	match_height - .
sort_window_rect :: proc(
	sort: ^Sort,
	window: SortingWindow,
	rect: rl.Rectangle,
	match_height := false,
	loc := #caller_location,
) -> rl.Rectangle {
	// vals_count := len(sort.vals)
	// window_count := sorting_window_len(window)
	// if window_count < 0 {
	// 	return {}
	// }
	// gap_count := f32(count) - 1
	// used_w: f32 = 1 - 2 * QUICK_SORT_PADDING
	// w := used_w / (f32(count) + gap_count * BAR_GAP)
	// x := w * f32(slice.start) * (1 + BAR_GAP) + QUICK_SORT_PADDING
	// w = w * f32(qs_len(slice)) + w * f32(qs_len(slice) - 1) * BAR_GAP
	// h := f32(1 - 2 * QUICK_SORT_PADDING - QUICK_SORT_CURSOR_SIZE)
	// y: f32 = QUICK_SORT_PADDING
	return {} // {x, y, w, h}
}

// returns the intended end result of the bars value
// 	rect - content rect of the bar graph
bar_value_rect :: proc(
	sort: ^Sort,
	idx: int,
	rect: rl.Rectangle,
	loc := #caller_location,
) -> rl.Rectangle {
	count := len(sort.vals)
	if count < 1 {
		log.warn("passed sort with zero values", location = loc)
		return {}
	}
	if idx < 0 {
		log.errorf("index %d in", idx, location = loc)
		return {}
	}
	if idx >= count {
		log.errorf("index %d and count %d", idx, count, location = loc)
	}
	gap_count := f32(count) - 1
	w := rect.width / (f32(count) + gap_count * BAR_GAP)
	x := w * f32(idx) * (1 + BAR_GAP)
	bar := sort.vals[idx]
	h := bar.height * rect.height
	y := 1 - h
	return {x, y, w, h}
}
sorting_window_len :: proc(window: SortingWindow) -> int {
	return window.end - window.start
}
sorting_window_to_slice :: proc(
	sort: ^Sort,
	window: SortingWindow,
	loc := #caller_location,
) -> []BarValue {
	if window.start > window.end {
		log.warnf(
			"trying to make a slice form window start %v, end %v",
			window.start,
			window.end,
			location = loc,
		)
		return {}
	}
	return sort.vals[window.start:window.end]
}
Animated :: struct($T: typeid) {
	type:  InterpolationType,
	t:     f32,
	dur:   f32, // when dur == 0 then value == end
	start: T,
	end:   T,
}
to_anim :: proc(val: $T) -> Animated(T) {
	if false {
		// Assert T can be interpolated
		_ = interp(val, val, 0)
	}
	return {start = val, end = val}
}
eval :: proc(val: Animated($T)) -> T {
	return interp(val.start, val.end, val.t, val.type)
}
anim_retarget :: proc(
	val: ^Animated($T),
	target: T,
	type: InterpolationType,
	dur: f32,
) -> Animated(T) {
	val^ = {
		type  = type,
		t     = 0,
		dur   = dur,
		start = eval(val^),
		end   = target,
	}
	return val^
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
interp_rect :: proc(
	start: rl.Rectangle,
	end: rl.Rectangle,
	t: f32,
	type: InterpolationType = .Linear,
) -> rl.Rectangle {
	// t_inter := interp01(t, type)
	return {
		interp(start.x, end.x, t, type),
		interp(start.y, end.y, t, type),
		interp(start.width, end.width, t, type),
		interp(start.height, end.height, t, type),
	}
}
interp_values_array :: proc(
	start: $T/[$N]f32,
	end: T,
	t: f32,
	type: InterpolationType = .Linear,
) -> T {
	t_inter := interp01(t, type)
	return start * (1 - t_inter) + end * t_inter
}
interp_values :: proc(start: f32, end: f32, t: f32, type: InterpolationType = .Linear) -> f32 {
	t_inter := interp01(t, type)
	return start * (1 - t_inter) + end * t_inter
}
interp01 :: proc(t: f32, type: InterpolationType = .Linear) -> f32 {
	// unimplemented()
	t := t
	t = clamp(t, 0, 1)
	switch type {
	case .Linear:
		return t
	case .Quad:
		return t * t
	case .Cubic:
		return t * t * t
	case .Root2:
		return math.sqrt(t)
	case .Root3:
		return math.pow(t, 1. / 3.)
	case .SmoothStep3:
		return 3 * t * t - 2 * t * t * t
	case .SmoothStep5:
		t3 := t * t * t
		return 6 * t3 * t * t - 15 * t3 * t + 10 * t3
	}
	unreachable()
}
interp :: proc {
	interp01,
	interp_values,
	interp_values_array,
	interp_rect,
}
