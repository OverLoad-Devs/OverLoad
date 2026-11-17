import SwiftUI
import SwiftData

struct StatCard: View {
    let title: String
    let value: String
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(.caption).foregroundStyle(.secondary)
            Text(value).font(.title2.bold())
        }.frame(maxWidth: .infinity, alignment: .leading).padding()
            .background(.quaternary, in: RoundedRectangle(cornerRadius: 12))
    }
}

#Preview { StatCard(title: "Total volume", value: "2,850 lb·reps").padding().modelContainer(SampleData.preview()) }
