
import Foundation

protocol QuestionFactoryProtocol {
    func requestNextQuestion()
 }
class QuestionFactory: QuestionFactoryProtocol {
    private let questionFactory: QuestionFactoryProtocol = QuestionFactory()
    
}
