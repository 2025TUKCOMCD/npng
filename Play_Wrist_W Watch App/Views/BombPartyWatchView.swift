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
    @State private var showGameEndAlert: Bool = false
    @State private var navigateToMission: Bool = false
    @State private var selectedMission: MissionType? = nil
    @State private var isPassingBomb: Bool = false

    var body: some View {
        NavigationView {
        ZStack {
            // 게임 종료 화면 (최상단 레이어)
            if sessionManager.gameEnded {
                VStack(spacing: 20) {
                    Text("💥 게임 종료")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.red)
                    
                    Text("\(sessionManager.loserName)님이")
                        .font(.headline)
                        .foregroundColor(.black)
                    
                    Text("폭탄을 폭발시켰습니다!")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    
                    Image(systemName: "burst.fill")
                        .font(.system(size: 50))
                        .foregroundColor(.orange)
                }
                .padding()
                .background(Color.white.opacity(0.95))
                .cornerRadius(15)
                .transition(.scale)
                .zIndex(100)  // 최상단에 표시
            }
            
            // 기존 게임 화면
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

                Text((sessionManager.hasBomb && !isPassingBomb) ? "O" : "X")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor((sessionManager.hasBomb && !isPassingBomb) ? .red : .green)
            }

            // 🚀 미션 수행 or 넘기기
            if sessionManager.hasBomb && !isPassingBomb && !missionCompleted {
                // 🎯 미션 선택 버튼
                VStack(spacing: 8) {
                    if let mission = currentMission {
                        Text(mission.label)
                            .font(.footnote)
                            .foregroundColor(.secondary)
                    } else {
                        Text("미션 준비 중...")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                    }
                    
                    Button(action: {
                        if currentMission == nil {
                            currentMission = MissionType.allCases.randomElement()
                        }
                        selectedMission = currentMission
                        navigateToMission = true
                    }) {
                        Label("미션 시작", systemImage: "play.fill")
                            .foregroundColor(.white)
                    }
                    .buttonStyle(.borderedProminent)
                }
            }

            if sessionManager.hasBomb && !isPassingBomb && missionCompleted {
                Button(action: {
                    sendPassBomb()
                }) {
                    Label("폭탄 넘기기", systemImage: "arrow.right.circle.fill")
                        .foregroundColor(.white)
                }
                .buttonStyle(.borderedProminent)
                .tint(.orange)
                .padding(.top, 8)
            }

            if !sessionManager.hasBomb {
                Text("폭탄 없음")
                    .foregroundColor(.gray)
                    .font(.subheadline)
                    .padding(.top, 12)
            }
        }  // VStack 끝
        }  // ZStack 끝
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.white)
        .multilineTextAlignment(.center)
        // 🎯 폭탄 상태 변화 감지 - 자동으로 랜덤 미션 시작
        .onChange(of: sessionManager.hasBomb) { newHasBomb in
            if newHasBomb {
                // 폭탄을 받으면 passing 상태 해제
                isPassingBomb = false
                if !missionCompleted {
                    // 랜덤 미션 자동 선택
                    currentMission = MissionType.allCases.randomElement()
                }
            }
        }
        // ✅ NavigationLink로 미션 화면 이동
        .background(
            NavigationLink(
                destination: missionDestinationView(),
                isActive: $navigateToMission
            ) {
                EmptyView()
            }
        )
        }  // NavigationView 끝
    }
    
    // 🎮 미션 뷰 선택
    @ViewBuilder
    private func missionDestinationView() -> some View {
        if let mission = selectedMission {
            switch mission {
            case .fastTap:
                FastTapMissionView(onSuccess: {
                    completeMission()
                    navigateToMission = false
                })
            case .timingTap:
                TimingTapMissionView(onSuccess: {
                    completeMission()
                    navigateToMission = false
                })
            case .shake:
                ShakeMissionView(onSuccess: {
                    completeMission()
                    navigateToMission = false
                })
            case .hapticReaction:
                HapticReactionGameView(onSuccess: {
                    completeMission()
                    navigateToMission = false
                })
            case .accuracyTap:
                TouchAccuracyGameView(onSuccess: {
                    completeMission()
                    navigateToMission = false
                })
            case .patternMemory:
                PatternMemoryGameView(onSuccess: {
                    completeMission()
                    navigateToMission = false
                })
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
        // 즉시 UI 업데이트를 위해 passing 상태 설정
        isPassingBomb = true
        
        let message: [String: Any] = [
            "event": "passBomb",
            "playerNumber": sessionManager.playerNumber
        ]
        if WCSession.default.isReachable {
            WCSession.default.sendMessage(message, replyHandler: nil, errorHandler: { error in
                // 에러 발생 시 passing 상태 롤백
                DispatchQueue.main.async {
                    self.isPassingBomb = false
                }
            })
        }

        // 상태 초기화
        missionCompleted = false
        currentMission = nil
    }
}
