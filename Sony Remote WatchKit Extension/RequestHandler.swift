//
//  RequestHandler.swift
//  Sony Remote WatchKit Extension
//
//  Created by Marius Ghita on 12.12.2020.
//

import Foundation

typealias FetchRemoteCommandsCompleteClosure = (_: [[String: String]]?, _: RequestError?) -> Void
typealias SendRemoteCommandCompleteClosure = (_: RequestError?) -> Void

enum ErrorCode: Int {
    case Default = 0
    case Credentials = 1
    case Cancelled = 2
}

struct RequestError: Identifiable {
    var id: String
    var errorMessage: String!
    var code: ErrorCode

    init(error: String) {
        id = UUID().uuidString
        errorMessage = error
        code = ErrorCode.Default
    }
    
    init(error: String, code: ErrorCode) {
        id = UUID().uuidString
        errorMessage = error
        self.code = code
    }
}

class RequestHandler {
    var requestCommands: [[String: String]]?
    var tasks: [URLSessionTask] = []
    
    func getRemoteCommands(fullReload: Bool, onComplete: FetchRemoteCommandsCompleteClosure!) {
        guard !fullReload, let requestCommands = requestCommands, requestCommands.count > 0 else {
            fetchRemoteCommands { (commands, error) in
                self.requestCommands = commands
                onComplete(commands, error)
            }
            
            return
        }
        
        onComplete(requestCommands, nil)
    }

    func fetchRemoteCommands(onComplete: FetchRemoteCommandsCompleteClosure!) {
        let tvIp = getTvIpInput()
        
        guard tvIp.count > 0 else {
            onComplete?(nil, RequestError(error: "Please add your TV connection details!", code: .Credentials))
            return
        }
        
        guard let url = URL(string: "http://\(tvIp)/sony/system") else {
            print("Invalid URL")
            return
        }
        
        let data = [
            "method": "getRemoteControllerInfo",
            "params": [],
            "id": 54,
            "version": "1.0"
        ] as [String : Any]
        
        let jsonData = try? JSONSerialization.data(withJSONObject: data)
        var request = URLRequest(url: url)
        request.httpBody = jsonData
        request.httpMethod = "POST"
        cancelOngoingRequests()
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                if let error = error as NSError?, error.code == NSURLErrorCancelled {
                    print("cancelled")
                    onComplete?(nil, RequestError(error: error.localizedDescription, code: .Cancelled))
                } else {
                    onComplete?(nil, RequestError(error: error.localizedDescription))
                }
            } else if let data = data,
                      let responseJson = try? JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: Any],
                      let responseArray = (responseJson["result"] as? [Any]),
                      let responseArrayUnwrapped = responseArray[1] as? [[String: String]] {
                print(responseArrayUnwrapped)
                onComplete?(responseArrayUnwrapped, nil)
            }
        }
        
        task.resume()
        tasks.append(task)
    }
    
    func sendRemoteCommand(command: String, onComplete: SendRemoteCommandCompleteClosure? = nil) {
        guard let hash = commandHashForKey(key: command) else {
            onComplete?(RequestError(error: "Command not found for this TV!"))
            return
        }
        
#if DEBUG
        // Fake success
        let deadlineTime = DispatchTime.now() + .seconds(1)
        DispatchQueue.main.asyncAfter(deadline: deadlineTime) {
            onComplete?(nil)
        }
#else
        guard let url = URL(string: "http://\(getTvIpInput())/sony/IRCC") else {
            print("Invalid URL")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpBody = "<?xml version=\"1.0\"?><s:Envelope xmlns:s=\"http://schemas.xmlsoap.org/soap/envelope/\" s:encodingStyle=\"http://schemas.xmlsoap.org/soap/encoding/\"><s:Body><u:X_SendIRCC xmlns:u=\"urn:schemas-sony-com:service:IRCC:1\"><IRCCCode>\(hash)</IRCCCode></u:X_SendIRCC></s:Body></s:Envelope>".data(using: .utf8)
        request.setValue("text/xml; charset=UTF-8", forHTTPHeaderField: "Content-Type")
        request.setValue(getTvPskInput(), forHTTPHeaderField: "X-Auth-PSK")
        request.setValue("\"urn:schemas-sony-com:service:IRCC:1#X_SendIRCC\"", forHTTPHeaderField: "SOAPACTION")
        request.httpMethod = "POST"

        cancelOngoingRequests()
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                if let error = error as NSError?, error.code == NSURLErrorCancelled {
                    print("cancelled")
                    onComplete?(RequestError(error: error.localizedDescription, code: .Cancelled))
                } else {
                    onComplete?(RequestError(error: error.localizedDescription))
                }
            } else {
                onComplete?(nil)
            }
        }

        task.resume()
        tasks.append(task)
#endif
    }
    
    func cancelOngoingRequests() {
        tasks.forEach { (task) in
            task.cancel()
        }
        
        tasks.removeAll()
    }
    
    func commandHashForKey(key: String) -> String? {
        guard let result = requestCommands?.first(where: { (entry: [String : String]) -> Bool in
            return entry["name"] == key
        }) else {
            return nil
        }
        
        return result["value"]
    }

    func getTvIpInput() -> String {
        guard let tvIp = UserDefaults.standard.string(forKey: "tvIp") else {
            return ""
        }
        
        return tvIp
    }
    
    func getTvPskInput() -> String {
        guard let tvPsk = UserDefaults.standard.string(forKey: "tvPsk") else {
            return ""
        }
        
        return tvPsk
    }
    
    func setTvIpInput(ip: String) {
        UserDefaults.standard.setValue(ip, forKey: "tvIp")
    }
    
    func setTvPskInput(psk: String) {
        UserDefaults.standard.setValue(psk, forKey: "tvPsk")
    }
}
