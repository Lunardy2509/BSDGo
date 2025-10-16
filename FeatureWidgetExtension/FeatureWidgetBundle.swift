//
//  FeatureWidgetBundle.swift
//  FeatureWidget
//
//  Created by Ferdinand Lunardy on 15/05/25.
//

import WidgetKit
import SwiftUI

#if canImport(ActivityKit)
import ActivityKit
#endif

struct FeatureWidgetBundle: WidgetBundle {
    var body: some Widget {
        #if canImport(ActivityKit)
        if #available(iOS 16.0, *) {
            BusTrackingLiveActivity()
        }
        #endif
    }
}
