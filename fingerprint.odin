package main

import "core:slice"

Entry :: struct {
	id:   i32,
	time: i32,
}

Key :: bit_field u32 {
	dt: u32 | 14,
	f2: u32 | 9,
	f1: u32 | 9,
}

database: map[Key][dynamic]Entry

index_peaks :: proc(id: i32, peaks: []Peak) {
	for p1, i in peaks {
		for p2 in peaks[i + 1:] {
			dt := p2.time - p1.time
			if dt > 100 do break

			key := Key {
				f1 = p1.freq / 2,
				f2 = p2.freq / 2,
				dt = dt,
			}

			if key not_in database {
				database[key] = make([dynamic]Entry)
			}

			append(&database[key], Entry{id, i32(p1.time)})
		}
	}
}

Match :: struct {
	entry: Entry,
	count: u32,
}

recognize_peaks :: proc(peaks: []Peak) -> []Match {
	counts := make(map[Entry]u32)

	for p1, i in peaks {
		for p2 in peaks[i + 1:] {
			dt := p2.time - p1.time
			if dt > 100 do break

			key := Key {
				f1 = p1.freq / 2,
				f2 = p2.freq / 2,
				dt = dt,
			}

			if entries, ok := database[key]; ok {
				for e in entries {
					diff := i32(e.time) - i32(p1.time)
					counts[{e.id, diff - 1}] += 1
					counts[{e.id, diff + 0}] += 1
					counts[{e.id, diff + 1}] += 1
				}
			}
		}
	}

	matches := make([dynamic]Match)

	for match, count in counts {
		append(&matches, Match{match, count})
	}

	slice.sort_by(matches[:], proc(i, j: Match) -> bool {
		return i.count > j.count
	})

	return matches[:]
}