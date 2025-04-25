import SwiftUI

struct PlayerStateView: View {
    @ObservedObject var session = WCSessionManager.shared

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: "person.circle.fill")
                .resizable()
                .frame(width: 30, height: 30)
                .foregroundColor(.purple)

            Text(session.playerName.isEmpty ? "대기 중..." : session.playerName)
                .font(.body)
                .foregroundColor(.black) // ✅ 진짜 검정

            Text("Ready")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.orange)
        }
        .frame(width: 80, height: 90)
        .padding()
        .background(Color(red: 0.95, green: 0.85, blue: 1.0)) // ✅ iPhone처럼 연보라색
        .cornerRadius(16)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.white) // ✅ 전체 화면 밝게
    }
}
