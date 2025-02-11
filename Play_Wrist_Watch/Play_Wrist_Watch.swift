//
//  Play_Wrist_Watch.swift
//  Play_Wrist_Watch
//
//  Created by 김현수 on 2/11/25.
//

import AppIntents

struct Play_Wrist_Watch: AppIntent {
    static var title: LocalizedStringResource { "Play_Wrist_Watch" }
    
    func perform() async throws -> some IntentResult {
        return .result()
    }
}
