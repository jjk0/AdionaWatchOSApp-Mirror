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

    let dataController = SessionData.shared

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
        handler(dataController.orderedSessions.last?.date)
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
        if let next = dataController.activeSession,
           let ctemplate = makeTemplate(for: next, complication: complication)
        {
            let entry = CLKComplicationTimelineEntry(
                date: next.date,
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
        if let next = dataController.activeSession,
               let ctemplate = makeTemplate(for: next, complication: complication)
            {
                let entry = CLKComplicationTimelineEntry(
                    date: next.date,
                    complicationTemplate: ctemplate)
                entries.append(entry)
            }
        
        handler(entries)
    }

    func getLocalizableSampleTemplate(
        for complication: CLKComplication,
        withHandler handler: @escaping (CLKComplicationTemplate?) -> Void)
    {
        let session = dummyData
        let ctemplate = makeTemplate(for: session, complication: complication)
        handler(ctemplate)
    }
}

extension ComplicationController {
    func makeTemplate(
        for session: Session,
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
            return makeUtilitarianLargeFlat(session: session)
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
    func makeUtilitarianLargeFlat(session: Session) -> CLKComplicationTemplateUtilitarianLargeFlat {
        let textProvider = CLKTextProvider(format: "\(session.description) for \(session.timeRemaining())")
        let complication = CLKComplicationTemplateUtilitarianLargeFlat(
            textProvider: textProvider)
        return complication
    }
    
    func makeUtilitarianSmallFlat(session: Session) -> CLKComplicationTemplateUtilitarianSmallFlat {
        let textProvider = CLKTextProvider(format: "\(session.timeRemaining())")
        let imageProvider = CLKImageProvider(onePieceImage: UIImage(named: "uchicago")!)
        return CLKComplicationTemplateUtilitarianSmallFlat(textProvider: textProvider, imageProvider: imageProvider)
    }

    func makeUtilitarianSmall(session: Session) -> CLKComplicationTemplateUtilitarianSmallRingText {
        let textProvider = CLKTextProvider(format: "\(session.timeRemaining())")
        return CLKComplicationTemplateUtilitarianSmallRingText(textProvider: textProvider, fillFraction: 0.3, ringStyle: .closed)
    }

    func makeCircularSmall(session: Session) -> CLKComplicationTemplateCircularSmallRingText {
        let textProvider = CLKTextProvider(format: "\(session.minutesRemaining())")
        let complication = CLKComplicationTemplateCircularSmallRingText(textProvider: textProvider, fillFraction: 0.3, ringStyle: .closed)
        return complication
    }
}
