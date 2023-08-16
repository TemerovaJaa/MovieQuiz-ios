

import Foundation

/// Отвечает за загрузку данных по URL
struct NetworkClient {
    func fetch(url: URL, handler: @escaping (Result<Data, Error>) -> Void) {
    }
    
    struct NetworkClient: NetworkRouting {
        
        private enum NetworkError: Error { //Тут мы создали свою реализацию протокола Error, чтобы обозначить его на тот случай, если произойдёт ошибка
            case codeError
        }
        
        func fetch(url: URL, handler: @escaping (Result<Data, Error>) -> Void) { //Эта функция, которая будет загружать что-то по заранее заданному URL. Так как все запросы с API IMDb — это GET запросы, то их дополнительные настройки нам не нужны, только адрес  Result<Data, Error> означает, что нам вернётся либо «успех» с данными типа Data, либо ошибка.
            let request = URLRequest(url: url) //Тут мы создали запрос из url, и теперь начинаем писать обработку ответа. Как уже было сказано, в ответе все аргументы data, response, error — опциональные: чтобы понять, какой ответ нам пришёл, надо их распаковать.
            
            let task = URLSession.shared.dataTask(with: request) { data, response, error in
                // Проверяем, пришла ли ошибка
                if let error = error { //Здесь мы распаковываем ошибку. Если ошибка оказалась не пустой, значит, что-то пошло не так и ответ от сервера не получен. Тогда мы считаем, что результат у нас не успешный и возвращаем .failure(error).
                    handler(.failure(error))
                    return
                }
                
                // Проверяем, что нам пришёл успешный код ответа
                if let response = response as? HTTPURLResponse,
                   response.statusCode < 200 || response.statusCode >= 300 {
                    handler(.failure(NetworkError.codeError))
                    return
                } //Если мы дошли до этого кода, значит, сервер прислал нам ответ. Он может быть не всегда успешным. Узнать это можно по коду ответа. Код ответа 200 — это успешный ответ. Но и любой код меньше 300 — тоже успешный ответ, только с дополнительными комментариями. Здесь мы как раз это и проверяем.
                
                // Возвращаем данные
                guard let data = data else { return }
                handler(.success(data))
            }
            
            task.resume()
        }
    }
}
