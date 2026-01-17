// inotifywait -m -r -e modify,create,delete ./source | while read path action file; do     ./build_hot_reload.sh; done
package game

import "base:runtime"
import "core:mem"
import R "resources"
import "sort"
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
	start_merge_sort:     bool,
	start_super_sort:     bool,
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
	input:          Input,
	time:           f32,
	font:           R.Font,
	font_mono:      R.Font,
	font_ui:        u16,
	font_mono_ui:   u16,
	bubble_texture: R.Texture,
	insert_texture: R.Texture,
	quick_texture:  R.Texture,
	merge_texture:  R.Texture,
	sorts:          [dynamic]sort.Sort,
	speed:          f32,
	is_sorting:     bool,
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
	append(&g.sorts, create_sort())
	append(&g.sorts, create_sort())
	append(&g.sorts, create_sort())
	append(&g.sorts, create_sort())
	g.sorts[0].frame = exd(rl.Rectangle{0, 0, SCREEN_WIDTH / 2, SCREEN_HEIGHT / 2}, -10)
	g.sorts[1].frame = exd(
		rl.Rectangle{SCREEN_WIDTH / 2, 0, SCREEN_WIDTH / 2, SCREEN_HEIGHT / 2},
		-10,
	)
	g.sorts[2].frame = exd(
		rl.Rectangle{0, SCREEN_HEIGHT / 2, SCREEN_WIDTH / 2, SCREEN_HEIGHT / 2},
		-10,
	)
	g.sorts[3].frame = exd(
		rl.Rectangle{SCREEN_WIDTH / 2, SCREEN_HEIGHT / 2, SCREEN_WIDTH / 2, SCREEN_HEIGHT / 2},
		-10,
	)
	g.bubble_texture = R.load_texture("bubble.png")
	g.insert_texture = R.load_texture("insert.png")
	g.quick_texture = R.load_texture("quick.png")
	g.merge_texture = R.load_texture("merge.png")
	// append(&g.sorts, create_sort())
	// g.sorts[0].frame = exd(rl.Rectangle{0, 0, SCREEN_WIDTH / 2, SCREEN_HEIGHT}, -10)
	// g.sorts[1].frame = exd(rl.Rectangle{SCREEN_WIDTH / 2, 0, SCREEN_WIDTH / 2, SCREEN_HEIGHT}, -10)
}
end :: proc() {
	// Freeing memory will be done in "game_end".
	// Here is for logic only.
}
create_sort :: proc() -> sort.Sort {
	COUNT :: 64
	s: sort.Sort
	s.frame = exd(rl.Rectangle{0, 0, SCREEN_WIDTH / 2, SCREEN_HEIGHT}, -0)
	for i in 0 ..< COUNT {
		w := sort.calc_bar_width(COUNT)
		x := sort.rect_end_pos_x(COUNT, i)
		h := f32(1)
		// h := f32(i + 1) / COUNT
		rect := sort.Animated(rl.Rectangle) {
			start = rl.Rectangle{x, 1 - h, w, h},
			end   = rl.Rectangle{x, 1 - h, w, h},
		}
		bar := sort.BarValue {
			value      = f32(i),
			height     = h,
			rect       = rect,
			real_place = i,
		}
		append(&s.vals, bar)
	}
	return s
}
