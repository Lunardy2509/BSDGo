import MapKit
import SwiftUI

struct BusRow: View {
    let bus: Bus
    let etaMinutes: Int
    let onTap: (_ busNumber: Int, _ busName: String) -> Void
    
    private var backgroundColor: Color {
        if etaMinutes <= 5 {
            return .green.opacity(0.5)
        }
        else if etaMinutes <= 15 {
            return .yellow.opacity(0.5)
        }
        else {
            return .primary.opacity(0.2)
        }
    }
    
    var body: some View {
        Button(action: {
            onTap(bus.number, bus.name)
        }) {
            HStack(alignment: .center, spacing: 8) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(bus.name)
                        .font(.headline)
                        .foregroundColor(.primary)
                        .padding(8)
                        .background(backgroundColor)
                        .cornerRadius(20)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Text("Will be arriving \(etaMinutes == 0 ? "soon" : "in \(etaMinutes) \(etaMinutes == 1 ? "minute" : "minutes")")")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.leading, 6)

                Spacer()

                Image(systemName: "chevron.right")
                    .foregroundColor(.gray)
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(UIColor.secondarySystemBackground))
            .cornerRadius(12)
            .contentShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }
}
