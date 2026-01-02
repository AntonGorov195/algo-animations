package sort

import "core:fmt"

NoSortGiven :: struct {
	message: string, // temporary
}
InvalidWindow :: struct {
	sort:    ^Sort,
	message: string, // temporary
	window:  Window,
}
IndexOutOfBound :: struct {
	sort:    ^Sort,
	message: string, // temporary
	index:   int,
	bounds:  [2]int,
}
EmptySort :: struct {
	sort:    ^Sort,
	message: string, // temporary
}
Error :: union {
	NoSortGiven,
	InvalidWindow,
	EmptySort,
	IndexOutOfBound,
}
err_msg :: proc(error: Error) -> string {
	switch err in error {
	case nil:
		return ""
	case NoSortGiven:
		return err.message
	case InvalidWindow:
		return err.message
	case EmptySort:
		return err.message
	case IndexOutOfBound:
		return err.message
	case:
		unreachable()
	}
}
err_sort :: proc(error: Error) -> ^Sort {
	switch err in error {
	case nil:
		return nil
	case NoSortGiven:
		return nil
	case InvalidWindow:
		return err.sort
	case EmptySort:
		return err.sort
	case IndexOutOfBound:
		return err.sort
	case:
		unreachable()
	}
}
validate_sort :: proc(sort: ^Sort, loc := #caller_location) -> Error {
	if sort == nil {
		return NoSortGiven{fmt.tprintfln("no sort given %v", loc)}
	}
	return nil
}
validate_sort_index :: proc(sort: ^Sort, idx: int, loc := #caller_location) -> Error {
	count := len(sort.vals)
	if idx < 0 {
		err: IndexOutOfBound
		err.sort = sort
		err.message = fmt.tprintfln("index %d %v", idx, loc)
		err.index = idx
		err.bounds = {0, count}
		return err
	}
	if idx >= count {
		err: IndexOutOfBound
		err.sort = sort
		err.message = fmt.tprintfln("index %d and count %d %v", idx, count, loc)
		err.index = idx
		err.bounds = {0, count}
		return err
	}
	return nil
}
validate_sort_window :: proc(sort: ^Sort, window: Window, loc := #caller_location) -> Error {
	if window.start > window.end {
		err: InvalidWindow
		err.message = fmt.tprintfln(
			"window.start > window.end (%d, %d) %v",
			window.start,
			window.end,
			loc,
		)
		err.window = window
		return err
	}
	return nil
}
validate_sort_has_items :: proc(sort: ^Sort, loc := #caller_location) -> Error {
	count := len(sort.vals)
	if count < 1 {
		err: EmptySort
		err.sort = sort
		err.message = fmt.tprintfln("sort must not be empty %v", loc)
		return err
	}
	return nil
}
