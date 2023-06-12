

import Foundation
import UIKit

class AlertPresenter {
    func presenter (contoller: UIViewController, model: AlertModel) {
            let alert = UIAlertController(
                title: model.title,
                message: model.message,
                preferredStyle: .alert)
            
            let action = UIAlertAction(title: model.buttonText, style: .default, handler: model.completion)
            
            alert.addAction(action)
            
            contoller.present(alert, animated: true, completion: nil)
        }
    }

