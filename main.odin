package main

import "core:os"
import "core:fmt"
import "core:strings"

songs: map[u32]string

main :: proc() {
	load_fingerprints()
	fmt.printfln("Indexed %v songs", len(songs))
	fmt.println("Recording for 5 seconds...\n")
	
	samples     := audio_record(5)
	spectrogram := samples_to_spectrogram(samples)
	peaks       := spectrogram_to_peaks(spectrogram)
	recognize_peaks(peaks)
}

load_fingerprints :: proc() {
	w := os.walker_create("songs")
	defer os.walker_destroy(&w)

	id := u32(0)
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

