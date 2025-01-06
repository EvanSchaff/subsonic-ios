//
//  PlayerView.swift
//  MusicPlayer
//
//  Created by Evan Schaff on 12/22/24.
//

import SwiftUI
import AVFoundation
import Combine

struct PlayerView: View {
    @ObservedObject private var player = PlayerViewModel.shared
    @Environment(\.dismiss) private var dismiss
    @GestureState private var dragState = CGSize.zero
    @State private var offset = CGSize.zero
    @State private var sliderPosition: Double = 0
    @State private var isDraggingSlider = false
    @State private var timer: Timer? = nil
    @State private var timerSubscription: AnyCancellable?
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                backgroundGradient
                
                VStack(spacing: 30) {
                    dismissHandle
                    albumArtView(geometry)
                    songInfo
                    progressBar
                    timeLabels
                    playbackControls
                    secondaryControls
                    Spacer()
                }
                .padding()
            }
            .background(Color.black)
            .offset(y: max(0, offset.height + dragState.height))
            .animation(.spring(response: 0.3, dampingFraction: 0.8), value: dragState)
            .gesture(dragGesture(geometry))
        }
        .onAppear {
            startTimer()
        }
        .onDisappear {
            timerSubscription?.cancel()
        }
    }
    
    private func startTimer() {
        // Cancel any existing subscription
        timerSubscription?.cancel()
        
        // Create and connect the timer
        timerSubscription = Timer.publish(every: 0.1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak player] _ in
                guard let player = player else { return }

                // Update slider position if not dragging
                if !isDraggingSlider {
                    withAnimation {
                        sliderPosition = player.currentTime
                    }
                }
            }
    }

    
    // MARK: - Components
    private var backgroundGradient: some View {
        LinearGradient(
            gradient: Gradient(colors: [Color.black.opacity(0.8), Color.black]),
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }
    
    private var progressBar: some View {
        Slider(
            value: $sliderPosition,
            in: 0...(Double(player.currentSong?.duration ?? 1)),
            onEditingChanged: { editing in
                isDraggingSlider = editing
                
                if !editing {
                    player.seek(to: sliderPosition)
                }
            }
        )
        .tint(.white)
        .padding(.horizontal)
    }
    
    private var dismissHandle: some View {
        RoundedRectangle(cornerRadius: 3)
            .fill(Color.gray.opacity(0.5))
            .frame(width: 40, height: 5)
            .padding(.top, 10)
    }
    
    private func albumArtView(_ geometry: GeometryProxy) -> some View {
        Group {
            if let albumArt = player.albumArt {
                albumArt
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: min(geometry.size.width * 0.8, 350))
                    .cornerRadius(12)
                    .shadow(radius: 10)
                    .padding(.vertical)
            } else {
                Image("test_album")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: min(geometry.size.width * 0.8, 350))
                    .cornerRadius(12)
                    .shadow(radius: 10)
                    .padding(.vertical)
            }
        }
    }
    
    private var songInfo: some View {
        VStack(spacing: 8) {
            GeometryReader { geometry in
                HStack {
                    Spacer()
                    
                    Text(player.currentSong?.name ?? "No Song Playing")
                        .font(.title)
                        .bold()
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .lineLimit(1)
                        .frame(width: geometry.size.width - 32, alignment: .center)
                    
                    Spacer()
                }
            }
            .frame(height: 40)

            Text(player.currentSong?.artist ?? "Unknown Artist")
                .font(.title2)
                .foregroundColor(.gray)
        }
        .padding(.horizontal)
    }
    

    private var timeLabels: some View {
        HStack {
            Text(formatTime(sliderPosition))
            Spacer()
            Text(formatTime(Double(player.currentSong?.duration ?? 0)))
        }
        .font(.caption)
        .foregroundColor(.gray)
        .padding(.horizontal)
    }
    
    private var playbackControls: some View {
        HStack(spacing: 40) {
            playbackButton(systemName: "backward.fill") {
                player.prevTrack()
            }
            
            playbackButton(systemName: player.isPlaying ? "pause.circle.fill" : "play.circle.fill", size: 65) {
                player.togglePause()
            }
            .disabled(player.isLoading) // Disable button while loading
            
            playbackButton(systemName: "forward.fill") {
                player.nextTrack()
            }
        }
        .foregroundColor(.white)
    }
    
    private var secondaryControls: some View {
        HStack(spacing: 40) {
            playbackButton(systemName: "shuffle") {
                player.toggleShuffle()
            }
            .foregroundColor(player.shuffleEnabled ? .green : .white)
            
            playbackButton(systemName: repeatImage) {
                player.toggleRepeatMode()
            }
            .foregroundColor(player.repeatMode != .none ? .green : .white)
        }
    }
    
    private var repeatImage: String {
        switch player.repeatMode {
        case .none:
            return "repeat"
        case .single:
            return "repeat.1"
        case .all:
            return "repeat"
        }
    }
    
    private func playbackButton(systemName: String, size: CGFloat = 28, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: size))
        }
    }
    
    // MARK: - Gestures
    
    private func dragGesture(_ geometry: GeometryProxy) -> some Gesture {
        DragGesture()
            .updating($dragState) { value, state, _ in
                if value.translation.height > 0 {
                    state = value.translation
                }
            }
            .onEnded { value in
                handleDragEnd(value: value, screenHeight: geometry.size.height)
            }
    }
    
    private func handleDragEnd(value: DragGesture.Value, screenHeight: CGFloat) {
        let halfScreen = screenHeight / 2
        
        if value.translation.height > halfScreen {
            withAnimation { dismiss() }
        } else {
            withAnimation { offset = .zero }
        }
    }
    
    // MARK: - Helpers
    
    private func formatTime(_ timeInSeconds: Double) -> String {
        let minutes = Int(timeInSeconds) / 60
        let seconds = Int(timeInSeconds) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}
