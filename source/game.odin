// inotifywait -m -r -e modify,create,delete ./source | while read path action file; do     ./build_hot_reload.sh; done
package game

import "base:runtime"
import "core:mem"
import R "resources"
import "vendor:clay"
import hm "vendor:odin-handle-map/handle_map_growing"
import rl "vendor:raylib"

InsertionSortData :: struct {
	bar_component_height:  f32, // [0, 1]
	cursor_component_size: f32, // [0, 1]
	initialization:        AnimationData,
	move_head:             AnimationData,
}
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
InsersionSort :: struct {
	head, insert, compare:             AnimatedFloat,
	head_idx, insert_idx, compare_idx: int,
	state:                             enum {
		Initialization,
		MoveHead,
		Swap,
		Compare,
	},
	step_t:                            f32,
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
	sim:          Simulation,
	speed:        f32,
	is_sorting:   bool,
	values:       [dynamic]BarValue,
	sim_window:   rl.Rectangle,
}
AnimationData :: struct {
	dur:  f32,
	type: IntepolationType,
}
AnimatedFloat :: struct {
	t:          f32,
	start, end: f32, // instead of index, use this to interpolate
}
BarValue :: struct {
	value:  f32,
	height: f32, // [0, 1]
	pos:    AnimatedFloat, // animated index
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
		bar := BarValue {
			value = f32(i),
			height = f32(i + 1) / COUNT,
			pos = {start = f32(i), end = f32(i)},
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
