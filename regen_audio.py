import wave
import math
import struct
import os

def generate_tone(filename, duration=0.2, freq=440, volume=0.5):
    sample_rate = 44100
    n_frames = int(duration * sample_rate)
    data = []
    for i in range(n_frames):
        t = i / sample_rate
        value = int(volume * 32767.0 * math.sin(2.0 * math.pi * freq * t))
        data.append(struct.pack('<h', value))
    
    with wave.open(filename, 'w') as f:
        f.setnchannels(1)
        f.setsampwidth(2)
        f.setframerate(sample_rate)
        f.writeframes(b''.join(data))
    print(f"Generated {filename}")

if __name__ == "__main__":
    generate_tone('mobile/assets/audio/sfx/click.wav', 0.1, 1200)
    generate_tone('mobile/assets/audio/sfx/success.wav', 0.4, 554)
    # Generate 1 sec of silence for music to stop errors if file missing
    generate_tone('mobile/assets/audio/music/cozy_lofi.wav', 1.0, 0, 0)
