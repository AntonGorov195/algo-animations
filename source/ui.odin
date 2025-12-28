package game

import "vendor:clay"

// Game UI
game_ui :: proc() {
	if clay.UI(clay.ID("WINDOW"))(ui_window()) {
		
	}
}
// Generic
ui_window :: proc() -> clay.ElementDeclaration {
	return {sizing = {clay.SizingGrow(), clay.SizingGrow()}}
}
