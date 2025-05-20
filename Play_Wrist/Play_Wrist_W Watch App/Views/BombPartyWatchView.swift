import SwiftUI
import WatchConnectivity

enum MissionType: CaseIterable, Identifiable {
    case fastTap, timingTap, shake, hapticReaction, accuracyTap, patternMemory

    var id: Self { self }

    var label: String {
        switch self {
        case .fastTap: return "빠르게 터치"
        case .timingTap: return "정확한 타이밍"
        case .shake: return "흔들기"
        case .hapticReaction: return "진동 반응"
        case .accuracyTap: return "정밀 터치"
        case .patternMemory: return "패턴 기억하기"
        }
    }
}

struct BombPartyWatchView: View {
    @StateObject private var sessionManager = WCSessionManager.shared
    @State private var missionCompleted: Bool = false
    @State private var currentMission: MissionType? = nil

    var body: some View {
        VStack(spacing: 12) {
            // 💣 타이틀
            Text("💣 Bomb Party")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.purple)

            // 👤 플레이어 번호
            VStack(spacing: 4) {
                Text("내 번호")
                    .font(.footnote)
                    .foregroundColor(.gray)

                Text(sessionManager.playerNumber)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.black)
            }

            // 🧨 폭탄 상태
            VStack(spacing: 4) {
                Text("폭탄 상태")
                    .font(.footnote)
                    .foregroundColor(.gray)

                Text(sessionManager.hasBomb ? "O" : "X")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(sessionManager.hasBomb ? .red : .green)
            }

            // 🚀 미션 수행 or 넘기기
            if sessionManager.hasBomb && !missionCompleted {
                // 🔽 미션 선택 버튼 목록
                ScrollView {
                    VStack(spacing: 6) {
                        Text("미션을 선택하세요")
                            .font(.subheadline)
                            .foregroundColor(.gray)

                        ForEach(MissionType.allCases) { mission in
                            Button(mission.label) {
                                currentMission = mission
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 6)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                        }
                    }
                    .padding(.top, 8)
                }
                .frame(maxHeight: 120)
            }

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

        // ✅ 미션 전체 화면으로 분리
        .fullScreenCover(item: $currentMission) { mission in
            switch mission {
            case .fastTap:
                FastTapMissionView(onSuccess: completeMission)
            case .timingTap:
                TimingTapMissionView(onSuccess: completeMission)
            case .shake:
                ShakeMissionView(onSuccess: completeMission)
            case .hapticReaction:
                HapticReactionGameView(onSuccess: completeMission)
            case .accuracyTap:
                TouchAccuracyGameView(onSuccess: completeMission)
            case .patternMemory:
                PatternMemoryGameView(onSuccess: completeMission)
            }
        }
    }

    // 🎯 미션 성공 처리
    private func completeMission() {
        missionCompleted = true
        currentMission = nil
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
