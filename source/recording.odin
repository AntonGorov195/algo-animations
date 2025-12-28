package game

import "json"
import "core:log"

Recording :: struct {
	state:  enum {
		Normal,
		Record,
		Replay,
	},
	paused: bool,
	frame:  int,
	inputs: [dynamic][]u8,
	game:   []u8,
}
recording_toggle :: proc() {
	switch g.recording.state {
	case .Normal:
		free_all(rec_a())
		g.recording.inputs = make([dynamic][]u8, rec_a())
		g.recording.state = .Record
		val, err := json.marshal(g.world^, allocator = rec_a())
		if err != nil {
			log.error(err)
		}
		g.recording.game = val
	case .Record:
		g.recording.state = .Normal
	case .Replay:
		g.recording.state = .Record
		resize(&g.recording.inputs, g.recording.frame)
	}
}
replaying_toggle :: proc() {
	switch g.recording.state {
	case .Normal:
		if len(g.recording.inputs) > 0 {
			g.recording.frame = 0
			g.recording.state = .Replay
		} else {
			log.logf(.Warning, "trying to switch to replay mode from normal without recording.")
		}
	case .Record:
		g.recording.frame = 0
		g.recording.state = .Replay
	case .Replay:
		g.recording.state = .Normal
	}
}
record_or_input :: proc() {
	switch g.recording.state {
	case .Normal:
		input()
	case .Record:
		input()
		val, err := json.marshal(g.input, allocator = rec_a())
		if err != nil {
			log.error(err)
		}
		append(&g.recording.inputs, val)
	case .Replay:
		assert(len(g.recording.inputs) > 0)
		g.recording.frame %= len(g.recording.inputs)
		if g.recording.frame == 0 {
			free_all(a())
			g.world = new(World, a())
			err := json.unmarshal(g.recording.game, g.world, allocator = a())
			if err != nil {
				log.error(err)
			}
		}
		err := json.unmarshal(g.recording.inputs[g.recording.frame], &g.input, allocator = a())
		if err != nil {
			log.error(err)
		}
		g.recording.frame += 1
	}
}
