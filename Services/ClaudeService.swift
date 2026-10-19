import Foundation

enum DAError: LocalizedError {
    case missingAPIKey
    case encodingError
    case apiError(String)

    var errorDescription: String? {
        switch self {
        case .missingAPIKey:
            return "Please add your Anthropic API key in Settings to start."
        case .encodingError:
            return "Failed to encode the request."
        case .apiError(let msg):
            return msg
        }
    }
}

struct ClaudeService {

    private static let systemPrompt = """
    You are a world-class executive career and leadership coach. You have guided hundreds of \
    senior leaders through pivotal career moments — promotions, pivots, performance challenges, \
    team conflicts, and questions of purpose.

    Your style:
    - Direct and honest. You don't flatter or soften difficult truths.
    - Question-forward. You often respond to a concern with a question that reframes it.
    - Practical. Every session should leave the person with one clear thing to act on.
    - Human. You recognize the emotional weight of career decisions.

    You are in a private daily consulting session. This is the person's space to think out loud, \
    get unstuck, and grow as a leader. Keep responses focused and conversational — typically 2-4 \
    paragraphs. No bullet lists unless they genuinely help. Ask one follow-up question at the end \
    when it moves the conversation forward.
    """

    // Returns a cancel closure. Call it to abort the stream.
    @discardableResult
    func sendMessage(
        messages: [Message],
        apiKey: String,
        onToken: @escaping (String) -> Void,
        onComplete: @escaping (Error?) -> Void
    ) -> () -> Void {
        let trimmedKey = apiKey.trimmingCharacters(in: .whitespaces)
        guard !trimmedKey.isEmpty else {
            DispatchQueue.main.async { onComplete(DAError.missingAPIKey) }
            return {}
        }

        let apiMessages = messages.map { ["role": $0.role.rawValue, "content": $0.content] }
        let body: [String: Any] = [
            "model": "claude-opus-4-8",
            "max_tokens": 1500,
            "stream": true,
            "thinking": ["type": "adaptive"],
            "system": Self.systemPrompt,
            "messages": apiMessages
        ]

        guard let bodyData = try? JSONSerialization.data(withJSONObject: body) else {
            DispatchQueue.main.async { onComplete(DAError.encodingError) }
            return {}
        }

        var request = URLRequest(url: URL(string: "https://api.anthropic.com/v1/messages")!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(trimmedKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        request.httpBody = bodyData

        let delegate = SSEDelegate(onToken: onToken, onComplete: onComplete)
        let urlSession = URLSession(configuration: .default, delegate: delegate, delegateQueue: nil)
        urlSession.dataTask(with: request).resume()

        return { urlSession.invalidateAndCancel() }
    }
}

// MARK: - SSE Delegate

private class SSEDelegate: NSObject, URLSessionDataDelegate {
    private var lineBuffer = ""
    private var errorData = Data()
    private var isErrorResponse = false

    let onToken: (String) -> Void
    let onComplete: (Error?) -> Void

    init(onToken: @escaping (String) -> Void, onComplete: @escaping (Error?) -> Void) {
        self.onToken = onToken
        self.onComplete = onComplete
    }

    func urlSession(
        _ session: URLSession,
        dataTask: URLSessionDataTask,
        didReceive response: URLResponse,
        completionHandler: @escaping (URLSession.ResponseDisposition) -> Void
    ) {
        if let http = response as? HTTPURLResponse, http.statusCode != 200 {
            isErrorResponse = true
        }
        completionHandler(.allow)
    }

    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        if isErrorResponse {
            errorData.append(data)
            return
        }

        guard let text = String(data: data, encoding: .utf8) else { return }
        lineBuffer += text

        while let newlineRange = lineBuffer.range(of: "\n") {
            let line = String(lineBuffer[lineBuffer.startIndex..<newlineRange.lowerBound])
            lineBuffer = String(lineBuffer[newlineRange.upperBound...])
            handleLine(line.trimmingCharacters(in: .init(charactersIn: "\r")))
        }
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let urlError = error as? URLError, urlError.code == .cancelled { return }

        if let error {
            DispatchQueue.main.async { self.onComplete(error) }
            return
        }

        if isErrorResponse {
            let msg: String
            if let json = try? JSONSerialization.jsonObject(with: errorData) as? [String: Any],
               let errObj = json["error"] as? [String: Any],
               let message = errObj["message"] as? String {
                msg = message
            } else {
                msg = "API request failed. Check your API key and try again."
            }
            DispatchQueue.main.async { self.onComplete(DAError.apiError(msg)) }
        } else {
            DispatchQueue.main.async { self.onComplete(nil) }
        }
    }

    private func handleLine(_ line: String) {
        guard line.hasPrefix("data: ") else { return }
        let jsonStr = String(line.dropFirst(6))
        guard jsonStr != "[DONE]",
              let data = jsonStr.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        else { return }

        // content_block_delta carries text tokens
        guard let type = json["type"] as? String, type == "content_block_delta",
              let delta = json["delta"] as? [String: Any],
              delta["type"] as? String == "text_delta",
              let token = delta["text"] as? String
        else { return }

        DispatchQueue.main.async { self.onToken(token) }
    }
}
