//
//  RateWidgetChartView.swift
//  TonkeeperWidgetExtension
//
//  Created by Grigory on 25.9.23..
//

import SwiftUI
import TKUIKit

struct RateWidgetChartView: View {
    let chartData: RateWidgetEntry.ChartData

    var body: some View {
        TKLineChartCanvasView(chartData: chartData.data)
    }
}
