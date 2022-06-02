//
//  UIHelper.swift
//  Adiona WatchKit Extension
//
//  Created by Ken Franklin on 6/2/22.
//

import Foundation

struct Action: Identifiable, Hashable {
    static func == (lhs: Action, rhs: Action) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    let id = UUID()
    let name: String
    let block: () -> Void
}
