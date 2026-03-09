//
//  AppSettings+Helpers.swift
//  StayConnected
//
//  Created by Anuj Patel on 9/28/25.
//

import CoreData

// MARK: - AppSettings Helpers

extension AppSettings {
    static func fetchOrCreate(
        in ctx: NSManagedObjectContext
    ) throws -> AppSettings {

        let req: NSFetchRequest<AppSettings> = AppSettings.fetchRequest()
        req.fetchLimit = 1

        if let existing = try ctx.fetch(req).first {
            return existing
        }

        let s = AppSettings(context: ctx)
        s.id = UUID()
        s.picksPerDay = 2
        s.minGapDays = 20

        try ctx.save()

        return s
    }
}
