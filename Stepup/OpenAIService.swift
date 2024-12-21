import Foundation

// MARK: - Error Definitions
enum OpenAIError: LocalizedError {
    case invalidURL
    case invalidResponse
    case apiError(String)
    case parsingError(String)
    case rateLimitExceeded
    case networkError(Error)
    case emptyResponse
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid API endpoint URL"
        case .invalidResponse:
            return "Invalid response from server"
        case .apiError(let message):
            return "API Error: \(message)"
        case .parsingError(let details):
            return "Parsing Error: \(details)"
        case .rateLimitExceeded:
            return "Rate limit exceeded. Please try again later."
        case .networkError(let error):
            return "Network Error: \(error.localizedDescription)"
        case .emptyResponse:
            return "Received empty response from OpenAI"
        }
    }
}

// MARK: - Request Models
struct ChatMessage: Codable {
    let role: String
    let content: String
}

struct ChatRequest: Codable {
    let model: String
    let messages: [ChatMessage]
    let temperature: Double
    let maxTokens: Int
    
    enum CodingKeys: String, CodingKey {
        case model, messages, temperature
        case maxTokens = "max_tokens"
    }
}

// MARK: - Response Models
struct OpenAIResponse: Decodable {
    let id: String
    let object: String
    let created: Int
    let model: String
    let choices: [Choice]
    let usage: Usage
    
    struct Choice: Decodable {
        let index: Int
        let message: Message
        let finishReason: String
        
        enum CodingKeys: String, CodingKey {
            case index, message
            case finishReason = "finish_reason"
        }
    }
    
    struct Message: Decodable {
        let role: String
        let content: String
    }
    
    struct Usage: Decodable {
        let promptTokens: Int
        let completionTokens: Int
        let totalTokens: Int
        
        enum CodingKeys: String, CodingKey {
            case promptTokens = "prompt_tokens"
            case completionTokens = "completion_tokens"
            case totalTokens = "total_tokens"
        }
    }
}

// MARK: - Configuration
struct OpenAIConfig {
    let apiKey: String
    let model: String
    let temperature: Double
    let maxTokens: Int
    let baseURL: URL
    let timeoutInterval: TimeInterval
    
    static let `default` = OpenAIConfig(
        apiKey: Config.openAIKey,
        model: "gpt-3.5-turbo",
        temperature: 0.7,
        maxTokens: 60,
        baseURL: URL(string: "https://api.openai.com/v1/chat/completions")!,
        timeoutInterval: 30
    )
}

// MARK: - Cache Manager
actor ResponseCache {
    private var cache: [Int: (response: String, timestamp: Date)] = [:]
    private let cacheTimeout: TimeInterval = 300 // 5 minutes
    
    func getCachedResponse(for steps: Int) -> String? {
        guard let (response, timestamp) = cache[steps],
              Date().timeIntervalSince(timestamp) < cacheTimeout else {
            return nil
        }
        return response
    }
    
    func cacheResponse(_ response: String, for steps: Int) {
        cache[steps] = (response, Date())
    }
}

// MARK: - OpenAI Service
actor OpenAIService {
    private let config: OpenAIConfig
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder
    private let cache: ResponseCache
    private var lastRequestTime: Date?
    private let minimumRequestInterval: TimeInterval = 1.0 // 1 second
    
    init(config: OpenAIConfig = .default) {
        self.config = config
        self.decoder = JSONDecoder()
        self.encoder = JSONEncoder()
        self.cache = ResponseCache()
        encoder.keyEncodingStrategy = .convertToSnakeCase
    }
    
    private func createPrompt(for steps: Int) -> String {
        """
        Given that I have taken \(steps) steps today, generate a single short, encouraging, and fun sentence that can contain expletive slangs. 
        If steps are low, ridicule me. If steps are high, make fun of for me putting the effort. It is for adults so it can be offensive and full of expletives. 
        Respond with just the sentence, no quotes or additional text. Only give 1 sentence. DO NOT show actual step count in the message.
        """
    }
    
    func generateMotivationalSentence(steps: Int) async throws -> String {
        // Check cache first
        if let cachedResponse = await cache.getCachedResponse(for: steps) {
            return cachedResponse
        }
        
        // Implement rate limiting
        if let lastRequest = lastRequestTime,
           Date().timeIntervalSince(lastRequest) < minimumRequestInterval {
            let waitTime = minimumRequestInterval - Date().timeIntervalSince(lastRequest)
            try await Task.sleep(nanoseconds: UInt64(waitTime * 1_000_000_000))
        }
        
        // Create and configure request
        var request = URLRequest(url: config.baseURL)
        request.httpMethod = "POST"
        request.addValue("Bearer \(config.apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = config.timeoutInterval
        
        let chatRequest = ChatRequest(
            model: config.model,
            messages: [ChatMessage(role: "user", content: createPrompt(for: steps))],
            temperature: config.temperature,
            maxTokens: config.maxTokens
        )
        
        request.httpBody = try encoder.encode(chatRequest)
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            lastRequestTime = Date()
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw OpenAIError.invalidResponse
            }
            
            switch httpResponse.statusCode {
            case 200:
                let openAIResponse = try decoder.decode(OpenAIResponse.self, from: data)
                guard let firstChoice = openAIResponse.choices.first else {
                    throw OpenAIError.emptyResponse
                }
                
                let result = firstChoice.message.content.trimmingCharacters(in: .whitespacesAndNewlines)
                await cache.cacheResponse(result, for: steps)
                return result
                
            case 429:
                throw OpenAIError.rateLimitExceeded
                
            default:
                if let errorResponse = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let error = errorResponse["error"] as? [String: Any],
                   let message = error["message"] as? String {
                    throw OpenAIError.apiError(message)
                }
                throw OpenAIError.apiError("HTTP \(httpResponse.statusCode)")
            }
            
        } catch let error as OpenAIError {
            throw error
        } catch {
            throw OpenAIError.networkError(error)
        }
    }
}

// MARK: - Response Handler Protocol
protocol OpenAIResponseHandler {
    func handleSuccess(_ message: String)
    func handleError(_ error: Error)
}

// MARK: - Usage Example
extension OpenAIService {
    static func example() async {
        let config = OpenAIConfig(
            apiKey: Config.openAIKey,
            model: "gpt-3.5-turbo",
            temperature: 0.7,
            maxTokens: 60,
            baseURL: URL(string: "https://api.openai.com/v1/chat/completions")!,
            timeoutInterval: 30
        )
        
        let service = OpenAIService(config: config)
        
        do {
            let motivationalMessage = try await service.generateMotivationalSentence(steps: 8000)
            print("Response: \(motivationalMessage)")
        } catch {
            print("Error: \(error.localizedDescription)")
            if let openAIError = error as? OpenAIError {
                print("OpenAI Error Details: \(openAIError)")
            }
        }
    }
}
