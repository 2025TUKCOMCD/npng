import SwiftUI

struct SpyFallLocationGuessView: View {
    let possibleLocations = ["병원","공항","학교","해적선","카지노","중세 군대","회사 송년회","호텔","남극기지","우주 정거장","온천","여객 열차","군부대","경찰서","원양 여객선"]

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                Text("📍 장소 후보")
                    .font(.headline)
                    .padding(.top)

                ForEach(possibleLocations, id: \.self) { location in
                    Text(location)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue.opacity(0.2))
                        .cornerRadius(10)
                        .foregroundColor(.black)
                }

                Spacer()
            }
            .padding()
        }
    }
}
