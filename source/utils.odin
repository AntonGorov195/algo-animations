package game

import "core:math"
import "core:math/rand"
import "core:mem"
import "json"
import R "resources"
import "vendor:clay"
import hm "vendor:odin-handle-map/handle_map_growing"
import rl "vendor:raylib"

@(require_results)
read_entire_file :: proc(
	name: string,
	allocator := context.allocator,
	loc := #caller_location,
) -> (
	data: []byte,
	success: bool,
) {
	return _read_entire_file(name, allocator, loc)
}

write_entire_file :: proc(name: string, data: []byte, truncate := true) -> (success: bool) {
	return _write_entire_file(name, data, truncate)
}
rl_screen2world :: proc(v: [2]f32) -> [2]f32 {
	real_screen_width := f32(rl.GetScreenWidth())
	real_screen_height := f32(rl.GetScreenHeight())
	real_aspect_ration := real_screen_width / real_screen_height

	if real_aspect_ration >= SCREEN_ASPECT_RATIO { 	// wider
		zoom := real_screen_height / SCREEN_HEIGHT
		width := SCREEN_WIDTH * zoom
		offset_x := (real_screen_width - width) / 2

		out := v
		out.x -= offset_x
		out /= zoom
		return out
	} else if real_aspect_ration < SCREEN_ASPECT_RATIO { 	// taller
		zoom := real_screen_width / SCREEN_WIDTH
		height := SCREEN_HEIGHT * zoom
		offset_y := (real_screen_height - height) / 2

		out := v
		out.y -= offset_y
		out /= zoom
		return out
	}
	return {}
}
a :: proc() -> mem.Allocator {
	return hm.arena_allocator(&g.world_arena)
}
perm_a :: proc() -> mem.Allocator {
	return hm.arena_allocator(&g.permenant_arena)
}
rec_a :: proc() -> mem.Allocator {
	return hm.arena_allocator(&g.world_recording_arena)
}
add_json_marshelling :: proc() {

}
play_sound :: proc(sound: R.Sound) -> rl.Sound {
	sound := R.get(sound)
	alias := rl.LoadSoundAlias(sound)
	rl.PlaySound(alias)
	append(&g.sound_pool, alias)
	return alias
}
clean_sound_pool :: proc() {
	pool := &g.sound_pool
	i: int
	for i < len(pool) {
		if !rl.IsSoundPlaying(pool[i]) {
			rl.UnloadSoundAlias(pool[i])
			unordered_remove(pool, i)
			continue
		}
		i += 1
	}
}
HotReloadGlobals :: struct {
	hot_reload_data: []u8,
	res_table:       ^R.Table,
	marshal:         [dynamic]json.Custom_Marshal,
	unmarshal:       [dynamic]json.Custom_Unmarshal,
	clay_ctx:        ^clay.Context,
}
IntepolationType :: enum {
	Linear, // default
	Quad,
	Cubic,
	Root2,
	Root3,
	SmoothStep3,
	SmoothStep5,
}
IT :: IntepolationType
inter_values_array :: proc(
	start: $T/[$N]f32,
	end: T,
	t: f32,
	type: IntepolationType = .Linear,
) -> T {
	t_inter := interp01(t, type)
	return start * (1 - t_inter) + end * t_inter
}
inter_values :: proc(start: f32, end: f32, t: f32, type: IntepolationType = .Linear) -> f32 {
	t_inter := interp01(t, type)
	return start * (1 - t_inter) + end * t_inter
}
interp01 :: proc(t: f32, type: IntepolationType = .Linear) -> f32 {
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
	inter_values,
	inter_values_array,
}
// [min, max)
rand_range :: proc(min, max: int, rng := context.random_generator) -> int {
	assert(min <= max)
	if min == max {
		return min
	}
	return rand.int_max(max - min, rng) + min
}