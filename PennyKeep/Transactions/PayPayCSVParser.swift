import Foundation

struct PayPayTransaction: Identifiable, Equatable {
    var id: String { transactionID }
    var dateTime: Date
    var amountOutgoing: Double?
    var amountIncoming: Double?
    var transactionType: String
    var businessName: String
    var method: String
    var paymentOption: String
    var transactionID: String
    
    // Editable fields
    var editedTitle: String?
    var editedCategory: String?
    var editedType: TransactionType?
    
    static func == (lhs: PayPayTransaction, rhs: PayPayTransaction) -> Bool {
        lhs.transactionID == rhs.transactionID
    }
    
    var amount: Double {
        amountOutgoing ?? -(amountIncoming ?? 0)
    }
    
    var isExpense: Bool {
        if let editedType = editedType {
            return editedType == .expense
        }
        return amountOutgoing != nil && amountOutgoing! > 0
    }
    
    var isIncome: Bool {
        if let editedType = editedType {
            return editedType == .income
        }
        return amountIncoming != nil && amountIncoming! > 0
    }
    
    var displayTitle: String {
        if let editedTitle = editedTitle, !editedTitle.isEmpty {
            return editedTitle
        }
        if businessName.isEmpty {
            return transactionType
        }
        return businessName
    }
    
    var finalCategory: String {
        editedCategory ?? "Other"
    }
}

class PayPayCSVParser {
    static func parse(_ csvContent: String) -> [PayPayTransaction] {
        let lines = csvContent.components(separatedBy: .newlines)
        guard lines.count > 1 else { return [] }
        
        // Skip header row
        let dataLines = Array(lines.dropFirst())
        
        var transactions: [PayPayTransaction] = []
        
        for line in dataLines {
            guard !line.trimmingCharacters(in: .whitespaces).isEmpty else { continue }
            
            let columns = parseCSVLine(line)
            guard columns.count >= 13 else { continue }
            
            // Parse date and time
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy/MM/dd HH:mm:ss"
            dateFormatter.locale = Locale(identifier: "ja_JP")
            guard let dateTime = dateFormatter.date(from: columns[0]) else { continue }
            
            // Parse amounts (remove commas)
            let amountOutgoingStr = columns[1].replacingOccurrences(of: ",", with: "").replacingOccurrences(of: "-", with: "")
            let amountIncomingStr = columns[2].replacingOccurrences(of: ",", with: "").replacingOccurrences(of: "-", with: "")
            
            let amountOutgoing = amountOutgoingStr.isEmpty ? nil : Double(amountOutgoingStr)
            let amountIncoming = amountIncomingStr.isEmpty ? nil : Double(amountIncomingStr)
            
            // Determine transaction type
            let transactionType = columns[7]
            let businessName = columns[8]
            let method = columns[9]
            let paymentOption = columns[10]
            let transactionID = columns[12]
            
            // Determine income/expense based on transaction type
            var finalAmountOutgoing: Double? = amountOutgoing
            var finalAmountIncoming: Double? = amountIncoming
            
            // Top-Up and Money Received are treated as income
            if transactionType == "Top-Up" || transactionType == "Money Received" {
                if amountIncoming == nil && amountOutgoing != nil {
                    finalAmountIncoming = amountOutgoing
                    finalAmountOutgoing = nil
                }
            }
            // Money Sent, Payment, and Invested are treated as expenses
            else if transactionType == "Money Sent" || transactionType == "Payment" || transactionType == "Invested" {
                if amountOutgoing == nil && amountIncoming != nil {
                    finalAmountOutgoing = amountIncoming
                    finalAmountIncoming = nil
                }
            }
            
            let transaction = PayPayTransaction(
                dateTime: dateTime,
                amountOutgoing: finalAmountOutgoing,
                amountIncoming: finalAmountIncoming,
                transactionType: transactionType,
                businessName: businessName,
                method: method,
                paymentOption: paymentOption,
                transactionID: transactionID,
                editedTitle: nil,
                editedCategory: nil,
                editedType: nil
            )
            
            transactions.append(transaction)
        }
        
        return transactions
    }
    
    private static func parseCSVLine(_ line: String) -> [String] {
        var result: [String] = []
        var currentField = ""
        var insideQuotes = false
        
        for char in line {
            if char == "\"" {
                insideQuotes.toggle()
            } else if char == "," && !insideQuotes {
                result.append(currentField.trimmingCharacters(in: .whitespaces))
                currentField = ""
            } else {
                currentField.append(char)
            }
        }
        
        // Add the last field
        result.append(currentField.trimmingCharacters(in: .whitespaces))
        
        return result
    }
}
