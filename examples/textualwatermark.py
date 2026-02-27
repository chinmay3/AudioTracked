import sys
from pathlib import Path

sys.path.append(str(Path(__file__).resolve().parents[1]))
from utils import text_watermark, extract_text_watermark

text_watermark('Man this song is creepy', 'radiohead.wav')
print(extract_text_watermark('wtext.wav'))
