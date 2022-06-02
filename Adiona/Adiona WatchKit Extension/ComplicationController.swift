//
//  ComplicationController.swift
//  Adiona WatchKit Extension
//
//  Created by Ken Franklin on 5/25/22.
//

import ClockKit
import SwiftUI

class ComplicationController: NSObject, CLKComplicationDataSource {
    // MARK: - Complication Configuration

    let dataController = HealthDataManager.shared

    func getComplicationDescriptors(handler: @escaping ([CLKComplicationDescriptor]) -> Void) {
        let descriptors = [
            CLKComplicationDescriptor(
                identifier: "complication",
                displayName: "Adiona",
                supportedFamilies: CLKComplicationFamily.allCases)
        ]
        handler(descriptors)
    }

    // MARK: - Timeline Configuration

    func getTimelineEndDate(
        for complication: CLKComplication,
        withHandler handler: @escaping (Date?) -> Void)
    {
        handler(dataController.lastUpload.addingTimeInterval(HealthDataManager.fifteenMinutes))
    }

    func getPrivacyBehavior(
        for complication: CLKComplication,
        withHandler handler: @escaping (CLKComplicationPrivacyBehavior) -> Void)
    {
        handler(.showOnLockScreen)
    }

    // MARK: - Timeline Population

    func getCurrentTimelineEntry(
        for complication: CLKComplication,
        withHandler handler: @escaping (CLKComplicationTimelineEntry?) -> Void)
    {
        if let ctemplate = makeTemplate(for: dataController, using: Date(), complication: complication)
        {
            let entry = CLKComplicationTimelineEntry(
                date: dataController.lastUpload,
                complicationTemplate: ctemplate)
            handler(entry)
        } else {
            handler(nil)
        }
    }

    func getTimelineEntries(
        for complication: CLKComplication,
        after date: Date,
        limit: Int,
        withHandler handler: @escaping ([CLKComplicationTimelineEntry]?) -> Void)
    {
        var entries: [CLKComplicationTimelineEntry] = []
    
        let oneMinute = 60.0

        // Calculate the start and end dates.
        var current = dataController.lastUpload.addingTimeInterval(oneMinute)
        let endDate = dataController.lastUpload.addingTimeInterval(HealthDataManager.fifteenMinutes)

        // Create a timeline entry for every minute from the starting time.
        // Stop once you reach the limit or the end date.
        while current < endDate && entries.count < limit {
            if let ctemplate = makeTemplate(for: dataController, using: current, complication: complication) {
                let entry = CLKComplicationTimelineEntry(
                    date: current,
                    complicationTemplate: ctemplate)

                entries.append(entry)
                current = current.addingTimeInterval(oneMinute)
            }
        }
        
        handler(entries)
    }

    func getLocalizableSampleTemplate(
        for complication: CLKComplication,
        withHandler handler: @escaping (CLKComplicationTemplate?) -> Void)
    {
        let ctemplate = makeTemplate(for: dataController, complication: complication)
        handler(ctemplate)
    }
}

extension ComplicationController {
    func makeTemplate(
        for session: HealthDataManager,
        using date: Date? = nil,
        complication: CLKComplication) -> CLKComplicationTemplate?
    {
        switch complication.family {
        case .circularSmall:
            return makeCircularSmall(session: session)
        case .graphicCircular:
            return CLKComplicationTemplateGraphicCircularView(
                ComplicationViewCircular(session: session))
        case .graphicCorner:
            return CLKComplicationTemplateGraphicCornerCircularView(
                ComplicationViewCornerCircular(session: session))
        case .utilitarianSmall:
            return makeUtilitarianSmall(session: session)
        case .utilitarianSmallFlat:
            return makeUtilitarianSmallFlat(session: session)
        case .utilitarianLarge:
            return makeUtilitarianLargeFlat(session: session, fromDate: date)
        case .graphicExtraLarge:
            guard #available(watchOSApplicationExtension 7.0, *) else {
                return nil
            }
            return CLKComplicationTemplateGraphicExtraLargeCircularView(
                ComplicationViewExtraLargeCircular(
                    session: session))
        default:
            print(complication.family.rawValue)
            return nil
        }
    }
}

extension ComplicationController {
    func makeUtilitarianLargeFlat(session: HealthDataManager, fromDate: Date? = nil) -> CLKComplicationTemplateUtilitarianLargeFlat {
        if let fromDate = fromDate {
            let date = session.lastUpload
            let difference = Int((fromDate.timeIntervalSince1970 - date.timeIntervalSince1970) / 60)
            let textProvider = CLKTextProvider(format: "\(session.stateDescription) for \(difference)m")
            let complication = CLKComplicationTemplateUtilitarianLargeFlat(
                textProvider: textProvider)
            return complication
        } else {
            let textProvider = CLKTextProvider(format: "\(session.stateDescription) for \(session.timeRemaining())")
            let complication = CLKComplicationTemplateUtilitarianLargeFlat(
                textProvider: textProvider)
            return complication
        }
    }
    
    func makeUtilitarianSmallFlat(session: HealthDataManager) -> CLKComplicationTemplateUtilitarianSmallFlat {
        let textProvider = CLKTextProvider(format: "\(session.timeRemaining())")
        let imageProvider = CLKImageProvider(onePieceImage: UIImage(named: "uchicago")!)
        return CLKComplicationTemplateUtilitarianSmallFlat(textProvider: textProvider, imageProvider: imageProvider)
    }

    func makeUtilitarianSmall(session: HealthDataManager) -> CLKComplicationTemplateUtilitarianSmallRingText {
        let textProvider = CLKTextProvider(format: "\(session.timeRemaining())")
        return CLKComplicationTemplateUtilitarianSmallRingText(textProvider: textProvider, fillFraction: 0.3, ringStyle: .closed)
    }

    func makeCircularSmall(session: HealthDataManager) -> CLKComplicationTemplateCircularSmallRingText {
        let textProvider = CLKTextProvider(format: "\(session.minutesRemaining())")
        let complication = CLKComplicationTemplateCircularSmallRingText(textProvider: textProvider, fillFraction: 0.3, ringStyle: .closed)
        return complication
    }
}
