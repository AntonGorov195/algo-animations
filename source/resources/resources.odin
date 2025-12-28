package resources

import "base:runtime"
import "core:fmt"
import "core:path/filepath"
import "core:strings"
import "core:time"
import rl "vendor:raylib"

Texture :: distinct int
Sound :: distinct int
Music :: distinct int
Font :: distinct int
TextureAsset :: struct {
	path:        string,
	value:       rl.Texture,
	last_update: time.Time,
}
SoundAsset :: struct {
	path:        string,
	value:       rl.Sound,
	last_update: time.Time,
}
MusicAsset :: struct {
	path:        string,
	value:       rl.Music,
	last_update: time.Time,
}
FontAsset :: struct {
	path:        string,
	value:       rl.Font,
	last_update: time.Time,
}
Table :: struct {
	textures:  [dynamic]TextureAsset,
	sounds:    [dynamic]SoundAsset,
	music:     [dynamic]MusicAsset,
	fonts:     [dynamic]FontAsset,
	allocator: runtime.Allocator,
}
t: ^Table

FILE_SEP :: filepath.SEPARATOR_STRING
ASSET_FOLDER :: "assets"
TEXTURE_FOLDER :: ASSET_FOLDER + FILE_SEP + "textures"
SOUNDS_FOLDER :: ASSET_FOLDER + FILE_SEP + "sounds"
MUSIC_FOLDER :: ASSET_FOLDER + FILE_SEP + "music"
FONT_FOLDER :: ASSET_FOLDER + FILE_SEP + "fonts"

start :: proc(allocator := context.allocator) -> ^Table {
	t = new(Table)
	t.allocator = allocator
	t.textures = make([dynamic]TextureAsset, allocator = t.allocator)
	t.sounds = make([dynamic]SoundAsset, allocator = t.allocator)
	t.music = make([dynamic]MusicAsset, allocator = t.allocator)
	t.fonts = make([dynamic]FontAsset, allocator = t.allocator)
	append(
		&t.textures,
		TextureAsset {
			// ZII
			// Get a default error texture in here.
			value = rl.LoadTexture(TEXTURE_FOLDER + FILE_SEP + "err.png"),
		},
	)
	append(
		&t.sounds,
		SoundAsset {
			// ZII
			// Get a default error texture in here.
		},
	)
	append(
		&t.music,
		MusicAsset {
			// ZII
			// Get a default error texture in here.
		},
	)
	append(
		&t.fonts,
		FontAsset {
			// ZII
			// Get a default error texture in here.
			value = rl.GetFontDefault(),
		},
	)
	return t
}
end :: proc() {
	for texture in t.textures {
		rl.UnloadTexture(texture.value)
		delete(texture.path, t.allocator)
	}
	delete(t.textures)
	for sound in t.sounds {
		rl.UnloadSound(sound.value)
		delete(sound.path, t.allocator)
	}
	delete(t.sounds)
	for music in t.music {
		rl.UnloadMusicStream(music.value)
		delete(music.path, t.allocator)
	}
	delete(t.music)
	for font in t.fonts {
		rl.UnloadFont(font.value)
		delete(font.path, t.allocator)
	}
	delete(t.fonts)
	free(t)
}

load_texture :: proc(path: string) -> Texture {
	result: TextureAsset
	result.path = strings.concatenate({TEXTURE_FOLDER, FILE_SEP, path}, t.allocator)
	cpath := fmt.ctprint(result.path)
	when ODIN_OS != .JS {
		result.last_update = time.from_nanoseconds(rl.GetFileModTime(cpath))
	}
	result.value = rl.LoadTexture(cpath)
	append(&t.textures, result)
	return Texture(len(t.textures) - 1)
}
get_texture :: proc(id: Texture) -> rl.Texture {
	return t.textures[int(id)].value
}
get_texture_asset :: proc(id: Texture) -> ^TextureAsset {
	return &t.textures[int(id)]
}
load_sound :: proc(path: string) -> Sound {
	result: SoundAsset
	result.path = strings.concatenate({SOUNDS_FOLDER, FILE_SEP, path}, t.allocator)
	cpath := fmt.ctprint(result.path)
	when ODIN_OS != .JS {
		result.last_update = time.from_nanoseconds(rl.GetFileModTime(cpath))
	}
	result.value = rl.LoadSound(cpath)
	append(&t.sounds, result)
	return Sound(len(t.sounds) - 1)
}
get_sound :: proc(id: Sound) -> rl.Sound {
	return t.sounds[int(id)].value
}
get_sound_asset :: proc(id: Sound) -> ^SoundAsset {
	return &t.sounds[int(id)]
}
load_music :: proc(path: string) -> Music {
	result: MusicAsset
	result.path = strings.concatenate(
		{MUSIC_FOLDER, FILE_SEP, path, "\x00"},
		allocator = t.allocator,
	)
	result.path = result.path[:len(result.path) - 1]
	cpath := strings.unsafe_string_to_cstring(result.path)
	when ODIN_OS != .JS {
		result.last_update = time.from_nanoseconds(rl.GetFileModTime(cpath))
	}
	result.value = rl.LoadMusicStream(cpath)
	append(&t.music, result)
	return Music(len(t.music) - 1)
}
get_music :: proc(id: Music) -> rl.Music {
	return t.music[int(id)].value
}
get_music_asset :: proc(id: Music) -> ^MusicAsset {
	return &t.music[int(id)]
}
load_font :: proc(path: string) -> Font {
	result: FontAsset
	result.path = strings.concatenate(
		{FONT_FOLDER, FILE_SEP, path, "\x00"},
		allocator = t.allocator,
	)
	result.path = result.path[:len(result.path) - 1]
	cpath := strings.unsafe_string_to_cstring(result.path)
	when ODIN_OS != .JS {
		result.last_update = time.from_nanoseconds(rl.GetFileModTime(cpath))
	}
	result.value = rl.LoadFontEx(cpath, 64, nil, 0)
	rl.SetTextureFilter(result.value.texture, rl.TextureFilter.BILINEAR)
	append(&t.fonts, result)
	return Font(len(t.fonts) - 1)
}
get_font :: proc(id: Font) -> rl.Font {
	return t.fonts[int(id)].value
}
get_font_asset :: proc(id: Font) -> ^FontAsset {
	return &t.fonts[int(id)]
}

get :: proc {
	get_texture,
	get_sound,
	get_music,
	get_font,
}
get_asset :: proc {
	get_texture_asset,
	get_sound_asset,
	get_music_asset,
	get_font_asset,
}
soft_reload_all :: proc() {
	when ODIN_OS == .JS {
		return
	} else {
		for &texture in t.textures {
			cpath := fmt.ctprint(texture.path)
			l := rl.GetFileModTime(cpath)
			if texture.last_update._nsec < l {
				rl.UnloadTexture(texture.value)
				texture.value = rl.LoadTexture(cpath)
				texture.last_update = time.from_nanoseconds(l)
			}
		}
		for &fonts in t.fonts {
			cpath := fmt.ctprint(fonts.path)
			l := rl.GetFileModTime(cpath)
			if fonts.last_update._nsec < l {
				rl.UnloadFont(fonts.value)
				fonts.value = rl.LoadFontEx(cpath, 32, nil, 0)
				fonts.last_update = time.from_nanoseconds(l)
			}
		}
	}
}
