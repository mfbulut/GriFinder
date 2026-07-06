package main

import "core:fmt"
import "core:slice"

Entry :: struct {
	id:   u32,
	time: i32,
}

Key :: bit_field u32 {
	f1: u32 | 12,
	f2: u32 | 12,
	dt: u32 | 8,
}

database: map[Key][dynamic]Entry

index_peaks :: proc(id: u32, peaks: []Peak) {
	for p1, i in peaks {
		for p2 in peaks[i + 1:] {
			dt := p2.time - p1.time
			if dt > 100 do break


			key := Key {
				f1 = p1.freq,
				f2 = p2.freq,
				dt = dt,
			}

			if key not_in database {
				database[key] = make([dynamic]Entry)
			}

			append(&database[key], Entry{id = id, time = i32(p1.time)})
		}
	}
}

recognize_peaks :: proc(peaks: []Peak) {
	candidates := make([dynamic]Entry)

	FAN_OUT :: 5
	for p1, i in peaks {
		for p2 in peaks[i + 1:] {
			dt := p2.time - p1.time
			if dt > 100 do break

			key := Key {
				f1 = p1.freq,
				f2 = p2.freq,
				dt = dt,
			}

			if entries, ok := database[key]; ok {
				for entry in entries {
					append(&candidates, Entry{
						id     = entry.id,
						time = i32(entry.time) - i32(p1.time),
					})
				}
			}
		}
	}

	slice.sort_by(candidates[:], proc(i, j: Entry) -> bool {
		if i.id != j.id do return i.id < j.id
		return i.time < j.time
	})

	best: Entry
	best_count: u32

	current: Entry
	current_count: u32

	for c in candidates {
		if current_count > 0 && c == current {
			current_count += 1
			continue
		}

		if current_count > best_count {
			best_count = current_count
			best = current
		}

		current_count = 1
		current = c
	}

	if current_count > best_count {
		best_count = current_count
		best = current
	}

	if best_count > 100 {
		seconds := best.time * HOP_SIZE / SAMPLE_RATE
		fmt.printfln("%v (at %02d:%02d) %v matches", songs[best.id], seconds / 60, seconds % 60, best_count)
	} else {
		fmt.printfln("No song is recognized")
	}
}
