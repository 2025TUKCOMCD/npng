import SwiftUI

struct LocationGuessingView: View {
    // 후보 장소 목록
    let locationCandidates = [
        "병원", "공항", "학교", "해적선", "카지노", "중세 군대",
        "회사 송년회", "호텔", "남극기지", "우주 정거장", "온천",
        "여객 열차", "군부대", "경찰서", "원양 여객선"
    ]

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                Text("🏝️ 장소 후보 리스트")
                    .font(.headline)
                    .foregroundColor(.purple)
                    .padding(.top)

                ForEach(locationCandidates, id: \.self) { location in
                    Text(location)
                        .font(.body)
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding()
                        .background(Color.purple.opacity(0.2))
                        .cornerRadius(10)
                }

                Button("닫기") {
                    dismiss()
                }
                .padding(.top, 20)
                .padding(.bottom, 10)
                .foregroundColor(.white)
                .background(Color.gray)
                .cornerRadius(8)
            }
            .padding(.horizontal, 8)
        }
        .background(Color.white)
    }
}
