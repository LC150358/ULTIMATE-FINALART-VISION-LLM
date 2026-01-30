import Foundation
import UIKit

class GeminiProvider {
    
    private let apiKey = "AIzaSyBZt0D4ct9Xrr41qej3PYe2R1DmF-gHip4"
    private let modelName = "gemini-2.5-flash"
    
    static let shared = GeminiProvider()
    private init() {}
    
    func getArtistInfo(artistName: String, completion: @escaping (Result<ArtistInfo, Error>) -> Void) {
        
        let urlString = "https://generativelanguage.googleapis.com/v1beta/models/\(modelName):generateContent?key=\(apiKey)"
        
        guard let url = URL(string: urlString) else {
            completion(.failure(GeminiError.invalidURL))
            return
        }
        
        let promptText = """
You are an art historian. Write a professional informative profile about \(artistName).

IMPORTANT RULES:
- NEVER start with "Certainly", "Here is", "Sure" or other pleasantries
- Start DIRECTLY with the artist's name and information
- Use an academic but accessible tone
- Write in a fluid, narrative style without bullet points

STRUCTURE (integrate into a single flowing text):
1. Full name, birth and death dates, nationality
2. Artistic training and influences
3. Artistic movement(s) they belonged to
4. Distinctive characteristics of their painting style
5. Most famous works and their importance
6. Artistic legacy and influence on later artists

Write in English, approximately 300-400 words.
"""
        
        let requestBody: [String: Any] = [
            "contents": [[
                "parts": [["text": promptText]]
            ]],
            "generationConfig": [
                "maxOutputTokens": 2500,
                "temperature": 0.7
            ]
        ]
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 120
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        } catch {
            completion(.failure(error))
            return
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(GeminiError.noData))
                return
            }
            
            do {
                let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                
                if let candidates = json?["candidates"] as? [[String: Any]],
                   let content = candidates.first?["content"] as? [String: Any],
                   let parts = content["parts"] as? [[String: Any]],
                   let text = parts.first?["text"] as? String {
                    
                    let info = ArtistInfo(
                        artistName: artistName,
                        fullText: text,
                        biography: text,
                        style: "",
                        famousWorks: "",
                        period: "",
                        funFact: ""
                    )
                    completion(.success(info))
                } else {
                    completion(.failure(GeminiError.invalidResponse))
                }
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
    
    func identifyPainting(image: UIImage, artistName: String, completion: @escaping (Result<PaintingInfo, Error>) -> Void) {
        
        let urlString = "https://generativelanguage.googleapis.com/v1beta/models/\(modelName):generateContent?key=\(apiKey)"
        
        guard let url = URL(string: urlString) else {
            completion(.failure(GeminiError.invalidURL))
            return
        }
        
        guard let imageData = image.jpegData(compressionQuality: 0.9) else {
            completion(.failure(GeminiError.imageConversionFailed))
            return
        }
        let base64Image = imageData.base64EncodedString()
        
        let promptText = """
You are an art historian. Analyze this artwork by \(artistName).

IMPORTANT RULES:
- NEVER start with "Certainly", "Here is", "Sure" or other pleasantries
- Start DIRECTLY with the title of the artwork

MANDATORY TITLE FORMAT:
Write the title in the ORIGINAL LANGUAGE of the artist:
- FRENCH artists (Monet, Renoir, Chagall): title in FRENCH
- Van Gogh: title in FRENCH (he worked in France)
- Klimt: title in GERMAN
- Picasso: title in SPANISH or French

Start with: "[Original Title]" (year)

NEVER translate the title to English!

Then continue with a COMPLETE paragraph including: technique, dimensions if known, museum and city where it is housed, detailed description of the subject and composition.

EXAMPLE for Van Gogh:
"La Nuit étoilée" (1889) is an oil on canvas measuring 73 × 92 cm housed at MoMA in New York. The work depicts a turbulent night sky above a quiet village, with a cypress tree in the foreground reaching upward. The swirling, dynamic brushstrokes convey a sense of energy and emotional movement.

IMPORTANT: Always complete all sentences without interrupting mid-way. Description in English, but title ALWAYS in original language.
"""
        
        let requestBody: [String: Any] = [
            "contents": [[
                "parts": [
                    ["text": promptText],
                    ["inline_data": [
                        "mime_type": "image/jpeg",
                        "data": base64Image
                    ]]
                ]
            ]],
            "generationConfig": [
                "maxOutputTokens": 3000,
                "temperature": 0.7
            ]
        ]
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 120
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        } catch {
            completion(.failure(error))
            return
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(GeminiError.noData))
                return
            }
            
            do {
                let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                
                if let candidates = json?["candidates"] as? [[String: Any]] {
                    
                    if let finishReason = candidates.first?["finishReason"] as? String {
                        print("🔍 GEMINI FINISH REASON: \(finishReason)")
                        if finishReason != "STOP" {
                            print("⚠️ Warning! Gemini stopped for: \(finishReason)")
                        }
                    }
                    
                    if let content = candidates.first?["content"] as? [String: Any],
                       let parts = content["parts"] as? [[String: Any]],
                       let text = parts.first?["text"] as? String {
                        
                        print("📝 Text received: \(text.count) characters")
                        
                        let info = self.parsePaintingInfoNarrative(from: text)
                        completion(.success(info))
                    } else {
                        completion(.failure(GeminiError.invalidResponse))
                    }
                } else {
                    completion(.failure(GeminiError.invalidResponse))
                }
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
    
    private func parsePaintingInfoNarrative(from text: String) -> PaintingInfo {
        let cleaned = text.trimmingCharacters(in: .whitespacesAndNewlines)
        
        var title = "Unknown"
        if let startQuote = cleaned.firstIndex(of: "\""),
           let endQuote = cleaned[cleaned.index(after: startQuote)...].firstIndex(of: "\"") {
            title = String(cleaned[cleaned.index(after: startQuote)..<endQuote])
        }
        
        return PaintingInfo(
            fullText: cleaned,
            title: title,
            year: "",
            technique: "",
            dimensions: "",
            museum: "",
            description: cleaned
        )
    }
}

struct ArtistInfo {
    let artistName: String
    let fullText: String
    let biography: String
    let style: String
    let famousWorks: String
    let period: String
    let funFact: String
}

struct PaintingInfo {
    let fullText: String
    let title: String
    let year: String
    let technique: String
    let dimensions: String
    let museum: String
    let description: String
}

enum GeminiError: Error, LocalizedError {
    case invalidURL
    case noData
    case invalidResponse
    case imageConversionFailed
    
    var errorDescription: String? {
        switch self {
        case .invalidURL: return "Invalid URL"
        case .noData: return "No data received"
        case .invalidResponse: return "Invalid response from Gemini"
        case .imageConversionFailed: return "Image conversion error"
        }
    }
}
