//
//  RegistrationService.swift
//  OTP_Generator
//
//  Created by Wellysson Avelar on 08/11/20.
//

import Foundation
import Alamofire
import ObjectMapper

class RegistrationService {
    static var urlBase = "https://yawning-small-neontetra.gigalixirapp.com/api/activations"
    
    static func registrationStart(customer: Customer, completion: @escaping ((BaseResponse) -> Void)) {
        let parameters = customer.toJSON()
        
        Alamofire.request(self.urlBase, method: .post, parameters: parameters).responseJSON { response in
            
            if let json = response.result.value as? [String: Any] {
                if let baseResponse = Mapper<BaseResponse>().map(JSON: json) {
                    completion(baseResponse)
                }
            } else {
                let baseResponse = BaseResponse()
                completion(baseResponse)
            }
        }
    }
    
    static func registrationFinish(userId: String, device_id: String, otp: String, completion: @escaping ((BaseResponse) -> Void)) {
        var parameters = [String: Any]()
        parameters["device_id"] = device_id
        parameters["otp"] = otp
        let url = "\(self.urlBase)/\(userId)"
        
        Alamofire.request(url, method: .put, parameters: parameters).responseJSON { response in
            
            if let json = response.result.value as? [String: Any] {
                if let baseResponse = Mapper<BaseResponse>().map(JSON: json) {
                    completion(baseResponse)
                }
            } else {
                let baseResponse = BaseResponse()
                completion(baseResponse)
            }
        }
    }
    
    static func validation(userId: String, device_id: String, otp: String, completion: @escaping ((BaseResponse) -> Void)) {
        var parameters = [String: Any]()
        parameters["device_id"] = device_id
        parameters["otp"] = otp
        let url = "\(self.urlBase)/\(userId)/check"
        
        Alamofire.request(url, method: .post, parameters: parameters).responseJSON { response in
            
            if let json = response.result.value as? [String: Any] {
                if let baseResponse = Mapper<BaseResponse>().map(JSON: json) {
                    completion(baseResponse)
                }
            } else {
                let baseResponse = BaseResponse()
                completion(baseResponse)
            }
        }
    }
}
