#+build !wasm32

package game

import os "core:os/os2"
SAVE_FILE_DIRECTORY :: "save"
SAVE_FILE_PATH :: "score.save"

save_game :: proc() -> os.Error {
	unimplemented()
	// os.make_directory_all(SAVE_FILE_DIRECTORY)
	// data, err := json.marshal(SaveData{score = g.score, solved = g.solved})
	// assert(err == nil)
	// return os.write_entire_file(SAVE_FILE_DIRECTORY + "/" + SAVE_FILE_PATH, data)
}
load_game :: proc() {
	unimplemented()
	// os.make_directory_all(SAVE_FILE_DIRECTORY)
	// byte_data, err := os.read_entire_file(
	// 	SAVE_FILE_DIRECTORY + "/" + SAVE_FILE_PATH,
	// 	context.temp_allocator,
	// )
	// if err != nil {
	// 	return
	// }
	// save: SaveData
	// err_json := json.unmarshal(byte_data, &save)
	// assert(err_json == nil)
	// g.score = save.score
	// g.solved = save.solved
}
