import SwiftUI
import Foundation

struct EnvironmentProcessor {
    static func processReceiptText(_ fullText: String, completion: @escaping (String, String, Date) -> Void) {
        print("All pages processed. Full recognized text:\n\(fullText)")
        let prompt = "Extract the receipt title, total amount and the date of the receipt from the following receipt text. Title should be the name of the place item was purchased. Return the result as a JSON object with keys \"title\", \"amount\", and \"date\". Date should be return in yyyy-mm-dd format. Do not place a comma for amount. Receipt text:\n\n\(fullText)"
        print("Open AI prompt:\n\(prompt)")
        
        guard let url = URL(string: "https://api.openai.com/v1/chat/completions") else {
            completion("Receipt", "0.00", Date())
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let apiKey = Env.OPENAI_API_KEY
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        
        let body: [String: Any] = [
            "model": "gpt-4.1-nano",
            "messages": [
                ["role": "user", "content": prompt]
            ],
            "max_tokens": 50,
            "temperature": 0.0
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])
        } catch {
            print("Error serializing JSON: \(error.localizedDescription)")
            completion("Receipt", "0.00", Date())
            return
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error calling OpenAI API: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    completion("Receipt", "0.00", Date())
                }
                return
            }
            
            guard let data = data else {
                DispatchQueue.main.async {
                    completion("Receipt", "0.00", Date())
                }
                return
            }
            
            print("API raw response: \(String(data: data, encoding: .utf8) ?? "")")
            
            do {
                if let result = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                   let choices = result["choices"] as? [[String: Any]],
                   let firstChoice = choices.first,
                   let message = firstChoice["message"] as? [String: Any],
                   let text = message["content"] as? String {
                    // Remove markdown code fences if present
                    let cleanedText = text.replacingOccurrences(of: "```json", with: "")
                                           .replacingOccurrences(of: "```", with: "")
                                           .trimmingCharacters(in: .whitespacesAndNewlines)
                    print("Cleaned API response text: \(cleanedText)")
                    
                    if let jsonData = cleanedText.data(using: .utf8) {
                        var parsedDate = Date()
                        if let parsed = try JSONSerialization.jsonObject(with: jsonData, options: []) as? [String: Any],
                           let parsedTitle = parsed["title"] as? String {
                            var parsedAmountString = "0.00"
                            if let amount = parsed["amount"] {
                                if let amountNumber = amount as? NSNumber {
                                    parsedAmountString = amountNumber.stringValue
                                } else if let amountStr = amount as? String {
                                    parsedAmountString = amountStr
                                }
                            }
                            if let date = parsed["date"] {
                                if let dateStr = date as? String {
                                    let inputFormatter = DateFormatter()
                                    inputFormatter.dateFormat = "yyyy-MM-dd"
                                    if let dateValue = inputFormatter.date(from: dateStr) {
                                        parsedDate = dateValue
                                    }
                                }
                            }
                            DispatchQueue.main.async {
                                completion(parsedTitle, parsedAmountString, parsedDate)
                                print(parsedTitle)
                                print(parsedAmountString)
                                print(parsedDate)
                            }
                            return
                        }
                    }
                }
                
                DispatchQueue.main.async {
                    completion("Receipt", "0.00", Date())
                }
            } catch {
                print("Error parsing OpenAI API response: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    completion("Receipt", "0.00", Date())
                }
            }
        }.resume()
    }
}

