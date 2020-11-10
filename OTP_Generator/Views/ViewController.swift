//
//  ViewController.swift
//  OTP_Generator
//
//  Created by Wellysson Avelar on 06/11/20.
//

import UIKit
import OneTimePassword
import Base32
import SwiftyRSA

class ViewController: UIViewController {
    @IBOutlet weak var countLabel: UILabel!
    @IBOutlet weak var keyLabel: UILabel!
    
    let userId = "05111620656"
    let device_id = "myphone"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        self.startActivation()
    }


    func startActivation() {
        let customer = Customer()
        customer.customer_id = self.userId
        customer.device_id = self.device_id
        customer.registration = Registration()
        customer.registration?.public_key = "-----BEGIN PUBLIC KEY-----\nMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA7QMQLb8nBZ5qKgBMNj3y\njlN1Qz8UAWcHnNzuKFF6yNoryWt7wDxt3eDYzqVfN5wK2r2xCaxNSO2AFeXShbOY\neIcxAOauRsBIAHkhlrr62Z8m5CXsaX9FmwQ2wHo6nlJ3eKso/qH5vfDJJ/JLtlmh\nzOoe1CxGj86Cjs2wvTgtcT6MR2+1LzHllcqSbsd23LPgodYmuAjKjrMzJAIyojCS\nZD2MbtMyXACaaIwmRJm3DuRRrsN0ZdSS/Ata/WWMu1g94yVIrMbvF3ikkw6KVEdD\nECYju6wp56hv2F6GkyHWauMsXFhFHqZaYBtrKJru4Ts+52FxFmIeT33DEcJGjkwX\nGwIDAQAB\n-----END PUBLIC KEY-----"
        customer.registration?.device_id = "myphone"
        customer.registration?.os_name = "iOS"
        customer.registration?.os_version = "10.3"
        customer.registration?.app_version = "1234"
        
        RegistrationService.registrationStart(customer: customer, completion: { [weak self] baseResponse in
            guard let self = self else { return }
            let secret = baseResponse.secret ?? ""
            print(secret)
            
            if let secretDecript = self.getDecrypt(base64Encoded: secret) {
                if let key = self.createKey(secret: secretDecript) {
                
                    self.finishActivation(key: key)
                }
            }
        })
    }
    
    func finishActivation(key: Token) {
        RegistrationService.registrationFinish(userId: self.userId, device_id: self.device_id, otp: key.currentPassword ?? "", completion: { [weak self] baseResponse in
            guard let self = self else { return }
            
            print("\(baseResponse.status ?? "") - \(baseResponse.message ?? "")")
            
            var count = 0
            var oldPassword = ""
            Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self, key] timer in
                guard let self = self else { return }
                
                count = count + 1
                if let currentPassword = key.currentPassword, currentPassword != oldPassword {
                    if oldPassword != "" {
                        self.validation(otp: oldPassword, onValidate: { [weak self] isValid in
                            guard let self = self else { return }
                            self.keyLabel.text = "Old OTP: \(oldPassword), Validate: \(isValid)\n"
                            
                            self.validation(otp: currentPassword, onValidate: { [weak self] isValid in
                                guard let self = self else { return }
                                self.keyLabel.text! += "Current OTP: \(currentPassword), Validate: \(isValid)"
                                oldPassword = key.currentPassword ?? ""
                            })
                        })
                    } else {
                        self.validation(otp: currentPassword, onValidate: { [weak self] isValid in
                            guard let self = self else { return }
                            self.keyLabel.text! += "Current OTP: \(currentPassword), Validate: \(isValid)"
                            oldPassword = key.currentPassword ?? ""
                        })
                    }
                    count = 0
                }
                
                self.countLabel.text =  "Countdown: \(self.getTineToEndValidate(key: key, currentPassword: key.currentPassword ?? ""))"
                
                print(key.currentPassword ?? "Vazio")
                
            }
        })
    }
    
    func getTineToEndValidate(key: Token, currentPassword: String) -> Int {
        
        var idDiferent = true
        var time = 0
        while idDiferent {
            do {
                let nextPassword = try key.generator.password(at: Date().addingTimeInterval(TimeInterval(time)))
                                                              
                if currentPassword != nextPassword {
                    idDiferent = false
                } else {
                    time += 1
                }
            } catch {
            }
        }
        
        return time
    }
    
    func validation(otp: String, onValidate: @escaping ((_ isValid: Bool) -> Void)) {
        RegistrationService.validation(userId: self.userId, device_id: self.device_id, otp: otp, completion: { [onValidate] baseResponse in
            
            print("\(otp): \(baseResponse.status ?? "") - \(baseResponse.message ?? "")")
            
            let isValid = baseResponse.status?.lowercased() == "ok"
            onValidate(isValid)
        })
    }
    
    func encriptMessage(message: String) -> String? {
        let pbKey = "-----BEGIN PUBLIC KEY-----\nMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA7QMQLb8nBZ5qKgBMNj3y\njlN1Qz8UAWcHnNzuKFF6yNoryWt7wDxt3eDYzqVfN5wK2r2xCaxNSO2AFeXShbOY\neIcxAOauRsBIAHkhlrr62Z8m5CXsaX9FmwQ2wHo6nlJ3eKso/qH5vfDJJ/JLtlmh\nzOoe1CxGj86Cjs2wvTgtcT6MR2+1LzHllcqSbsd23LPgodYmuAjKjrMzJAIyojCS\nZD2MbtMyXACaaIwmRJm3DuRRrsN0ZdSS/Ata/WWMu1g94yVIrMbvF3ikkw6KVEdD\nECYju6wp56hv2F6GkyHWauMsXFhFHqZaYBtrKJru4Ts+52FxFmIeT33DEcJGjkwX\nGwIDAQAB\n-----END PUBLIC KEY-----"

        do {
            // Then you use that public key in your pem file
            let publicKey = try PublicKey(pemEncoded: pbKey)
            let clear = try ClearMessage(string: message, using: .utf8)
            let encrypted = try clear.encrypted(with: publicKey, padding: .OAEP)
            print(encrypted.base64String)
        } catch let error {
            print(error.localizedDescription)
        }
        
        return nil
    }
    
    func getDecrypt(base64Encoded: String) -> String? {
        do {
            let privateKey_ = "-----BEGIN RSA PRIVATE KEY-----\nMIIEowIBAAKCAQEA7QMQLb8nBZ5qKgBMNj3yjlN1Qz8UAWcHnNzuKFF6yNoryWt7\nwDxt3eDYzqVfN5wK2r2xCaxNSO2AFeXShbOYeIcxAOauRsBIAHkhlrr62Z8m5CXs\naX9FmwQ2wHo6nlJ3eKso/qH5vfDJJ/JLtlmhzOoe1CxGj86Cjs2wvTgtcT6MR2+1\nLzHllcqSbsd23LPgodYmuAjKjrMzJAIyojCSZD2MbtMyXACaaIwmRJm3DuRRrsN0\nZdSS/Ata/WWMu1g94yVIrMbvF3ikkw6KVEdDECYju6wp56hv2F6GkyHWauMsXFhF\nHqZaYBtrKJru4Ts+52FxFmIeT33DEcJGjkwXGwIDAQABAoIBAQCGJ/24Z0LHQ2wE\naja5XUc2mLb/YW0JfjAo8kU8PSKrHhM658QchBgMR4FxNto2t/TM7CKRvx3f8c9W\nlcgcNhRP5PYv9GMhWSVoXyhMEXp8REHXUkAHVysnG7OCL62OgE9v1jJWL4kVon26\nRsPka8fSHZNltcobDGGKQ5OPB4VxW0dMChHg2YKp8GUHFzQjS13FE08z5HJ2GsTv\nRpJB5OS7R92G0mq1yMO7/nX1kfnx+Ko6wG/iBxCJDh9kdKwDqiov4ExtRIEpMTnt\nAiM6rS7YZAlsW/Ynrxbp7p2w8oXaNOwkkszFbM0cgjxjMzW7diR1aAOi6+Q3LJWL\naOuMWGgBAoGBAPxLgwlJyLHG0X2Dk9Q23sGO3iPXephw1d5j9yv8tACpH5ErzLku\ngknc3xykZdlkm0e0GqrAqA7wi3WqUDJ6ovsETJanXYoO+NArPOzgB58BE76gfeuz\nWi7KmdBSnlWbJ70s8ZrulAaafRxIPqwP1/ZjZcFaJr8JJpP7BYIfP3ubAoGBAPB+\nGIVlXCYl9bidRhuXbTZebkrt5AAivfOuIaaUw6/RcdZIDLOIAr+Xa4wcJS8R5JYh\nArQY15aJ73fiYCgC1RNuwcEcGIaPd3jFsyN3VmBHsgtVxkTN28Md9iAzCpsO0N3P\n19UHGKieJitI7WWNkMZ52WUg/W9Dkxt9b19r/EqBAoGAB1hbdEXFpgdXygOuphsC\n2TfDl9+KHi4Ky/K1G3677tj9pkhUKYAFIwlfJYJTxMR9ENVZgWcifWzbYo2W0CFp\n5Uz2vdwZiQ9uhwD7QRo0nph1brNVdys9kOctGzeMjIl72rIYRp5ziM2unsgrqu67\nJt019S8euakWinBgdK1cN8kCgYAv01O7C3o01+2yxgwQJqAAZO0YF5D0+fO+hw2I\nHCOCTmuOCowEE/M/+LPZjCtU3gEQXgY0nJAbDtlBhRJMQqvvDmKXraeu8s72hJJo\nZi4WPYvJt0gTnMCsX8P3iU79oQemZNPuOFgOCE1c5EbZoDp/TfIOq23a95xEpkBE\nwKvOgQKBgEX/VpVhjU0OguW3IbaTlGbr9AyJkHTXClJg31oQxDKT1kXOooE+++lm\nrhU3mpVFv5wC9nBzf6uDQTp5kIZe7dVhPrzCz2l7qOM6MMA7nBB6JfePkB7FvbTW\n5r6OIAiFMd4A2OMyok5Jq8MTylfBtDdseaSVQyQbo6H2aLwDT4O+\n-----END RSA PRIVATE KEY-----"
            
            let privateKey = try PrivateKey(pemEncoded: privateKey_) //PrivateKey(pemNamed: privateKey_)
            let encrypted = try EncryptedMessage(base64Encoded: base64Encoded)
            let clear = try encrypted.decrypted(with: privateKey, padding: .PKCS1)

            // Then you can use:
//            let data = clear.data
//            let base64String = clear.base64String
            let string = try clear.string(encoding: .utf8)
            
            return string
        } catch let error {
            print("erro decrypt:" + error.localizedDescription)
        }
        
        return nil
    }
    
    func createKey(secret: String) -> Token? {
        let name = "..."
        let issuer = "..."
        let secretString = secret

        guard let secretData = MF_Base32Codec.data(fromBase32String: secretString),
            !secretData.isEmpty else {
                print("Invalid secret")
                return nil
        }

        guard let generator = Generator(
            factor: .timer(period: 30),
            secret: secretData,
            algorithm: .sha1,
            digits: 6) else {
                print("Invalid generator parameters")
                return nil
        }

        let token = Token(name: name, issuer: issuer, generator: generator)
        return token
    }
}

