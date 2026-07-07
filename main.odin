package main

import "core:fmt"
import "core:os"
import "core:strings"

songs: map[i32]string

main :: proc() {
	index_songs()
	fmt.printfln("Indexed %v songs", len(songs))
	fmt.println("Recording for 5 seconds...\n")

	samples := audio_record(5)
	spectrogram := samples_to_spectrogram(samples)
	peaks := spectrogram_to_peaks(spectrogram)
	matches := recognize_peaks(peaks)

	fmt.println("Top matches:")
	for m, i in matches {
		if i >= 10 do continue
		seconds := m.entry.time * HOP_SIZE / SAMPLE_RATE
		fmt.printfln(
			"%v (at %02d:%02d) %v matches",
			songs[m.entry.id],
			seconds / 60,
			seconds % 60,
			m.count,
		)
	}
}

index_songs :: proc() {
	w := os.walker_create("songs")
	defer os.walker_destroy(&w)

	id := i32(1)
	for info in os.walker_walk(&w) {
		songs[id] = strings.clone(info.name)
		samples := audio_decode(info.fullpath)
		spectrogram := samples_to_spectrogram(samples)
		peaks := spectrogram_to_peaks(spectrogram)
		index_peaks(id, peaks)
		fmt.println("Indexed:", info.name)
		id += 1
	}
}
