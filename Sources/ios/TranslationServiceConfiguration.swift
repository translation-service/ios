//
//  TranslationServiceConfiguration.swift
//  
//
//  Created by Alexander Wodarz on 06.11.23.
//

public struct TranslationServiceConfiguration {
    public var repositoryID: String
    public var fallbackLocale: String
    
    public init(repositoryID: String, fallbackLocale: String) {
        self.repositoryID = repositoryID
        self.fallbackLocale = fallbackLocale
    }
}
