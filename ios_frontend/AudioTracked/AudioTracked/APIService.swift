import Foundation
import UIKit

class APIService {
    static let shared = APIService()
    private let baseURL = "http://54.204.110.168:5000/api"
    
    private init() {}
    
    // MARK: - Audio Watermarking
    func embedAudioWatermark(hostAudio: Data, watermarkAudio: Data) async throws -> WatermarkResponse {
        let url = URL(string: "\(baseURL)/audio-watermark")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var body = Data()
        
        // Add host audio
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"host_audio\"; filename=\"host.wav\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: audio/wav\r\n\r\n".data(using: .utf8)!)
        body.append(hostAudio)
        body.append("\r\n".data(using: .utf8)!)
        
        // Add watermark audio
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"watermark_audio\"; filename=\"watermark.wav\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: audio/wav\r\n\r\n".data(using: .utf8)!)
        body.append(watermarkAudio)
        body.append("\r\n".data(using: .utf8)!)
        
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        request.httpBody = body
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw APIError.invalidResponse
        }
        
        let watermarkResponse = try JSONDecoder().decode(WatermarkResponse.self, from: data)
        return watermarkResponse
    }
    
    func extractAudioWatermark(sessionId: String) async throws -> ExtractionResponse {
        let url = URL(string: "\(baseURL)/audio-watermark/extract")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let requestBody = ["session_id": sessionId]
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw APIError.invalidResponse
        }
        
        let extractionResponse = try JSONDecoder().decode(ExtractionResponse.self, from: data)
        return extractionResponse
    }
    
    func extractAudioWatermarkDirect(audio: Data) async throws -> ExtractionResponse {
        let url = URL(string: "\(baseURL)/audio-watermark/direct-extract")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var body = Data()
        
        // Add audio
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"audio\"; filename=\"audio.wav\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: audio/wav\r\n\r\n".data(using: .utf8)!)
        body.append(audio)
        body.append("\r\n".data(using: .utf8)!)
        
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        request.httpBody = body
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw APIError.invalidResponse
        }
        
        let extractionResponse = try JSONDecoder().decode(ExtractionResponse.self, from: data)
        return extractionResponse
    }
    
    // MARK: - Image Watermarking
    func embedImageWatermark(audio: Data, image: Data) async throws -> WatermarkResponse {
        let url = URL(string: "\(baseURL)/image-watermark")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var body = Data()
        
        // Add audio
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"audio\"; filename=\"audio.wav\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: audio/wav\r\n\r\n".data(using: .utf8)!)
        body.append(audio)
        body.append("\r\n".data(using: .utf8)!)
        
        // Add image
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"image\"; filename=\"image.jpg\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
        body.append(image)
        body.append("\r\n".data(using: .utf8)!)
        
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        request.httpBody = body
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw APIError.invalidResponse
        }
        
        let watermarkResponse = try JSONDecoder().decode(WatermarkResponse.self, from: data)
        return watermarkResponse
    }
    
    func extractImageWatermarkDirect(audio: Data) async throws -> ExtractionResponse {
        let url = URL(string: "\(baseURL)/image-watermark/direct-extract")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var body = Data()
        
        // Add audio
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"audio\"; filename=\"audio.wav\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: audio/wav\r\n\r\n".data(using: .utf8)!)
        body.append(audio)
        body.append("\r\n".data(using: .utf8)!)
        
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        request.httpBody = body
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw APIError.invalidResponse
        }
        
        let extractionResponse = try JSONDecoder().decode(ExtractionResponse.self, from: data)
        return extractionResponse
    }
    
    // MARK: - Text Watermarking
    func embedTextWatermark(audio: Data, text: String) async throws -> WatermarkResponse {
        let url = URL(string: "\(baseURL)/text-watermark")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var body = Data()
        
        // Add audio
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"audio\"; filename=\"audio.wav\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: audio/wav\r\n\r\n".data(using: .utf8)!)
        body.append(audio)
        body.append("\r\n".data(using: .utf8)!)
        
        // Add text
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"text\"\r\n\r\n".data(using: .utf8)!)
        body.append(text.data(using: .utf8)!)
        body.append("\r\n".data(using: .utf8)!)
        
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        request.httpBody = body
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw APIError.invalidResponse
        }
        
        let watermarkResponse = try JSONDecoder().decode(WatermarkResponse.self, from: data)
        return watermarkResponse
    }
    
    func extractTextWatermark(audio: Data) async throws -> TextExtractionResponse {
        let url = URL(string: "\(baseURL)/text-watermark/extract")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var body = Data()
        
        // Add audio
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"audio\"; filename=\"audio.wav\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: audio/wav\r\n\r\n".data(using: .utf8)!)
        body.append(audio)
        body.append("\r\n".data(using: .utf8)!)
        
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        request.httpBody = body
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw APIError.invalidResponse
        }
        
        let extractionResponse = try JSONDecoder().decode(TextExtractionResponse.self, from: data)
        return extractionResponse
    }
}

// MARK: - Data Models
struct WatermarkResponse: Codable {
    let success: Bool
    let sessionId: String?
    let resultUrl: String?
    let message: String?
    
    enum CodingKeys: String, CodingKey {
        case success
        case sessionId = "session_id"
        case resultUrl = "result_url"
        case message
    }
}

struct ExtractionResponse: Codable {
    let success: Bool
    let extractedUrl: String?
    let message: String?
    
    enum CodingKeys: String, CodingKey {
        case success
        case extractedUrl = "extracted_url"
        case message
    }
}

struct TextExtractionResponse: Codable {
    let success: Bool
    let extractedText: String?
    let message: String?
    
    enum CodingKeys: String, CodingKey {
        case success
        case extractedText = "extracted_text"
        case message
    }
}

enum APIError: Error {
    case invalidResponse
    case noData
    case decodingError
}
