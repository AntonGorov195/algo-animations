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

BAR_GAP :: 0.2 // Proportional to bar width
PIVOT_COLOR :: rl.BLUE
COMPARE_COLOR :: rl.ORANGE
SELECTED_COLOR :: rl.RED
CURSOR_COLOR :: rl.RED
HIDE_WINDOW_COLOR :: rl.BLACK
HIGHLIGHT_EXD :: 0.005
WINDOW_EXD :: 0.015
CUSOR_WIDTH :: 0.03
CUSOR_HEIGHT :: 0.08
CUSOR_SPACE :: 0.02
DEFAULT_STEP_DUR :: 0.9
DEFAULT_INTERPOLATION_TYPE :: InterpolationType.SmoothStep3

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
			bar.rect.type = DEFAULT_INTERPOLATION_TYPE
			bar.rect.end = bar_target_rect(sort, i, {0, 0, 1, 1})
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
window_target_rect :: proc(
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
window_target_rect2 :: proc(
	sort: ^Sort,
	start: int,
	end: int,
	rect: rl.Rectangle,
	match_height := false,
	loc := #caller_location,
) -> rl.Rectangle {
	count := f32(len(sort.vals))
	window_size := f32(end - start)
	gap_count := f32(count) - 1
	w := rect.width / (count + gap_count * BAR_GAP)
	x := w * f32(start) * (1 + BAR_GAP) + rect.x
	w *= window_size + (window_size - 1) * BAR_GAP
	h := rect.height
	if match_height {
		h = 0
		for bar in sort.vals[start:end] {
			h = max(h, bar.height)
		}
		h *= rect.height
	}
	y: f32 = rect.height - h + rect.y
	return {x, y, w, h}
}
window_rect :: proc(sort: ^Sort, start, end: int, height: Maybe(f32) = nil) -> rl.Rectangle {
	x, y, w, h: f32
	x = 1
	y = 1
	for bar in sort.vals[start:end] {
		r := eval(bar.rect)
		x = min(x, r.x)
		y = min(y, r.y)
		w = max(w, r.x + r.width)
		h = max(h, r.height)
	}
	w -= x
	return {x, y, w, h}
}
bar_target_rect :: proc(sort: ^Sort, idx: int, rect: rl.Rectangle) -> rl.Rectangle {
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
advance_sort :: proc(sort: ^Sort) {
	dt := sort.dt * (1 + sort.speed)
	sort.step_time += dt
	for &bar in sort.vals {
		bar.rect.t += dt / bar.rect.dur
	}
}
draw_bars :: proc(bars: []BarValue) {
	for bar, i in bars {
		rl.DrawRectangleRec(eval(bar.rect), bar.real_place == i ? rl.GREEN : rl.BLACK)
	}
}

// In the animation, there is the starting value, end value and current value.
// track - current value. time is a side effect
// target - start/end value. no side effects

track_window_rect :: proc(sort: ^Sort, start, end: int) -> rl.Rectangle {
	x, y, w, h: f32
	x = 1
	y = 1
	for bar in sort.vals[start:end] {
		r := eval(bar.rect)
		x = min(x, r.x)
		y = min(y, r.y)
		w = max(w, r.x + r.width)
		h = max(h, r.height)
	}
	w -= x
	return {x, y, w, h}
} // tracks the current thing.
target_window_rect :: proc(
	sort: ^Sort,
	start: int,
	end: int,
	rect: rl.Rectangle,
	match_height := false,
) -> rl.Rectangle {
	count := f32(len(sort.vals))
	window_size := f32(end - start)
	gap_count := f32(count) - 1
	w := rect.width / (count + gap_count * BAR_GAP)
	x := w * f32(start) * (1 + BAR_GAP) + rect.x
	w *= window_size + (window_size - 1) * BAR_GAP
	h := rect.height
	if match_height {
		h = 0
		for bar in sort.vals[start:end] {
			h = max(h, bar.height)
		}
		h *= rect.height
	}
	y: f32 = rect.height - h + rect.y
	return {x, y, w, h}
}

track_bar_rect :: proc(sort: ^Sort, idx: int) -> rl.Rectangle {
	return eval(sort.vals[idx].rect)
}
target_bar_rect :: proc(sort: ^Sort, idx: int, frame: rl.Rectangle) -> rl.Rectangle {
	bar := sort.vals[idx]
	count := f32(len(sort.vals))
	gap_count := count - 1
	w := frame.width / (count + gap_count * BAR_GAP)
	x := w * f32(idx) * (1 + BAR_GAP) + frame.x
	h := bar.height * frame.height
	y := frame.height - h + frame.y
	return {x, y, w, h}
}

track_cursor_tip :: proc(sort: ^Sort, idx: int, space: f32 = CUSOR_SPACE) -> [2]f32 {
	r := track_bar_rect(sort, idx)
	tip: [2]f32
	tip.x = r.x + r.width / 2
	tip.y = r.y + r.height + space
	return tip
}
target_cursor_tip :: proc(
	sort: ^Sort,
	idx: int,
	frame: rl.Rectangle,
	space: f32 = CUSOR_SPACE,
) -> [2]f32 {
	r := target_bar_rect(sort, idx, frame)
	tip: [2]f32
	tip.x = r.x + r.width / 2
	tip.y = r.y + r.height + space
	return tip
}

htar :: target_bar_rect
htra :: track_bar_rect

htari :: proc(
	sort: ^Sort,
	s, e: int,
	frame: rl.Rectangle,
	t: f32,
	type: InterpolationType = DEFAULT_INTERPOLATION_TYPE,
) -> rl.Rectangle {
	return interp(htar(sort, s, frame), htar(sort, e, frame), t, type)
}
htrai :: proc(
	sort: ^Sort,
	s, e: int,
	t: f32,
	type: InterpolationType = DEFAULT_INTERPOLATION_TYPE,
) -> rl.Rectangle {
	return interp(htra(sort, s), htra(sort, e), t, type)
}

tiptar :: target_cursor_tip
tiptra :: track_cursor_tip

tiptari :: proc(
	sort: ^Sort,
	s, e: int,
	frame: rl.Rectangle,
	t: f32,
	space: f32 = CUSOR_SPACE,
	type: InterpolationType = DEFAULT_INTERPOLATION_TYPE,
) -> [2]f32 {
	return interp(tiptar(sort, s, frame, space), tiptar(sort, e, frame, space), t, type)
}
tiptrai :: proc(
	sort: ^Sort,
	s, e: int,
	t: f32,
	space: f32 = CUSOR_SPACE,
	type: InterpolationType = DEFAULT_INTERPOLATION_TYPE,
) -> [2]f32 {
	return interp(tiptra(sort, s, space), tiptra(sort, e, space), t, type)
}
