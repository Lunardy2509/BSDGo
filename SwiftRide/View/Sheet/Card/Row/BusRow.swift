import MapKit
import SwiftUI

struct BusRow: View {
    let bus: Bus
    let etaMinutes: Int
    let onTap: (_ busNumber: Int, _ busName: String) -> Void
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(UIColor.secondarySystemBackground))
            HStack {
                Image(systemName: "bus")
                    .foregroundStyle(bus.color)
                    .font(.system(size: 40))

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(bus.name)
                            .font(.headline)
                            .foregroundColor(.black)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 3)
                    .background(Color(bus.color))
                    .cornerRadius(20)
                    .fixedSize()

                    Text("Will be arriving \(etaMinutes == 0 ? "soon" : "in \(etaMinutes) \(etaMinutes == 1 ? "minute" : "minutes" )")")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
            .onTapGesture {
                onTap(bus.number, bus.name)
            }
        }
    }
}
