//
//  TranslationServiceConfigManager.swift
//  
//
//  Created by Alexander Wodarz on 06.11.23.
//

public class TranslationServiceConfigManager {
    public static var shared = TranslationServiceConfigManager()
    
    public var configuration: TranslationServiceConfiguration?
    
    public func setConfiguration(repositoryID: String, fallbackLocale: String) {
        configuration = TranslationServiceConfiguration(repositoryID: repositoryID, fallbackLocale: fallbackLocale)
    }
}
