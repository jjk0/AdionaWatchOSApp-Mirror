//
//  ComplicationController.swift
//  Adiona WatchKit Extension
//
//  Created by Ken Franklin on 6/22/22.
//

import ClockKit


class ComplicationController: NSObject, CLKComplicationDataSource {
    
    // MARK: - Complication Configuration
    func getComplicationDescriptors(handler: @escaping ([CLKComplicationDescriptor]) -> Void) {
        let descriptors = [
            CLKComplicationDescriptor(identifier: "complication", displayName: "Adiona", supportedFamilies: CLKComplicationFamily.allCases)
            // Multiple complication support can be added here with more descriptors
        ]
        
        // Call the handler with the currently supported complication descriptors
        handler(descriptors)
    }
    
    func handleSharedComplicationDescriptors(_ complicationDescriptors: [CLKComplicationDescriptor]) {
        // Do any necessary work to support these newly shared complication descriptors
    }

    // MARK: - Timeline Configuration
    
    func getTimelineEndDate(for complication: CLKComplication, withHandler handler: @escaping (Date?) -> Void) {
        // Call the handler with the last entry date you can currently provide or nil if you can't support future timelines
        handler(nil)
    }
    
    func getPrivacyBehavior(for complication: CLKComplication, withHandler handler: @escaping (CLKComplicationPrivacyBehavior) -> Void) {
        // Call the handler with your desired behavior when the device is locked
        handler(.showOnLockScreen)
    }

    // MARK: - Timeline Population
    
    func getCurrentTimelineEntry(for complication: CLKComplication, withHandler handler: @escaping (CLKComplicationTimelineEntry?) -> Void) {
        // Call the handler with the current timeline entry
        handler(nil)
    }
    
    func getTimelineEntries(for complication: CLKComplication, after date: Date, limit: Int, withHandler handler: @escaping ([CLKComplicationTimelineEntry]?) -> Void) {
        // Call the handler with the timeline entries after the given date
        handler(nil)
    }

    // MARK: - Sample Templates
    
    func getLocalizableSampleTemplate(for complication: CLKComplication, withHandler handler: @escaping (CLKComplicationTemplate?) -> Void) {
        let ctemplate = makeTemplate(for: HealthDataManager.shared, complication: complication)
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
        case .utilitarianSmall:
            return makeUtilitarianSmall(session: session)
        case .utilitarianSmallFlat:
            return makeUtilitarianSmallFlat(session: session)
        case .utilitarianLarge:
            return makeUtilitarianLargeFlat(session: session, fromDate: date)
        default:
            print(complication.family.rawValue)
            return nil
        }
    }
}

extension ComplicationController {
    func makeUtilitarianLargeFlat(session: HealthDataManager, fromDate: Date? = nil) -> CLKComplicationTemplateUtilitarianLargeFlat {
        let textProvider = CLKTextProvider(format: "Adiona")
        let complication = CLKComplicationTemplateUtilitarianLargeFlat(
            textProvider: textProvider)
        return complication
    }
    
    func makeUtilitarianSmallFlat(session: HealthDataManager) -> CLKComplicationTemplateUtilitarianSmallFlat {
        let textProvider = CLKTextProvider(format: "Adiona")
        let imageProvider = CLKImageProvider(onePieceImage: UIImage(named: "uchicago")!)
        return CLKComplicationTemplateUtilitarianSmallFlat(textProvider: textProvider, imageProvider: imageProvider)
    }

    func makeUtilitarianSmall(session: HealthDataManager) -> CLKComplicationTemplateUtilitarianSmallRingText {
        let textProvider = CLKTextProvider(format: "A")
        return CLKComplicationTemplateUtilitarianSmallRingText(textProvider: textProvider, fillFraction: 0.3, ringStyle: .closed)
    }

    func makeCircularSmall(session: HealthDataManager) -> CLKComplicationTemplateCircularSmallRingText {
        let textProvider = CLKTextProvider(format: "A")
        let complication = CLKComplicationTemplateCircularSmallRingText(textProvider: textProvider, fillFraction: 0.3, ringStyle: .closed)
        return complication
    }
}
