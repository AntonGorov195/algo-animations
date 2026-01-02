// inotifywait -m -r -e modify,create,delete ./source | while read path action file; do     ./build_hot_reload.sh; done
package game

import "base:runtime"
import "core:mem"
import R "resources"
import "vendor:clay"
import hm "vendor:odin-handle-map/handle_map_growing"
import rl "vendor:raylib"

SIM_WINDOW :: [2]f32{1100, 800}

CONST_FPS :: 60.
SCREEN_WIDTH :: 1200.
SCREEN_HEIGHT :: 900.
SCREEN_ASPECT_RATIO :: SCREEN_WIDTH / SCREEN_HEIGHT
WINDOW_NAME :: "Algos"
WINDOW_CONFIG_FLAGS :: rl.ConfigFlags{.WINDOW_RESIZABLE, .VSYNC_HINT}

Input :: struct {
	dt:                   f32,
	mouse_pos:            [2]f32,
	click:                bool,
	randomize:            bool,
	start_insertion_sort: bool,
	start_bubble_sort:    bool,
	start_quick_sort:     bool,
	// pause_sort:       bool,
	process_rng_seed:     u64,
	output_rng_seed:      u64,
}
Game :: struct {
	using world:           ^World,
	run:                   bool,
	hot_reload:            HotReloadGlobals,
	recording:             Recording,
	world_arena:           hm.Arena,
	world_recording_arena: hm.Arena,
	permenant_arena:       hm.Arena,
	general_allocator:     mem.Allocator,
	sound_pool:            [dynamic]rl.Sound,
	ui_fonts_by_id:        [dynamic]R.Font,
	ctx:                   runtime.Context,
	// Temporaries
	ui_cmds:               clay.ClayArray(clay.RenderCommand),
	camera:                rl.Camera2D,
	letter_box_start:      rl.Rectangle,
	letter_box_end:        rl.Rectangle,
	render_texture:        rl.RenderTexture,
}
World :: struct {
	// Add stuff here for hot reloading to work
	input:        Input,
	time:         f32,
	font:         R.Font,
	font_mono:    R.Font,
	font_ui:      u16,
	font_mono_ui: u16,
	main_sort:    Sort,
	speed:        f32,
	is_sorting:   bool,
}
g: ^Game
start :: proc() {
	when ODIN_OS != .JS {
		rl.HideCursor()
		rl.SetTargetFPS(CONST_FPS)
	}
	g.font = R.load_font("Calistoga-Regular.ttf")
	g.font_mono = R.load_font("dejavu-sans-mono.book.ttf")
	_ = ui_add_font(0)
	g.font_ui = ui_add_font(g.font)
	g.font_mono_ui = ui_add_font(g.font_mono)
	COUNT :: 16
	g.main_sort.frame = exd(rl.Rectangle{0, 0, SCREEN_WIDTH, SCREEN_HEIGHT}, -0)
	for i in 0 ..< COUNT {
		w := calc_bar_width(COUNT)
		x := rect_end_pos_x(COUNT, i)
		h := f32(i + 1) / COUNT
		rect := Animated(rl.Rectangle) {
			start = rl.Rectangle{x, 1 - h, w, h},
			end   = rl.Rectangle{x, 1 - h, w, h},
		}
		bar := BarValue {
			value      = f32(i),
			height     = h,
			rect       = rect,
			real_place = i,
		}
		append(&g.main_sort.vals, bar)
	}
}
end :: proc() {
	// Freeing memory will be done in "game_end".
	// Here is for logic only.
}
Animated :: struct($T: typeid) {
	type:  IntepolationType,
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
	type: IntepolationType,
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
rect_end_pos_x :: proc(count: int, index: int) -> f32 {
	w := calc_bar_width(count)
	return w * f32(index) * (1 + BAR_GAP)
}
