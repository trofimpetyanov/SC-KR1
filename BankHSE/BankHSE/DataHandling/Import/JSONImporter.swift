import Foundation

class JSONImporter: DataImporter {
    override func parseData(_ data: Data) throws -> Any {
        do {
            guard let jsonObject = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
                throw ImportError.parseError("Не удалось преобразовать JSON в словарь")
            }
            return jsonObject
        } catch {
            throw ImportError.parseError("Ошибка парсинга JSON: \(error.localizedDescription)")
        }
    }
}
