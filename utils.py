import wave
import numpy as np
from PIL import Image

def load_audio(filename):
    with wave.open('files/'+filename, 'rb') as audio_file:
        num_channels = audio_file.getnchannels()
        sample_width = audio_file.getsampwidth()
        frame_rate = audio_file.getframerate()
        audio_data = bytearray(list(audio_file.readframes(audio_file.getnframes())))
    return audio_data, num_channels, sample_width, frame_rate

def save_audio(filename, audio_data, num_channels, sample_width, frame_rate):
    with wave.open('files/'+filename, 'wb') as audio_file:
        audio_file.setnchannels(num_channels)
        audio_file.setsampwidth(sample_width)
        audio_file.setframerate(frame_rate)
        audio_file.writeframes(audio_data)
    
def text_watermark(message, filename):
    audio_data, num_channels, sample_width, frame_rate= load_audio(filename)
    message = message+ '#####'
    message = message + int((len(audio_data)-(len(message)*8*8))/8) *'#'
    bits = list(map(int, ''.join([bin(ord(i)).lstrip('0b').rjust(8,'0') for i in message])))
    for i, bit in enumerate(bits):
        audio_data[i] =bit | (2**8-2 & audio_data[i])
    
    audio_data_modified = bytes(audio_data)
    save_audio('wtext.wav', audio_data_modified, num_channels, sample_width, frame_rate)
    print('Watermarking done')

def extract_text_watermark(filename):
    audio_data, _, _, _ = load_audio(filename)
    extracted = [audio_data[i] & 1 for i in range(len(audio_data))]
    string = "".join(chr(int("".join(map(str,extracted[i:i+8])),2)) for i in range(0,len(extracted),8))
    decode = string.split("#####")[0]
    return decode

def audio_watermark(filename_audio, filename_watermark):
    audio_data, num_channels, sample_width, frame_rate = load_audio(filename_audio)
    watermark_data, _, _, _ = load_audio(filename_watermark)

    small_audio_bits = []
    for byte in watermark_data:
        small_audio_bits.extend([int(bit) for bit in bin(byte)[2:].rjust(8, '0')])
    if len(small_audio_bits) > len(audio_data):
        raise ValueError('Watermark too large for audio file')
    else:
        for i, bit in enumerate(small_audio_bits):
            audio_data[i] = (audio_data[i] & 0xFE) | bit
    
    save_audio("waudio.wav", audio_data, num_channels, sample_width, frame_rate)
    return(small_audio_bits)


def extract_audio_watermark(filename, small_audio_bits):
    audio_data, num_channels, sample_width, frame_rate = load_audio("waudio.wav")
    extracted_bits = []

    for byte in audio_data:
        lsb = byte & 1  
        extracted_bits.append(lsb)

    if extracted_bits[:len(small_audio_bits)] == small_audio_bits:
        num_bits_in_hidden_audio = len(extracted_bits)
        num_bytes_in_hidden_audio = num_bits_in_hidden_audio // 8

        extracted_audio_data = bytearray()
        for i in range(0, num_bytes_in_hidden_audio * 8, 8):
            byte_bits = extracted_bits[i:i + 8]
            byte = int(''.join(map(str, byte_bits)), 2)  
            extracted_audio_data.append(byte)

        save_audio("ewaudio.wav", extracted_audio_data, num_channels, sample_width, frame_rate)

def image_watermark(audio, wimage):
    audio_data, num_channels, sample_width, frame_rate = load_audio(audio)
    image = Image.open('files/'+wimage).convert('L')
    width, height = image.size
    image_array = np.array(image)
    image_1d_array = image_array.flatten()
    image_bits = [format(pixel, '08b') for pixel in image_1d_array] 
    image_bits = ''.join(image_bits)

    watermark_bits = list(map(int, image_bits)) 

    if len(watermark_bits) > len(audio_data):
        raise ValueError("The image is too large to fit into the audio!")
    for i, bit in enumerate(watermark_bits):
        audio_data[i] = (audio_data[i] & 0xFE) | bit  

    save_audio('wiaudio.wav', audio_data, num_channels, sample_width, frame_rate)
    return width, height, len(watermark_bits)

def extract_image_watermark(audio, width, height, index):
    audio_data, _, _, _ = load_audio(audio)

    extracted_bits = []
    for byte in audio_data:
        lsb = byte & 1  
        extracted_bits.append(lsb)

    extracted_bits = extracted_bits[:index]
    byte_values = [int(''.join(map(str, extracted_bits[i:i+8])), 2) for i in range(0, len(extracted_bits), 8)]
    image_array = np.array(byte_values, dtype=np.uint8).reshape((height, width))
    image = Image.fromarray(image_array, mode='L')  
    image.save('files/'+'ewimate.jpg') 