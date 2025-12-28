package clay_short

import "vendor:clay"


fix :: proc(val: f32) -> clay.SizingAxis {
	return clay.SizingFixed(val)
}
grow :: proc(constraint: clay.SizingConstraintsMinMax = {}) -> clay.SizingAxis {
	return clay.SizingGrow(constraint)
}
fit :: proc(constraint: clay.SizingConstraintsMinMax = {}) -> clay.SizingAxis {
	return clay.SizingFit(constraint)
}
per :: proc(percent: f32) -> clay.SizingAxis {
	return clay.SizingPercent(percent)
}
id :: proc(id: string, index: int = 0) -> clay.ElementId {
	return clay.ID(id, u32(index))
}
txtcfg::proc(cfg: clay.TextElementConfig) -> ^clay.TextElementConfig {
   return clay.TextConfig(cfg)
}
padall :: proc(val: u16) -> clay.Padding {
	return clay.PaddingAll(val)
}
n2c :: proc(value: u32be) -> [4]f32 {
	value := value
	a := u8(value); value >>= 8
	b := u8(value); value >>= 8
	g := u8(value); value >>= 8
	r := u8(value); value >>= 8
	return {f32(r), f32(g), f32(b), f32(a)}
}