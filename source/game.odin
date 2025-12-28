// inotifywait -m -r -e modify,create,delete ./source | while read path action file; do     ./build_hot_reload.sh; done
package game

import "base:runtime"
import "core:mem"
import R "resources"
import "vendor:clay"
import hm "vendor:odin-handle-map/handle_map_growing"
import rl "vendor:raylib"

// use g.input.dt for portability
CONST_FPS :: 60.

UPGRADE_BUTTON_ID :: "UPGRADE"
CONTINUE_BUTTON_ID :: "CONTINUE"
BACK_TO_START_BUTTON_ID :: "BACK_TO_START"
PAUSE_BUTTON_ID :: "PAUSE"
START_GAME_BUTTON_ID :: "BUTTON"
HELLO_BUTTON_ID :: "HELLO"
GAME_BOTTOM_BAR_HEIGHT :: 120
PROBLEM_SPREAD :: 300.
PROBLEM_HEIGHT :: 60.
PROBLEM_FALL_SPEED :: 70.
PROBLEM_COOLDONW :: 1.2
BUTTON_COLOR :: [?]f32{200, 200, 200, 255}
BUTTON_HOVERED_COLOR :: [?]f32{235, 235, 235, 255}
COMBO_DURATION :: 4.5
#assert(COMBO_DURATION > 0)

IMAGE_DUR :: 3
CURSOR_LINE_COUNT :: 5
PIXEL_WINDOW_HEIGHT :: 180
SCREEN_WIDTH :: 1200.
SCREEN_HEIGHT :: 900.
INIT_SCREEN_WIDTH :: SCREEN_WIDTH
INIT_SCREEN_HEIGHT :: SCREEN_HEIGHT
INIT_WINDOW_NAME :: "Algos"
INIT_CONFIG_FLAGS :: rl.ConfigFlags{.WINDOW_RESIZABLE, .VSYNC_HINT}
SCREEN_ASPECT_RATIO :: SCREEN_WIDTH / SCREEN_HEIGHT

Input :: struct {
	dt:               f32,
	mouse_pos:        [2]f32,
	click:            bool,
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
World :: struct {
	// Add stuff here for hot reloading to work
	input:         Input,
	state:         WorldState,
	time:          f32,
	font:          R.Font,
	font_mono:     R.Font,
	font_ui:       u16,
	font_mono_ui:  u16,
}
WorldState :: enum {
	Game,
	Paused,
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
	load_game()
}
end :: proc() {
	// Freeing memory will be done in "game_end".
	// Here is for logic only.
}
