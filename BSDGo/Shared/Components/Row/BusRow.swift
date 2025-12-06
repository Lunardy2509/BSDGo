import MapKit
import SwiftUI

struct BusRow: View {
    let bus: Bus
    let etaMinutes: Int
    let onTap: (_ busNumber: Int, _ busName: String) -> Void
    @Environment(\.colorScheme) var scheme
    
    var body: some View {
        Button(action: {
            onTap(bus.number, bus.name)
        }, label: {
            HStack(alignment: .center, spacing: 8) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(bus.name)
                        .font(.headline)
                        .foregroundColor(.black)
                        .padding(8)
                        .background(bus.color.resolvedColor(for: scheme))
                        .cornerRadius(20)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Text(bus.licensePlate)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
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
        })
        .buttonStyle(DefaultButtonStyle())
        .tint(.primary)
    }
}
