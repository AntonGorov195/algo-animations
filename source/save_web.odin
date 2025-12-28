#+build wasm32

package game

// import "core:fmt"
// import "core:log"
// import "core:strconv"
import "json"
import "core:os"
SAVE_FILE_PATH :: "score"

save_game :: proc() -> os.Error {
	data, err := json.marshal(SaveData{score = g.score, solved = g.solved})
	assert(err == nil)
	local_storage_set(
		SAVE_FILE_PATH,
		string(data),
	)
	return nil
}
load_game :: proc() {
	data := local_storage_get(SAVE_FILE_PATH)
	if data == "" {
		return
	}
	save: SaveData
	err_json := json.unmarshal(transmute([]u8)(data), &save)
	assert(err_json == nil)
	g.score = save.score
	g.solved = save.solved
}
