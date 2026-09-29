import SwiftUI

struct Insight: Identifiable {
    let id: UUID
    let title: String
    let subtitle: String
    let type: InsightType
    let accentColor: Color
    enum InsightType { case trend, anomaly, summary, tip }
}
