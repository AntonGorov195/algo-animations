package game

import "core:log"
import "json"
import "vendor:clay"
_ :: clay
import R "resources"
import hm "vendor:odin-handle-map/handle_map_growing"
import rl "vendor:raylib"

@(export)
game_should_run :: proc() -> bool {
	when ODIN_OS != .JS {
		// Never run this proc in browser. It contains a 16 ms sleep on web!
		if rl.WindowShouldClose() {
			return false
		}
	}

	return g.run
}
@(export)
game_memory :: proc() -> rawptr {
	return g
}
@(export)
game_memory_size :: proc() -> int {
	return size_of(Game)
}
@(export)
game_pre_hot_reloaded :: proc() { 
	data, err := json.marshal(g.world^, allocator = a()) 
	if err != nil {
		log.logf(.Error, "game marshal error: %v", err)
	}
	g.hot_reload.hot_reload_data = data
	g.hot_reload.res_table = R.t
	g.hot_reload.marshal = json.custom_marshals
	g.hot_reload.unmarshal = json.custom_unmarshals 
	g.hot_reload.clay_ctx = clay.GetCurrentContext() 
	log.debug(string(data))
} 
@(export) 
game_post_hot_reloaded :: proc(mem: rawptr) {
	g = (^Game)(mem)
	clay.SetCurrentContext(g.hot_reload.clay_ctx) 
	clay.SetMeasureTextFunction(measure_text, nil) 
	R.t = g.hot_reload.res_table 
	json.custom_marshals = g.hot_reload.marshal
	json.custom_unmarshals = g.hot_reload.unmarshal
	g.world = new(World, a()) 
	err := json.unmarshal(g.hot_reload.hot_reload_data, g.world, allocator = a())
	if err != nil {
		log.logf(.Error, "game marshal error: %v", err)
	}
	log.info(string(g.hot_reload.hot_reload_data))
	g.hot_reload.hot_reload_data = {}
}
@(export)
game_force_reload :: proc() -> bool {
	return rl.IsKeyPressed(.F5)
}
@(export)
game_force_restart :: proc() -> bool {
	return rl.IsKeyPressed(.F6)
}
// In a web build, this is called when browser changes size. Remove the
// `rl.SetWindowSize` call if you don't want a resizable game.
game_parent_window_size_changed :: proc(w, h: int) {
	rl.SetWindowSize(i32(w), i32(h))
}
@(export)
game_update :: proc() {
	context = g.ctx
	rl.BeginDrawing()
	if rl.IsKeyPressed(.ESCAPE) {
		g.run = false
	}

	camera, letter_box_start, letter_box_end := letter_box()
	g.camera = camera
	g.letter_box_start = letter_box_start
	g.letter_box_end = letter_box_end
	rl.SetMouseOffset(-cast(i32)camera.offset.x, -cast(i32)camera.offset.y)
	rl.SetMouseScale(1 / camera.zoom, 1 / camera.zoom)

	if rl.IsKeyPressed(.K) {
		recording_toggle()
	}
	if rl.IsKeyPressed(.L) {
		replaying_toggle()
	}
	record_or_input()
	process()
	output()
	rl.EndDrawing()

	R.soft_reload_all()
	free_all(context.temp_allocator)
}
@(export)
game_start :: proc() {
	g = new(Game)
	g.run = true
	g.general_allocator = context.allocator

	_ = hm.arena_init(&g.world_recording_arena)
	_ = hm.arena_init(&g.permenant_arena)
	_ = hm.arena_init(&g.world_arena)

	add_json_marshelling()

	g.world = new(World, allocator = a())
	g.recording.inputs = make([dynamic][]u8, allocator = rec_a())
	g.sound_pool = make([dynamic]rl.Sound, allocator = perm_a())
	g.ui_fonts_by_id = make([dynamic]R.Font, allocator = perm_a())


	minMemorySize := clay.MinMemorySize()
	memory := make([^]u8, minMemorySize, allocator = perm_a())
	arena: clay.Arena = clay.CreateArenaWithCapacityAndMemory(cast(uint)minMemorySize, memory)
	clay.Initialize(
		arena,
		{SCREEN_WIDTH, SCREEN_HEIGHT},
		{handler = errorHandler},
	)
	clay.SetMeasureTextFunction(measure_text, nil)
	clay.SetLayoutDimensions({SCREEN_WIDTH, SCREEN_HEIGHT})

	rl.SetConfigFlags(WINDOW_CONFIG_FLAGS)
	rl.InitWindow(SCREEN_WIDTH, SCREEN_HEIGHT, WINDOW_NAME)
	rl.SetExitKey(nil)
	rl.InitAudioDevice()

	_ = R.start(g.general_allocator)
	context.allocator = a()
	g.ctx = context
	start()
}
@(export)
game_end :: proc() {
	context = g.ctx
	end()
	for alias in g.sound_pool {
		rl.UnloadSoundAlias(alias)
	}
	hm.arena_free_all(&g.world_recording_arena)
	hm.arena_free_all(&g.world_arena)
	hm.arena_free_all(&g.permenant_arena)

	context.allocator = g.general_allocator
	R.end()
	free(g)
	rl.CloseAudioDevice()
	rl.CloseWindow()
}
