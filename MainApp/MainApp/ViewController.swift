//
//  ViewController.swift
//  MainApp
//
//  Created by Wellysson Avelar on 10/11/20.
//

import UIKit
import OTPGenerator

class ViewController: UIViewController {
    
    @IBOutlet weak var countdownLabel: UILabel!
    @IBOutlet weak var keyLabel: UILabel!
    
    @IBOutlet weak var keyTextField: UITextField!
    @IBOutlet weak var validatorLabel: UILabel!
    
    var secret: String? = PreferencesManager.getObject("OTP_KEY")
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        OTPHelper.otp?.getStatus(completion: { isOn in
            print("Is ON: \(isOn)")
        })
        
        if let secret = self.secret {
            OTPHelper.otp?.createToken(secret: secret)
            
            self.setKeyAndTimer()
        } else {
            OTPHelper.otp?.startActivation(completion: { secretDecript in
                PreferencesManager.saveObject("OTP_KEY", value: secretDecript)
                self.secret = secretDecript
                
                self.setKeyAndTimer()
            })
        }
    }
    
    @IBAction func ValidateAction(sender: Any) {
        let secret = self.keyTextField.text ?? ""
        
        OTPHelper.otp?.validation(otp: secret, onValidate: { [weak self] isValid in
            guard let self = self else { return }
            
            if isValid {
                self.validatorLabel.text = "Valido"
                self.validatorLabel.textColor = .blue
            } else {
                self.validatorLabel.text = "Inválido"
                self.validatorLabel.textColor = .red
            }
        })
    }
    
    func setKeyAndTimer() {
        Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] timer in
            guard let self = self else { return }
            
            self.countdownLabel.text = "\(OTPHelper.otp?.getTimeToEndValidate() ?? 0)"
            self.keyLabel.text = OTPHelper.otp?.getCurrentKey()
            if self.keyLabel.text != self.keyTextField.text {
                self.keyTextField.text = OTPHelper.otp?.getCurrentKey()
                self.validatorLabel.text = ""
            }
        }
    }
}

