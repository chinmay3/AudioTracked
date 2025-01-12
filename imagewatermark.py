from utils import image_watermark, extract_image_watermark

w, h, index = image_watermark('radiohead.wav', 'creepyman.jpg')
extract_image_watermark('wiaudio.wav', w, h, index) 