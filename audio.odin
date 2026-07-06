package main

import "base:runtime"

import "core:os"
import "core:fmt"
import "core:time"
import "core:slice"

import ma "vendor:miniaudio"

SAMPLE_RATE :: 12000

audio_decode :: proc(filename: string) -> []f32 {
    decoder: ma.decoder
    config := ma.decoder_config_init(.f32, 1, SAMPLE_RATE)

    data, err := os.read_entire_file(filename, context.allocator)

    if err != nil {
        fmt.eprintln("Failed to read file", err)
        return nil
    }

    if ma.decoder_init_memory(raw_data(data), len(data), &config, &decoder) != .SUCCESS {
        fmt.eprintln("Failed to decode audio file:", filename)
        return nil
    }

    frame_count: u64
    ma.decoder_get_length_in_pcm_frames(&decoder, &frame_count)

    samples := make([]f32, frame_count)
    ma.decoder_read_pcm_frames(&decoder, raw_data(samples), frame_count, nil)
    ma.decoder_uninit(&decoder)
    return samples
}

mic_buffer: [dynamic]f32

mic_callback :: proc "c" (device: ^ma.device, output, input: rawptr, frame_count: u32) {
    context = runtime.default_context()
    samples := slice.from_ptr((^f32)(input), int(frame_count))
    append(&mic_buffer, ..samples)
}

audio_record :: proc(seconds: time.Duration) -> []f32 {
    config := ma.device_config_init(.capture)
    config.dataCallback = mic_callback
    config.capture.format = .f32
    config.capture.channels = 1
    config.sampleRate = SAMPLE_RATE

    device: ma.device
    if ma.device_init(nil, &config, &device) != .SUCCESS {
        panic("Failed to init microphone device")
    }

    ma.device_start(&device)
    time.sleep(seconds * time.Second)
    ma.device_uninit(&device);

    res := mic_buffer[:]
    return res
}