package game

import "core:slice"
import rl "vendor:raylib"

BubbleSortState :: enum {
	Initialization,
	MoveEnd,
	Swap,
	Compare,
	MoveNext,
}
BubbleSort :: struct {
	assist_opacity:            Animated(f32),
	end_cursor:                Animated(f32),
	bubble_rect, compare_rect: Animated(rl.Rectangle),
	end, bubble, compare:      int,
	state:                     BubbleSortState,
	step_time:                 f32,
	step_dur:                  f32,
}

BUBBLE_SORT_CURSOR_SIZE :: 0.1
bubble_sort_fin_rect :: proc(vals: []BarValue, idx: int) -> rl.Rectangle {
	PADDING :: 0.03
	count := len(vals)
	w: f32
	gap_count := f32(count) - 1
	used_w: f32 = 1 - 2 * PADDING
	w = used_w / (f32(count) + gap_count * BAR_GAP)
	x: f32
	x = w * f32(idx) * (1 + BAR_GAP) + PADDING
	bar := vals[idx]
	used_h: f32 = (1 - 2 * PADDING - BUBBLE_SORT_CURSOR_SIZE)
	h := bar.height * used_h
	return {x, used_h + PADDING - h, w, h}
}
bubble_sort_target :: proc(
	algo: ^BubbleSort,
	assist_opacity: f32,
	end_cursor: f32,
	bubble_rect: rl.Rectangle,
	compare_rect: rl.Rectangle,
) {
	algo.assist_opacity.end = assist_opacity
	algo.end_cursor.end = end_cursor
	algo.bubble_rect.end = bubble_rect
	algo.compare_rect.end = compare_rect
}
bubble_sort_dur :: proc(
	algo: ^BubbleSort,
	assist_opacity: f32,
	end_cursor: f32,
	bubble_rect: f32,
	compare_rect: f32,
) {
	algo.assist_opacity.dur = assist_opacity
	algo.end_cursor.dur = end_cursor
	algo.bubble_rect.dur = bubble_rect
	algo.compare_rect.dur = compare_rect
}
bubble_sort_t :: proc(
	algo: ^BubbleSort,
	assist_opacity: f32,
	end_cursor: f32,
	bubble_rect: f32,
	compare_rect: f32,
) {
	algo.assist_opacity.t = assist_opacity
	algo.end_cursor.t = end_cursor
	algo.bubble_rect.t = bubble_rect
	algo.compare_rect.t = compare_rect
}
bubble_sort_start :: proc(algo: ^BubbleSort) {
	algo.assist_opacity.start = eval_anim(algo.assist_opacity)
	algo.end_cursor.start = eval_anim(algo.end_cursor)
	algo.bubble_rect.start = eval_anim(algo.bubble_rect)
	algo.compare_rect.start = eval_anim(algo.compare_rect)
}
bubble_sort_change_state :: proc(
	sort: ^Sort,
	algo: ^BubbleSort,
	state: BubbleSortState,
	dur: f32,
) -> (
	is_completed: bool,
) {
	for &bar, i in sort.values {
		bar.rect.start = eval_anim(bar.rect)
		bar.rect.end = bubble_sort_fin_rect(sort.values[:], i)
		bar.rect.t = 0
		bar.rect.dur = dur
	}
	algo.step_time -= algo.step_dur
	algo.step_dur = dur // dur
	algo.state = state
	bubble_sort_start(algo)
	bubble_sort_dur(algo, algo.step_dur, algo.step_dur, algo.step_dur, algo.step_dur)
	bubble_sort_t(algo, 0, 0, 0, 0)
	return algo.step_time < algo.step_dur
}
process_bubble_sort :: proc(sort: ^Sort, algo: ^BubbleSort) -> (is_completed: bool) {
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
		advance_sort(sort, &algo.end_cursor)
		advance_sort(sort, &algo.bubble_rect)
		advance_sort(sort, &algo.compare_rect)
	}
	for &bar, i in sort.values {
		bar.rect.end = bubble_sort_fin_rect(sort.values[:], i)
	}

	switch algo.state {
	case .Initialization:
		// MoveEnd, fin
		end_rect := bubble_sort_fin_rect(sort.values[:], algo.end)
		bubble_rect := bubble_sort_fin_rect(sort.values[:], algo.bubble)
		compare_rect := bubble_sort_fin_rect(sort.values[:], algo.compare)
		bubble_sort_target(
			algo,
			1,
			end_rect.x + end_rect.width / 2,
			extend_rect(bubble_rect, 0.01),
			extend_rect(compare_rect, 0.01),
		)
		if algo.step_time > algo.step_dur {
			algo.end = len(sort.values) - 1
			algo.compare += 1
			if algo.end <= 1 {
				algo.step_dur = 1
				sort.algo = nil
				for &bar in sort.values {
					bar.rect.start = eval_anim(bar.rect)
					bar.rect.t = 0
					bar.rect.dur = 1
				}
			} else {
				return bubble_sort_change_state(sort, algo, .MoveEnd, MOVE_HEAD_DUR)
			}
		}
	case .MoveEnd:
		// fin, Compare
		end_rect := bubble_sort_fin_rect(sort.values[:], algo.end)
		bubble_rect := bubble_sort_fin_rect(sort.values[:], algo.bubble)
		compare_rect := bubble_sort_fin_rect(sort.values[:], algo.compare)
		bubble_sort_target(
			algo,
			1,
			end_rect.x + end_rect.width / 2,
			extend_rect(bubble_rect, 0.01),
			extend_rect(compare_rect, 0.01),
		)
		if algo.step_time > algo.step_dur {
			if algo.end == 0 {
				algo.step_dur = 1
				sort.algo = nil
				for &bar in sort.values {
					bar.rect.start = eval_anim(bar.rect)
					bar.rect.t = 0
					bar.rect.dur = 1
				}
			} else {
			    return bubble_sort_change_state(sort, algo, .Compare, COMPARE_DUR)
            }
		}
	case .Swap:
		// MoveNext, MoveEnd
		end_rect := bubble_sort_fin_rect(sort.values[:], algo.end)
		bubble_rect := bubble_sort_fin_rect(sort.values[:], algo.bubble + 1)
		compare_rect := bubble_sort_fin_rect(sort.values[:], algo.compare - 1)
		bubble_sort_target(
			algo,
			1,
			end_rect.x + end_rect.width / 2,
			extend_rect(bubble_rect, 0.01),
			extend_rect(compare_rect, 0.01),
		)
		if algo.step_time > algo.step_dur {
			// if we swapped the end, then move
			if algo.compare == algo.end {
				algo.end -= 1
				algo.compare = 1
				algo.bubble = 0
				return bubble_sort_change_state(sort, algo, .MoveEnd, MOVE_HEAD_DUR)
			} else {
				algo.compare += 1
				algo.bubble += 1
				return bubble_sort_change_state(sort, algo, .MoveNext, MOVE_NEXT_DUR)
			}
		}
	case .Compare:
		// MoveNext, Swap, MoveEnd
		if algo.step_time > algo.step_dur {
			if sort.values[algo.bubble].value > sort.values[algo.compare].value {
				// Swap
				slice.swap(sort.values[:], algo.bubble, algo.compare)
				return bubble_sort_change_state(sort, algo, .Swap, SWAP_DUR)
			} else {
				// reached end
				if algo.compare == algo.end {
					algo.end -= 1
					algo.compare = 1
					algo.bubble = 0
					return bubble_sort_change_state(sort, algo, .MoveEnd, MOVE_HEAD_DUR)
				} else {
					// move next
					algo.compare += 1
					algo.bubble += 1
					return bubble_sort_change_state(sort, algo, .MoveNext, MOVE_NEXT_DUR)
				}
			}
		}
	case .MoveNext:
		// Compare
		end_rect := bubble_sort_fin_rect(sort.values[:], algo.end)
		bubble_rect := bubble_sort_fin_rect(sort.values[:], algo.bubble)
		compare_rect := bubble_sort_fin_rect(sort.values[:], algo.compare)
		bubble_sort_target(
			algo,
			1,
			end_rect.x + end_rect.width / 2,
			extend_rect(bubble_rect, 0.01),
			extend_rect(compare_rect, 0.01),
		)
		if algo.step_time > algo.step_dur {
			return bubble_sort_change_state(sort, algo, .Compare, COMPARE_DUR)
		}
	}
	return true
}
draw_bubble_sort :: proc(sort: ^Sort, algo: ^BubbleSort) {
	push_rect_matrix(sort.frame)
	{ 	// cursor
		CURSOR_WIDTH :: 0.1
		cursor := eval_anim(algo.end_cursor)
		draw_sort_cursor(
			extend_rect(
				{
					cursor - BUBBLE_SORT_CURSOR_SIZE / 4,
					1 - BUBBLE_SORT_CURSOR_SIZE,
					BUBBLE_SORT_CURSOR_SIZE / 2,
					BUBBLE_SORT_CURSOR_SIZE,
				},
				-0.000,
			),
			{255, 0, 0, u8(255 * eval_anim(algo.assist_opacity))},
		)
	}
	rl.DrawRectangleRec(eval_anim(algo.compare_rect), rl.ORANGE)
	rl.DrawRectangleRec(eval_anim(algo.bubble_rect), rl.RED)
	draw_bars(sort.values[:])
	pop_rect_matrix()
}
