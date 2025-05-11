import MapKit
import SwiftUI

struct BusRow: View {
    let bus: Bus
    let etaMinutes: Int
    let onTap: (_ busNumber: Int, _ busName: String) -> Void

    var body: some View {
        Button(action: {
            onTap(bus.number, bus.name)
        }) {
            HStack(alignment: .center, spacing: 12) {
                Image(systemName: "bus")
                    .foregroundStyle(bus.color)
                    .font(.system(size: 40))

                VStack(alignment: .leading, spacing: 4) {
                    Text(bus.name)
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(Color(bus.color))
                        .cornerRadius(20)

                    Text("Will be arriving \(etaMinutes == 0 ? "soon" : "in \(etaMinutes) \(etaMinutes == 1 ? "minute" : "minutes")")")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

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
