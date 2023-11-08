//
//  TranslationService.swift
//
//
//  Created by Alexander Wodarz on 06.11.23.
//
import Foundation


public class TranslationService {
    public init() {}
    
    public func translate(text: String, fallback: String) -> String {
        
        guard let config = TranslationServiceConfigManager.shared.configuration else {
            print("use fallback")
            return fallback
        }
        
        let repositoryID = config.repositoryID
        
        let text = UserDefaults.standard.data(forKey: "translation-\(text)")
        
        if (text == nil) {
            return fallback
        }
        var code = Locale(identifier: Locale.preferredLanguages.first!).languageCode!
        
        var result = fallback
        if let translationDictionary = try! JSONSerialization.jsonObject(with: text!, options: []) as? [String: String] {
            // Jetzt kannst du auf die Übersetzungen zugreifen
            if let translation = translationDictionary[code] {
                result = translation
            } else if let fallbackTranslation = translationDictionary[config.fallbackLocale] {
                result = fallbackTranslation
            }
        }
        
        return result
    }
    
    public func translate(text: String) -> String {
        return translate(text: text, fallback: "")
    }
    
    public func getLocalVersion() -> String {
        if let version = UserDefaults.standard.string(forKey: "translation_version") {
            return version
        }
        return ""
    }
    
    private func needFetch(completionHandler: @escaping (NeedFetchResult) -> Void) {
        var localVersion = getLocalVersion()
        let semaphore = DispatchSemaphore(value: 1)
        sendAuthenticatedGETRequest(to: "https://translate.alexanderwodarz.de/api/library/version", authorizationToken: TranslationServiceConfigManager.shared.configuration!.repositoryID) { result in
            switch(result) {
            case .success(let jsonDictionary):
                let need = String(describing: jsonDictionary!["version"]!) != localVersion
                if (need) {
                    completionHandler(NeedFetchResult(required: true, version: String(describing: jsonDictionary!["version"]!)))
                } else {
                    completionHandler(NeedFetchResult(required: false))
                }
            case .failure(let error):
                print("Fehler beim Anfordern der Daten: \(error.localizedDescription)")
            }
            semaphore.signal()
        }
        
    }
    
    public func loadTranslations(completionHandler: @escaping () -> Void) {
        needFetch() { needFetch in
            if(!needFetch.required) {
                completionHandler()
                return
            }
            sendAuthenticatedGETRequest(to: "https://translate.alexanderwodarz.de/api/library/list", authorizationToken:  TranslationServiceConfigManager.shared.configuration!.repositoryID) { result in
                
                switch result {
                case .success(let jsonDictionary):
                    if let jsonDictionary = jsonDictionary {
                        for (key, _) in jsonDictionary {
                            let jsonData = try! JSONSerialization.data(withJSONObject: (jsonDictionary[key]!), options: [])
                            UserDefaults.standard.setValue(jsonData, forKey: "translation-\(key)")
                        }
                        UserDefaults.standard.setValue(needFetch.version!, forKey: "translation_version")
                    }
                case .failure(let error):
                    print("Fehler beim Anfordern der Daten: \(error.localizedDescription)")
                }
                completionHandler()
            }
        }
    }
    
}

class NeedFetchResult {
    var required: Bool
    var version: String?
    
    init(required: Bool, version: String? = nil) {
        self.required = required
        self.version = version
    }
    
    func setVersion(version: String) {
        self.version = version
    }
    
    func setRequired(required: Bool) {
        self.required = required
    }
    
}

func sendAuthenticatedGETRequest(to url: String, authorizationToken: String, completionHandler: @escaping (Result<[String: Any]?, Error>) -> Void) {
    // Erstelle die URL aus der gegebenen Zeichenkette
    guard let apiUrl = URL(string: url) else {
        completionHandler(.failure(NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Ungültige URL"])))
        return
    }
    
    // Erstelle die URLRequest und setze den Autorisierungs-Header
    var request = URLRequest(url: apiUrl)
    request.httpMethod = "GET"
    request.setValue("\(authorizationToken)", forHTTPHeaderField: "Authorization")
    
    // Erstelle die URLSession
    let session = URLSession.shared
    
    // Führe die Anfrage aus und verarbeite die Antwort
    let task = session.dataTask(with: request) { (data, response, error) in
        if let error = error {
            completionHandler(.failure(error))
            return
        }
        
        // Überprüfe, ob die Antwort erfolgreich ist (z. B. HTTP-Statuscode 200)
        if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
            if let data = data {
                do {
                    // Parsen der Daten in ein [String: Any]-Dictionary
                    if let jsonDictionary = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                        completionHandler(.success(jsonDictionary))
                    } else {
                        completionHandler(.failure(NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Ungültiges JSON-Format"])))
                    }
                } catch {
                    completionHandler(.failure(error))
                }
            } else {
                completionHandler(.success(nil)) // Leeres Dictionary, wenn keine Daten vorhanden sind
            }
        } else {
            completionHandler(.failure(NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Ungültige Serverantwort"])))
        }
    }
    
    task.resume()
}

