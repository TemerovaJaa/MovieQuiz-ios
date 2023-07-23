import UIKit

final class MovieQuizViewController: UIViewController, QuestionFactoryDelegate {
    
    var alertPresenter: AlertPresenterProtocol?
    private var statisticService: StatisticService?
    private var currentQuestion: QuizQuestion?
    private var questionFactory: QuestionFactoryProtocol?
    var presenter: StatisticService?
    
    func didReceiveNextQuestion(question: QuizQuestion?) {
        guard let question = question else {
            return
        }
        currentQuestion = question
        let viewModel = convert(model: question)
        DispatchQueue.main.async { [weak self] in
            self?.show(quiz: viewModel)
        }
    }
    
    @IBOutlet private var imageView: UIImageView!
    @IBOutlet private var textLabel: UILabel!
    @IBOutlet private var counterLabel: UILabel!
    @IBOutlet private weak var noButton: UIButton!
    @IBOutlet private weak var yesButton: UIButton!
    
    @IBAction private func yesButtonClicked(_ sender: UIButton) {
        guard let currentQuestion = currentQuestion else {
            return
        }
        let givenAnswer = true
        
        showAnswerResults(isCorrect: givenAnswer == currentQuestion.correctAnswer)
        
    }
    
    @IBAction private func noButtonClicked(_ sender: UIButton) {
        guard let currentQuestion = currentQuestion else {
            return
        }
        
        let givenAnswer = false
        
        showAnswerResults(isCorrect: givenAnswer == currentQuestion.correctAnswer)
        
    }
    
    
    private var currentQuestionIndex = 0 // Номер текущего вопроса
    private var correctAnswers = 0 // Количество правильных ответов
    private let questionsAmount: Int = 10 // Счетчик вопросов
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        statisticService = StatisticServiceImplementation()
        var documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let fileName = "inception.json"
        documentsURL.appendPathComponent(fileName)
        let jsonString = try? String(contentsOf: documentsURL)
        
        guard let data = jsonString?.data(using: .utf8) else {
            return
        }
        do {
            let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
            _ = json?["title"]
            _ = json?["year"]
            
            print(json as Any)
        } catch {
            print("Failed to parse: \(String(describing: jsonString))")
        }
        
        questionFactory = QuestionFactory(delegate: self)
        questionFactory?.requestNextQuestion()
        alertPresenter = AlertPresenter(delegate: self)
    }
    
    
    func getMovie(from jsonString: String) -> Movie? {
        var movie: Movie? = nil
        do {
            guard let data = jsonString.data(using: .utf8) else {
                return nil
            }
            let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
            
            guard let json = json,
                  let id = json["id"] as? String,
                  let title = json["title"] as? String,
                  let jsonYear = json["year"] as? String,
                  let year = Int(jsonYear),
                  let image = json["image"] as? String,
                  let releaseDate = json["releaseDate"] as? String,
                  let jsonRuntimeMins = json["runtimeMins"] as? String,
                  let runtimeMins = Int(jsonRuntimeMins),
                  let directors = json["directors"] as? String,
                  let actorList = json["actorList"] as? [Any] else {
                return nil
            }
            
            var actors: [Actor] = []
            
            for actor in actorList {
                guard let actor = actor as? [String: Any],
                      let id = actor["id"] as? String,
                      let image = actor["image"] as? String,
                      let name = actor["name"] as? String,
                      let asCharacter = actor["asCharacter"] as? String else {
                    return nil
                }
                let mainActor = Actor(id: id,
                                      image: image,
                                      name: name,
                                      asCharacter: asCharacter)
                actors.append(mainActor)
            }
            
            movie = Movie(id: id,
                          title: title,
                          year: year,
                          image: image,
                          releaseDate: releaseDate,
                          runtimeMins: runtimeMins,
                          directors: directors,
                          actorList: actors)
        } catch {
            print("Failed to parse: \(jsonString)")
        }
        
        return movie
    }
    
    // MARK: - QuestionFactoryDelegate
    
    private func convert(model: QuizQuestion) -> QuizStepViewModel {
        let questionStep = QuizStepViewModel(
            image: UIImage(named: model.image) ?? UIImage(),
            question: model.text,
            questionNumber: "\(currentQuestionIndex + 1)/\(questionsAmount)")
        return questionStep
    }
    
    private func show(quiz result: QuizResultsViewModel) {
        _ = "Количество сыгранных квизов:\(String(describing: statisticService?.gamesCount) )"
        _ = "Ваш результат:\(correctAnswers)\(questionsAmount)"
        let alertModel = AlertModel(
            title: result.title,
            message:result.text,
            buttonText: result.buttonText,
            completion: { [weak self] _ in
                guard let self = self else { return }
                self.currentQuestionIndex = 0
                self.correctAnswers = 0
                self.questionFactory?.requestNextQuestion()
                
            }
        )
        alertPresenter?.showQuizResult(model: alertModel)
    }
    
    private func showAnswerResults(isCorrect: Bool) { //Функция показа результатов ответа
        imageView.layer.masksToBounds = true
        imageView.layer.borderWidth = 8
        imageView.layer.borderColor = isCorrect ? UIColor.ypGreen.cgColor : UIColor.ypRed.cgColor
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.showNextQuestionOrResults()
        }
        if isCorrect {
            correctAnswers += 1
        }
    }
    
    func switchToNextQuestion() {
        currentQuestionIndex += 1
    }
    
    func isLastQuestion() -> Bool {
        currentQuestionIndex == questionsAmount - 1
    }
    
    func restartGame() {
        currentQuestionIndex = 0
        correctAnswers = 0
        questionFactory?.requestNextQuestion()
    }
    
    private func show(quiz step: QuizStepViewModel) {
        imageView.image = step.image
        textLabel.text = step.question
        counterLabel.text = step.questionNumber
        
        
    }

    private func showNextQuestionOrResults() { //Функция показа следующнго вопроса или результата квиза 
        if self.isLastQuestion() {
            statisticService?.store(correct: correctAnswers, total: self.questionsAmount)
            
            guard let gamesCount = statisticService?.gamesCount else { return }
            guard let bestGame = statisticService?.bestGame else { return }
            guard let totalAccuracy = statisticService?.totalAccuracy else { return }
            
            let finalScreen = AlertModel (title: "Этот раунд окончен!",
                                          message: """
     Ваш результат: \(correctAnswers)/\(self.questionsAmount)
     Количество сыгранных квизов: \(gamesCount)
     Рекорд: \(bestGame.correct)/\(bestGame.total) (\(bestGame.date.dateTimeString))
     Средняя точность: \(String(format: "%.2f", totalAccuracy))%
     """ ,
                                          buttonText: "Сыграть еще раз",
                                          completion: { _ in [weak self] in
                guard let self = self else { return }
                
                self.restartGame()
                self.correctAnswers = 0
                
            })
            viewController?.alertPresenter?.showQuizResult(model: finalScreen)
        } else {
            self.switchToNextQuestion()
            questionFactory?.requestNextQuestion()
        }
    }
}



