import SwiftUI
import WatchConnectivity

enum MissionType: CaseIterable {
    case fastTap, timingTap, shake
}

struct BombPartyWatchView: View {
    @StateObject private var sessionManager = WCSessionManager.shared
    @State private var missionCompleted: Bool = false
    @State private var currentMission: MissionType? = nil

    var body: some View {
        VStack(spacing: 12) {
            // 타이틀
            Text("💣 Bomb Party")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.purple)

            // 플레이어 번호
            VStack(spacing: 4) {
                Text("내 번호")
                    .font(.footnote)
                    .foregroundColor(.gray)

                Text(sessionManager.playerNumber)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.black)
            }

            // 폭탄 상태
            VStack(spacing: 4) {
                Text("폭탄 상태")
                    .font(.footnote)
                    .foregroundColor(.gray)

                Text(sessionManager.hasBomb ? "O" : "X")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(sessionManager.hasBomb ? .red : .green)
            }

            // 🚀 폭탄 있음 + 미션 안함 상태
            if sessionManager.hasBomb && !missionCompleted {
                if let mission = currentMission {
                    switch mission {
                    case .fastTap:
                        FastTapMissionView(onSuccess: completeMission)
                    case .timingTap:
                        TimingTapMissionView(onSuccess: completeMission)
                    case .shake:
                        ShakeMissionView(onSuccess: completeMission)
                    }
                } else {
                    Button("미션 수행") {
                        currentMission = MissionType.allCases.randomElement()
                    }
                    .frame(maxWidth: 120)
                    .padding(.vertical, 8)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    .padding(.top, 12)
                }
            }

            // ✅ 미션 완료 후 → 폭탄 넘기기
            if sessionManager.hasBomb && missionCompleted {
                Button("폭탄 넘기기") {
                    sendPassBomb()
                }
                .frame(maxWidth: 120)
                .padding(.vertical, 8)
                .background(Color.orange)
                .foregroundColor(.white)
                .cornerRadius(10)
                .padding(.top, 12)
            }

            // 🔕 폭탄 없음
            if !sessionManager.hasBomb {
                Text("폭탄 없음")
                    .foregroundColor(.gray)
                    .font(.subheadline)
                    .padding(.top, 12)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.white)
        .multilineTextAlignment(.center)
    }

    // 🎯 미션 성공 처리
    private func completeMission() {
        missionCompleted = true
    }

    // 💣 폭탄 넘기기 메시지 전송
    private func sendPassBomb() {
        let message: [String: Any] = [
            "event": "passBomb",
            "playerNumber": sessionManager.playerNumber
        ]
        if WCSession.default.isReachable {
            WCSession.default.sendMessage(message, replyHandler: nil, errorHandler: nil)
        }

        // 상태 초기화
        sessionManager.hasBomb = false
        missionCompleted = false
        currentMission = nil
    }
}
