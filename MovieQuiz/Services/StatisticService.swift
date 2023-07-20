
import Foundation

protocol StatisticService {
    var totalAccuracy: Double { get }
    var gamesCount: Int { get }
    var bestGame: GameRecord { get }
    func store(correct count: Int, total amount: Int)
}

final class StatisticServiceImplementation: StatisticService {
    private let userDefaults = UserDefaults.standard
    private enum Keys: String {
        case correct, total, bestGame, gamesCount
    }
    
    var gamesCount: Int = 0
    
    
    var bestGame: GameRecord {
        get {
            guard let data = userDefaults.data(forKey: Keys.bestGame.rawValue),
                  let record = try? JSONDecoder().decode(GameRecord.self, from: data) else {
                return .init(correct: 0, total: 0, date: Date())
            }
            
            return record
        }
        
        set {
            guard let data = try? JSONEncoder().encode(newValue) else {
                print("Невозможно сохранить результат")
                return
            }
            
            userDefaults.set(data, forKey: Keys.bestGame.rawValue)
        }
    }
    
    func store(correct count: Int, total amount: Int) {
        gamesCount += 1
        if bestGame.correct < count   {
            print (GameRecord(correct: count, total: amount, date: Date()))
        } else {
            bestGame.correct
        }
        
    }
    var correct: Int {
        get
        { userDefaults.integer(forKey: Keys.total.rawValue) }
        set
        { userDefaults.set(newValue, forKey: Keys.total.rawValue) }
    }
    var total: Int {
        get
        { userDefaults.integer(forKey: Keys.total.rawValue) }
        set
        { userDefaults.set(newValue, forKey: Keys.total.rawValue) }
        
    }
        
    var totalAccuracy: Double {
        if total == 0 { return 0 }
        return (Double(total) /
        Double(correct)) * 100
        }
        
    
}
