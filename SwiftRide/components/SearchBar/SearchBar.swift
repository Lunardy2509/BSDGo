import MapKit
import SwiftUI

struct SearchBar: View {
    @Binding var searchText: String
    @Binding var busStops: [BusStop]
    var onCancel: () -> Void

    @FocusState private var isTextFieldFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)

                    TextField("Search Bus Stop", text: $searchText)
                        .textFieldStyle(PlainTextFieldStyle())
                        .focused($isTextFieldFocused)

                    if !searchText.isEmpty {
                        Button {
                            searchText = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.gray)
                        }
                    }
                }
                .padding()
                .frame(height: 35)
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))

                if isTextFieldFocused || !searchText.isEmpty {
                    Button("Cancel") {
                        searchText = ""
                        isTextFieldFocused = false
                        onCancel()
                    }
                    .foregroundColor(.blue)
                    .padding(.leading, 4)
                    .transition(.move(edge: .trailing))
                    .animation(.default, value: searchText)
                }
            }
            .padding(.horizontal)
            .padding(.top, 25)
        }
    }
}
