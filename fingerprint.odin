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
			if dt < 5 do continue
			if dt > 100 do break

			key := Key {
				f1 = p1.freq,
				f2 = p2.freq,
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
	diffs_by_song := make(map[i32][dynamic]i32)

	for p1, i in peaks {
		for p2 in peaks[i + 1:] {
			dt := p2.time - p1.time
			if dt < 5 do continue
			if dt > 100 do break

			key := Key {
				f1 = p1.freq,
				f2 = p2.freq,
				dt = dt,
			}

			entries := database[key] or_continue

			for e in entries {
				if e.id not_in diffs_by_song {
					diffs_by_song[e.id] = make([dynamic]i32)
				}

				diff := i32(e.time) - i32(p1.time)
				append(&diffs_by_song[e.id], diff)
			}
		}
	}

	matches := make([dynamic]Match)

	for song, diffs in diffs_by_song {
		slice.sort(diffs[:])

		best_count := u32(0)
		best_diff := i32(0)
		low := 0

		for high := 0; high < len(diffs); high += 1 {
			for diffs[high] - diffs[low] > 3 {
				low += 1
			}

			count := u32(high - low + 1)
			if count > best_count {
				best_count = count
				best_diff = diffs[high]
			}
		}

		append(&matches, Match{Entry{song, best_diff}, best_count})
	}

	slice.sort_by(matches[:], proc(i, j: Match) -> bool {
		return i.count > j.count
	})

	return matches[:]
}