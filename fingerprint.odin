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

database: map[Key]Entry

index_peaks :: proc(id: u32, peaks: []Peak) {
	for p1, i in peaks {
		for p2 in peaks[i + 1:] {
			dt := p2.time - p1.time
			if dt > 100 do break

			key := Key{
				f1 = p1.freq,
				f2 = p2.freq,
				dt = dt,
			}

			database[key] = Entry{id = id, time = i32(p1.time)}
		}
	}
}

Match :: struct {
	entry: Entry,
	count: u32,
}

recognize_peaks :: proc(peaks: []Peak) -> []Match {
	candidates := make([dynamic]Entry)

	for p1, i in peaks {
		for p2 in peaks[i + 1:] {
			dt := p2.time - p1.time
			if dt > 100 do break

			key := Key{
				f1 = p1.freq,
				f2 = p2.freq,
				dt = dt,
			}

			if entry, ok := database[key]; ok {
				append(&candidates, Entry{
					id   = entry.id,
					time = i32(entry.time) - i32(p1.time),
				})
			}
		}
	}

	slice.sort_by(candidates[:], proc(i, j: Entry) -> bool {
		if i.id != j.id do return i.id < j.id
		return i.time < j.time
	})

	matches := make([dynamic]Match)

	for i := 0; i < len(candidates); {
		current := candidates[i]
		start := i

		for i < len(candidates) && candidates[i].id == current.id && candidates[i].time - current.time <= 3 {
			i += 1
		}

		count := u32(i - start)
		if count > 100 {
			append(&matches, Match{current, count})
		}
	}

	slice.sort_by(matches[:], proc(i, j: Match) -> bool {
		return i.count > j.count
	})

	return matches[:]
}
