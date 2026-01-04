package sort

import "core:math"
import rl "vendor:raylib"

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
		_ = interp(val, val, f32(0), InterpolationType.Linear)
	}
	return {start = val, end = val}
}
eval :: proc(val: Animated($T)) -> T {
	return interp(val.start, val.end, val.t, val.type)
}
retarget :: proc(val: ^Animated($T), target: T, type: InterpolationType, dur: f32) -> Animated(T) {
	val^ = {
		type  = type,
		t     = 0,
		dur   = dur,
		start = eval(val^),
		end   = target,
	}
	return val^
}
track_timing :: proc(target: ^Animated($T), tracker: ^Animated($U)) {
	tracker.type = target.type
	tracker.t = target.t
	tracker.dur = target.dur
}
go_after :: proc(dst: ^Animated($T), src: ^Animated(T)) {
	dst^ = {
		type  = src.type,
		t     = src.t,
		dur   = src.dur,
		start = dst.start,
		end   = src.end,
	}
}
interp_rect :: proc(
	start: rl.Rectangle,
	end: rl.Rectangle,
	t: f32,
	type: InterpolationType,
) -> rl.Rectangle {
	// t_inter := interp01(t, type)
	return {
		interp(start.x, end.x, t, type),
		interp(start.y, end.y, t, type),
		interp(start.width, end.width, t, type),
		interp(start.height, end.height, t, type),
	}
}
interp_color :: proc(start: rl.Color, end: rl.Color, t: f32, type: InterpolationType) -> rl.Color {
	// t_inter := interp01(t, type)
	return {
		u8(interp(f32(start.r), f32(end.r), t, type)),
		u8(interp(f32(start.g), f32(end.g), t, type)),
		u8(interp(f32(start.b), f32(end.b), t, type)),
		u8(interp(f32(start.a), f32(end.a), t, type)),
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
interp_values :: proc(start: f32, end: f32, t: f32, type: InterpolationType) -> f32 {
	t_inter := interp01(t, type)
	return start * (1 - t_inter) + end * t_inter
}
interp01 :: proc(t: f32, type: InterpolationType) -> f32 {
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
	case .JumpQuad:
		return -4 * t * (t - 1)
	}
	unreachable()
}
interp :: proc {
	interp01,
	interp_values,
	interp_values_array,
	interp_rect,
	interp_color,
}
InterpolationType :: enum {
	Linear, // default
	Quad,
	Cubic,
	Root2,
	Root3,
	SmoothStep3,
	SmoothStep5,
	JumpQuad,
}
