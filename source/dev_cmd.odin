package game

import "core:log"
_ :: log
import "core:slice"
import "base:intrinsics"
import "sort"

dev_cmd :: proc() {
	// when ODIN_DEBUG {
		arr := []f32{0, 10, -1, 4, 9}
		a1 := slice.clone(arr, context.temp_allocator)
		a2 := slice.clone(arr, context.temp_allocator)
		sort.merge_sort_demo(a1)
		merge_sort(a2)
		for _, i in arr {
			if a1[i] != a2[i] {
				// log.debug("found", a1[i], "expected", a2[2], "at", i)
			}
		}
	// }
}

merge_sort :: proc(array: $A/[]$T) where intrinsics.type_is_ordered(T) {
	merge :: proc(a: A, start, mid, end: int) {
		s, m := start, mid

		s2 := m + 1
		if a[m] <= a[s2] {
			return
		}

		for s <= m && s2 <= end {
			if a[s] <= a[s2] {
				s += 1
			} else {
				v := a[s2]
				i := s2

				for i != s {
					a[i] = a[i-1]
					i -= 1
				}
				a[s] = v

				s  += 1
				m  += 1
				s2 += 1
			}
		}
	}
	internal_sort :: proc(a: A, l, r: int) {
		if l < r {
			m := l + (r - l) / 2

			internal_sort(a, l, m)
			internal_sort(a, m+1, r)
			merge(a, l, m, r)
		}
	}

	internal_sort(array, 0, len(array)-1)
}