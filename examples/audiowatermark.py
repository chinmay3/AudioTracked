import sys
from pathlib import Path

sys.path.append(str(Path(__file__).resolve().parents[1]))
from utils import audio_watermark, extract_audio_watermark

small_audio_bits = audio_watermark("radiohead.wav", "creep.wav")
extract_audio_watermark("waudio.wav", small_audio_bits)
