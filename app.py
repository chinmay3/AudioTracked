from flask import Flask, request, jsonify, send_file
from flask_cors import CORS
import os
import uuid
import boto3
import shutil
import json
from utils import (
    audio_watermark as audio_watermark_util,
    extract_audio_watermark as extract_audio_watermark_util,
    extract_audio_watermark_direct as extract_audio_watermark_direct_util,
    image_watermark as image_watermark_util,
    extract_image_watermark_direct as extract_image_watermark_direct_util,
    text_watermark as text_watermark_util,
    extract_text_watermark as extract_text_watermark_util,
)

app = Flask(__name__)
CORS(app)

# AWS Configuration
S3_BUCKET = os.getenv('S3_BUCKET', 'audiotracked-files')
AWS_REGION = os.getenv('AWS_REGION', 'us-east-1')

# Storage configuration
LOCAL_STORAGE_DIR = os.getenv('LOCAL_STORAGE_DIR', 'local_storage')
DISABLE_S3 = os.getenv('DISABLE_S3', '').strip() == '1'
FILES_DIR = os.getenv('FILES_DIR', 'files')

# Initialize S3 client if credentials exist and S3 isn't disabled
_session = boto3.Session()
_credentials = _session.get_credentials()
S3_ENABLED = (not DISABLE_S3) and (_credentials is not None)
s3_client = boto3.client('s3', region_name=AWS_REGION) if S3_ENABLED else None

# Ensure upload directory exists
UPLOAD_FOLDER = 'temp_uploads'
os.makedirs(UPLOAD_FOLDER, exist_ok=True)
os.makedirs(FILES_DIR, exist_ok=True)

TEMP_RESULT_FILES = {
    "audio_watermarked": os.path.join(FILES_DIR, "waudio.wav"),
    "audio_extracted": os.path.join(FILES_DIR, "ewaudio.wav"),
    "image_watermarked": os.path.join(FILES_DIR, "wiaudio.wav"),
    "image_extracted": os.path.join(FILES_DIR, "extracted_image.jpg"),
    "text_watermarked": os.path.join(FILES_DIR, "wtext.wav"),
}
SAMPLE_FILES = {
    "radiohead.wav": "audio/wav",
    "creep.wav": "audio/wav",
    "creepyman.jpg": "image/jpeg",
}

def _ensure_local_path(s3_key):
    local_path = os.path.join(LOCAL_STORAGE_DIR, s3_key)
    os.makedirs(os.path.dirname(local_path), exist_ok=True)
    return local_path

def _store_metadata(session_id, metadata):
    if S3_ENABLED:
        s3_client.put_object(
            Bucket=S3_BUCKET,
            Key=f"metadata/{session_id}.json",
            Body=json.dumps(metadata),
            ContentType='application/json'
        )
        return
    metadata_path = _ensure_local_path(f"metadata/{session_id}.json")
    with open(metadata_path, 'w') as metadata_file:
        json.dump(metadata, metadata_file)

def _move_temp_result(source_path, destination_path):
    if not os.path.exists(source_path):
        raise FileNotFoundError(f"Expected output file missing: {source_path}")
    shutil.move(source_path, destination_path)

def _cleanup_paths(*paths):
    for path in paths:
        if path and os.path.exists(path):
            os.remove(path)

def upload_to_s3(file_path, s3_key):
    """Upload file to S3 bucket or local storage"""
    if not S3_ENABLED:
        local_path = _ensure_local_path(s3_key)
        shutil.copyfile(file_path, local_path)
        return f"/api/local-file/{s3_key}"
    try:
        s3_client.upload_file(file_path, S3_BUCKET, s3_key)
        # Return a signed URL that works for 7 days instead of public URL
        url = s3_client.generate_presigned_url(
            'get_object',
            Params={'Bucket': S3_BUCKET, 'Key': s3_key},
            ExpiresIn=604800  # 7 days
        )
        return url
    except Exception as e:
        raise Exception(f"Failed to upload to S3: {str(e)}")

def download_from_s3(s3_key, local_path):
    """Download file from S3 bucket or local storage"""
    if not S3_ENABLED:
        source_path = os.path.join(LOCAL_STORAGE_DIR, s3_key)
        if not os.path.exists(source_path):
            raise Exception("File not found in local storage")
        shutil.copyfile(source_path, local_path)
        return True
    try:
        s3_client.download_file(S3_BUCKET, s3_key, local_path)
        return True
    except Exception as e:
        raise Exception(f"Failed to download from S3: {str(e)}")

@app.route('/health', methods=['GET'])
def health_check():
    return jsonify({"status": "healthy", "service": "AudioTracked API"})

@app.route('/api/audio-watermark', methods=['POST'])
def embed_audio_watermark_endpoint():
    """Embed audio file into another audio file"""
    try:
        if 'host_audio' not in request.files or 'watermark_audio' not in request.files:
            return jsonify({"error": "Both host_audio and watermark_audio files are required"}), 400
        
        host_file = request.files['host_audio']
        watermark_file = request.files['watermark_audio']
        
        if host_file.filename == '' or watermark_file.filename == '':
            return jsonify({"error": "No files selected"}), 400
        
        # Generate unique IDs for files
        session_id = str(uuid.uuid4())
        # Save temp files
        host_path = os.path.join(UPLOAD_FOLDER, f"{session_id}_host.wav")
        watermark_path = os.path.join(UPLOAD_FOLDER, f"{session_id}_watermark.wav")
        
        host_file.save(host_path)
        watermark_file.save(watermark_path)
        
        # Process watermarking
        small_audio_bits = audio_watermark_util(host_path, watermark_path)
        
        # Save result - the utils function saves to "files/waudio.wav"
        temp_result = TEMP_RESULT_FILES["audio_watermarked"]
        result_path = os.path.join(UPLOAD_FOLDER, f"{session_id}_result.wav")
        _move_temp_result(temp_result, result_path)
        
        # Upload to S3
        result_s3_key = f"watermarked/{session_id}_result.wav"
        result_url = upload_to_s3(result_path, result_s3_key)
        
        # Store metadata in S3
        metadata = {
            "session_id": session_id,
            "type": "audio_watermark",
            "small_audio_bits": small_audio_bits,
            "result_url": result_url,
            "result_s3_key": result_s3_key
        }
        _store_metadata(session_id, metadata)
        
        # Cleanup temp files
        _cleanup_paths(host_path, watermark_path, result_path)
        
        return jsonify({
            "success": True,
            "session_id": session_id,
            "result_url": result_url,
            "message": "Audio watermarking completed successfully"
        })
        
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@app.route('/api/audio-watermark/extract', methods=['POST'])
def extract_audio_watermark_endpoint():
    """Extract embedded audio from watermarked file"""
    try:
        data = request.get_json()
        session_id = data.get('session_id')
        
        if not session_id:
            return jsonify({"error": "session_id is required"}), 400
        
        # Download metadata
        try:
            if S3_ENABLED:
                metadata_response = s3_client.get_object(
                    Bucket=S3_BUCKET,
                    Key=f"metadata/{session_id}.json"
                )
                metadata = json.loads(metadata_response['Body'].read())
            else:
                metadata_path = os.path.join(LOCAL_STORAGE_DIR, f"metadata/{session_id}.json")
                with open(metadata_path, 'r') as metadata_file:
                    metadata = json.load(metadata_file)
            small_audio_bits = metadata['small_audio_bits']
            result_s3_key = metadata.get('result_s3_key')
            if not result_s3_key:
                result_url = metadata.get('result_url', '')
                result_s3_key = result_url.split('?')[0].split('/')[-1]
            if not result_s3_key.startswith("watermarked/"):
                result_s3_key = f"watermarked/{result_s3_key}"
        except Exception:
            return jsonify({"error": "Session not found"}), 404
        
        # Download watermarked file
        watermarked_path = os.path.join(UPLOAD_FOLDER, f"{session_id}_watermarked.wav")
        download_from_s3(result_s3_key, watermarked_path)
        
        # Extract watermark
        extract_audio_watermark_util(watermarked_path, small_audio_bits)
        
        # Upload extracted audio
        extracted_path = TEMP_RESULT_FILES["audio_extracted"]
        extracted_s3_key = f"extracted/{session_id}_extracted.wav"
        extracted_url = upload_to_s3(extracted_path, extracted_s3_key)
        
        # Cleanup
        _cleanup_paths(watermarked_path, extracted_path)
        
        return jsonify({
            "success": True,
            "extracted_url": extracted_url,
            "message": "Audio watermark extracted successfully"
        })
        
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@app.route('/api/audio-watermark/direct-extract', methods=['POST'])
def direct_extract_audio_watermark_endpoint():
    """Directly extract embedded audio from uploaded watermarked file"""
    try:
        if 'audio' not in request.files:
            return jsonify({"error": "Audio file is required"}), 400
        
        audio_file = request.files['audio']
        session_id = str(uuid.uuid4())
        
        # Save temp file
        audio_path = os.path.join(UPLOAD_FOLDER, f"{session_id}_watermarked.wav")
        audio_file.save(audio_path)
        
        # Extract watermark using direct method
        extracted_size = extract_audio_watermark_direct_util(audio_path)
        
        # Move result - the utils function saves to "files/ewaudio.wav"
        temp_result = TEMP_RESULT_FILES["audio_extracted"]
        result_path = os.path.join(UPLOAD_FOLDER, f"{session_id}_extracted.wav")
        _move_temp_result(temp_result, result_path)
        
        # Upload extracted audio
        extracted_s3_key = f"extracted/{session_id}_extracted.wav"
        extracted_url = upload_to_s3(result_path, extracted_s3_key)
        
        # Cleanup
        _cleanup_paths(audio_path, result_path)
        
        return jsonify({
            "success": True,
            "extracted_url": extracted_url,
            "extracted_size": extracted_size,
            "message": "Audio watermark extracted successfully"
        })
        
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@app.route('/api/image-watermark', methods=['POST'])
def embed_image_watermark_endpoint():
    """Embed image into audio file"""
    try:
        if 'audio' not in request.files or 'image' not in request.files:
            return jsonify({"error": "Both audio and image files are required"}), 400
        
        audio_file = request.files['audio']
        image_file = request.files['image']
        
        session_id = str(uuid.uuid4())
        
        # Save temp files
        audio_path = os.path.join(UPLOAD_FOLDER, f"{session_id}_audio.wav")
        image_path = os.path.join(UPLOAD_FOLDER, f"{session_id}_image.jpg")
        
        audio_file.save(audio_path)
        image_file.save(image_path)
        
        # Process watermarking
        w, h, index = image_watermark_util(audio_path, image_path)
        
        # Move result - the utils function saves to "files/wiaudio.wav"
        temp_result = TEMP_RESULT_FILES["image_watermarked"]
        result_path = os.path.join(UPLOAD_FOLDER, f"{session_id}_result.wav")
        _move_temp_result(temp_result, result_path)
        
        # Upload to S3
        result_s3_key = f"image_watermarked/{session_id}_result.wav"
        result_url = upload_to_s3(result_path, result_s3_key)
        
        # Store metadata
        metadata = {
            "session_id": session_id,
            "type": "image_watermark",
            "width": w,
            "height": h,
            "index": index,
            "result_url": result_url,
            "result_s3_key": result_s3_key
        }
        _store_metadata(session_id, metadata)
        
        # Cleanup
        _cleanup_paths(audio_path, image_path, result_path)
        
        return jsonify({
            "success": True,
            "session_id": session_id,
            "result_url": result_url,
            "message": "Image watermarking completed successfully"
        })
        
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@app.route('/api/image-watermark/direct-extract', methods=['POST'])
def direct_extract_image_watermark_endpoint():
    """Directly extract embedded image from uploaded watermarked file"""
    try:
        if 'audio' not in request.files:
            return jsonify({"error": "Audio file is required"}), 400
        
        audio_file = request.files['audio']
        session_id = str(uuid.uuid4())
        
        # Save temp file
        audio_path = os.path.join(UPLOAD_FOLDER, f"{session_id}_watermarked.wav")
        audio_file.save(audio_path)
        
        # Extract watermark using direct method
        width, height, extracted_bits = extract_image_watermark_direct_util(audio_path)
        
        # Move result - the utils function saves to "files/extracted_image.jpg"
        temp_result = TEMP_RESULT_FILES["image_extracted"]
        result_path = os.path.join(UPLOAD_FOLDER, f"{session_id}_extracted.jpg")
        _move_temp_result(temp_result, result_path)
        
        # Upload extracted image
        extracted_s3_key = f"extracted/{session_id}_extracted.jpg"
        extracted_url = upload_to_s3(result_path, extracted_s3_key)
        
        # Cleanup
        _cleanup_paths(audio_path, result_path)
        
        return jsonify({
            "success": True,
            "extracted_url": extracted_url,
            "width": width,
            "height": height,
            "extracted_bits": extracted_bits,
            "message": "Image watermark extracted successfully"
        })
        
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@app.route('/api/text-watermark', methods=['POST'])
def embed_text_watermark_endpoint():
    """Embed text into audio file"""
    try:
        if 'audio' not in request.files:
            return jsonify({"error": "Audio file is required"}), 400
        
        text = request.form.get('text', '')
        if not text:
            return jsonify({"error": "Text message is required"}), 400
        
        audio_file = request.files['audio']
        session_id = str(uuid.uuid4())
        
        # Save temp file
        audio_path = os.path.join(UPLOAD_FOLDER, f"{session_id}_audio.wav")
        audio_file.save(audio_path)
        
        # Process watermarking
        text_watermark_util(text, audio_path)
        
        # Move result - the utils function saves to "files/wtext.wav"
        temp_result = TEMP_RESULT_FILES["text_watermarked"]
        result_path = os.path.join(UPLOAD_FOLDER, f"{session_id}_result.wav")
        _move_temp_result(temp_result, result_path)
        
        # Upload to S3
        result_s3_key = f"text_watermarked/{session_id}_result.wav"
        result_url = upload_to_s3(result_path, result_s3_key)
        
        # Store metadata
        metadata = {
            "session_id": session_id,
            "type": "text_watermark",
            "text": text,
            "result_url": result_url,
            "result_s3_key": result_s3_key
        }
        _store_metadata(session_id, metadata)
        
        # Cleanup
        _cleanup_paths(audio_path, result_path)
        
        return jsonify({
            "success": True,
            "session_id": session_id,
            "result_url": result_url,
            "message": "Text watermarking completed successfully"
        })
        
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@app.route('/api/text-watermark/extract', methods=['POST'])
def extract_text_watermark_endpoint():
    """Extract text from watermarked audio"""
    try:
        if 'audio' not in request.files:
            return jsonify({"error": "Audio file is required"}), 400
        
        audio_file = request.files['audio']
        session_id = str(uuid.uuid4())
        
        # Save temp file
        audio_path = os.path.join(UPLOAD_FOLDER, f"{session_id}_audio.wav")
        audio_file.save(audio_path)
        
        # Extract text
        extracted_text = extract_text_watermark_util(audio_path)
        
        # Cleanup
        _cleanup_paths(audio_path)
        
        return jsonify({
            "success": True,
            "extracted_text": extracted_text,
            "message": "Text watermark extracted successfully"
        })
        
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@app.route('/api/download/<filename>')
def download_file(filename):
    """Download a file by serving the S3 content directly"""
    try:
        if not S3_ENABLED:
            local_candidates = [
                os.path.join(LOCAL_STORAGE_DIR, "watermarked", filename),
                os.path.join(LOCAL_STORAGE_DIR, "image_watermarked", filename),
                os.path.join(LOCAL_STORAGE_DIR, "text_watermarked", filename),
                os.path.join(LOCAL_STORAGE_DIR, "extracted", filename),
                os.path.join(LOCAL_STORAGE_DIR, "downloads", filename),
            ]
            for candidate in local_candidates:
                if os.path.exists(candidate):
                    return send_file(candidate, as_attachment=True, download_name=filename)
            return jsonify({"error": "File not found"}), 404

        # Get the file from S3
        s3_key = f"downloads/{filename}"
        
        # Check if file exists in different folders
        try:
            s3_client.head_object(Bucket=S3_BUCKET, Key=f"watermarked/{filename}")
            s3_key = f"watermarked/{filename}"
        except:
            try:
                s3_client.head_object(Bucket=S3_BUCKET, Key=f"image_watermarked/{filename}")
                s3_key = f"image_watermarked/{filename}"
            except:
                try:
                    s3_client.head_object(Bucket=S3_BUCKET, Key=f"text_watermarked/{filename}")
                    s3_key = f"text_watermarked/{filename}"
                except:
                    try:
                        s3_client.head_object(Bucket=S3_BUCKET, Key=f"extracted/{filename}")
                        s3_key = f"extracted/{filename}"
                    except:
                        return jsonify({"error": "File not found"}), 404
        
        # Create a temporary file to download from S3
        temp_path = os.path.join(UPLOAD_FOLDER, f"temp_{filename}")
        s3_client.download_file(S3_BUCKET, s3_key, temp_path)
        
        # Send the file
        return send_file(temp_path, as_attachment=True, download_name=filename)
        
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@app.route('/api/local-file/<path:s3_key>')
def local_file(s3_key):
    """Serve locally stored files when S3 is disabled."""
    if S3_ENABLED:
        return jsonify({"error": "Local file serving is disabled when S3 is enabled"}), 400
    local_path = os.path.join(LOCAL_STORAGE_DIR, s3_key)
    if not os.path.exists(local_path):
        return jsonify({"error": "File not found"}), 404
    filename = os.path.basename(local_path)
    return send_file(local_path, as_attachment=True, download_name=filename)

@app.route('/api/sample/<filename>')
def sample_file(filename):
    """Serve bundled sample assets for one-click demo flows."""
    if filename not in SAMPLE_FILES:
        return jsonify({"error": "Sample file not found"}), 404
    sample_path = os.path.join(FILES_DIR, filename)
    if not os.path.exists(sample_path):
        return jsonify({"error": "Sample file missing on server"}), 404
    return send_file(sample_path, mimetype=SAMPLE_FILES[filename], as_attachment=False)

@app.route('/')
def index():
    """Serve the web interface"""
    return send_file('web_interface.html')

if __name__ == '__main__':
    port = int(os.getenv("PORT", "5001"))
    debug = os.getenv("FLASK_DEBUG", "").strip() == "1"
    app.run(host='0.0.0.0', port=port, debug=debug)
