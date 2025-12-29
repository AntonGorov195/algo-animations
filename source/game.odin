// inotifywait -m -r -e modify,create,delete ./source | while read path action file; do     ./build_hot_reload.sh; done
package game

import "base:runtime"
import "core:mem"
import R "resources"
import "vendor:clay"
import hm "vendor:odin-handle-map/handle_map_growing"
import rl "vendor:raylib"

SIM_WINDOW :: [2]f32{400, 400}

CONST_FPS :: 60.
SCREEN_WIDTH :: 1200.
SCREEN_HEIGHT :: 900.
SCREEN_ASPECT_RATIO :: SCREEN_WIDTH / SCREEN_HEIGHT
WINDOW_NAME :: "Algos"
WINDOW_CONFIG_FLAGS :: rl.ConfigFlags{.WINDOW_RESIZABLE, .VSYNC_HINT}

Input :: struct {
	dt:               f32,
	mouse_pos:        [2]f32,
	click:            bool,
	randomize:        bool,
	start_sort:       bool,
	pause_sort:       bool,
	process_rng_seed: u64,
	output_rng_seed:  u64,
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
	// Game world
}
InsersionSortState :: enum {
	Initialization,
	MoveHead,
	Swap,
	Compare,
	MoveNext,
}
// insert_sort_anim := [InsersionSortState]AnimationData {
// 	.Initialization = {dur = 1, type = .SmoothStep3},
// 	.MoveHead = {dur = 1, type = .SmoothStep3},
// 	.Swap = {dur = 1, type = .SmoothStep3},
// 	.Compare = {dur = 1, type = .SmoothStep3},
// 	.MoveNext = {dur = 1, type = .SmoothStep3},
// }
InsersionSort :: struct {
	// head, insert, compare:             AnimatedFloat,
	assist_opacity:            Animated(f32),
	head_cursor:               Animated(f32),
	insert_rect, compare_rect: Animated(rl.Rectangle),
	head, insert, compare:     int,
	state:                     InsersionSortState,
	step_t:                    f32,
	step_dur:                  f32,
}
Randomize :: struct {}
Simulation :: union #no_nil {
	Randomize,
	InsersionSort,
}
World :: struct {
	// Add stuff here for hot reloading to work
	input:        Input,
	time:         f32,
	font:         R.Font,
	font_mono:    R.Font,
	font_ui:      u16,
	font_mono_ui: u16,
	sort:         Simulation,
	speed:        f32,
	is_sorting:   bool,
	values:       [dynamic]BarValue,
	sim_window:   rl.Rectangle,
}
BarValue :: struct {
	value: f32,
	rect:  Animated(rl.Rectangle), // animated index
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
	COUNT :: 5
	// insort: InsersionSort
	for i in 0 ..< COUNT {
		w := calc_bar_width(COUNT)
		x := rect_end_pos_x(COUNT, i)
		h := f32(i + 1) / COUNT
		bar := BarValue {
			value = f32(i),
			rect  = to_anim(rl.Rectangle{x, 1 - h, w, h}),
		}
		append(&g.values, bar)
	}
	// g.sim = insort
	// g.sim_window = {0, 0, 400, 300}
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
eval_anim :: proc(val: Animated($T)) -> T {
	return interp(val.start, val.end, val.t, val.type)
}
anim_change_target :: proc(
	val: Animated($T),
	target: T,
	type: IntepolationType,
	dur: f32,
) -> Animated(T) {
	return {type = type, t = 0, dur = dur, start = eval_anim(val), end = target}
}
rect_end_pos_x :: proc(count: int, index: int) -> f32 {
	w := calc_bar_width(count)
	return w * f32(index) * (1 + BAR_GAP)
}
