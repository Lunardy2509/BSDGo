//
//  AppIntent.swift
//  FeatureWidget
//
//  Created by Ferdinand Lunardy on 15/05/25.
//

import WidgetKit
import AppIntents

struct ConfigurationAppIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource { "Configuration" }
    static var description: IntentDescription { "This is an example widget." }

    // An example configurable parameter.
    @Parameter(title: "Number of Stops", default: 3)
    var numberOfStops: Int
}
