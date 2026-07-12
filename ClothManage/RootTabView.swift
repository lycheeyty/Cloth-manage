import SwiftUI
import UIKit
import PhotosUI
import AVFoundation

/// 一次拍摄/选择的图片批次，触发发布流程全屏页
struct CaptureBatch: Identifiable {
    let id = UUID()
    let images: [UIImage]
}

struct RootTabView: View {
    @State private var selectedTab = 0
    @State private var showAddMenu = false
    @State private var showCamera = false
    @State private var showPhotoPicker = false
    @State private var showPermissionAlert = false
    @State private var pickerItems: [PhotosPickerItem] = []
    @State private var captureBatch: CaptureBatch?

    private var cameraAvailable: Bool {
        UIImagePickerController.isSourceTypeAvailable(.camera)
    }

    /// 「添加」不是页面：点击只弹出菜单，选中态保持在原 Tab
    private var tabSelection: Binding<Int> {
        Binding(
            get: { selectedTab },
            set: { newValue in
                if newValue == 1 {
                    withAnimation(.easeOut(duration: 0.15)) { showAddMenu.toggle() }
                } else {
                    selectedTab = newValue
                    showAddMenu = false
                }
            }
        )
    }

    var body: some View {
        TabView(selection: tabSelection) {
            WardrobeView(onAddTapped: {
                withAnimation(.easeOut(duration: 0.15)) { showAddMenu = true }
            })
            .tabItem { Label("衣橱", systemImage: "square.grid.2x2") }
            .tag(0)

            Color.clear
                .tabItem { Label("添加", systemImage: "plus.circle.fill") }
                .tag(1)

            ProfileView()
                .tabItem { Label("我的", systemImage: "person") }
                .tag(2)
        }
        .tint(AppColor.accent)
        .overlay {
            if showAddMenu {
                addMenuOverlay
            }
        }
        .fullScreenCover(isPresented: $showCamera) {
            CameraPicker(
                onCapture: { image in
                    showCamera = false
                    captureBatch = CaptureBatch(images: [image])
                },
                onCancel: { showCamera = false }
            )
            .ignoresSafeArea()
        }
        .photosPicker(
            isPresented: $showPhotoPicker,
            selection: $pickerItems,
            maxSelectionCount: 9,
            matching: .images
        )
        .fullScreenCover(item: $captureBatch) { batch in
            CaptureFlowView(images: batch.images) { published in
                captureBatch = nil
                if published {
                    selectedTab = 0
                }
            }
        }
        .alert("需要相机权限", isPresented: $showPermissionAlert) {
            Button("去设置") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            Button("取消", role: .cancel) {}
        } message: {
            Text("请在系统设置中允许访问相机，用于拍摄衣物照片")
        }
        .onChange(of: pickerItems) { _, newItems in
            guard !newItems.isEmpty else { return }
            Task { await loadFromLibrary(newItems) }
        }
        .onAppear {
            // 截图巡游：直接进入发布页（正常使用不带该参数）
            if CommandLine.arguments.contains("--seed-drafts"), captureBatch == nil {
                let cardigan = DemoSeeder.drawGarment(
                    category: .top,
                    color: UIColor(red: 0.93, green: 0.91, blue: 0.87, alpha: 1)
                )
                let dress = DemoSeeder.drawGarment(
                    category: .dress,
                    color: UIColor(red: 0.85, green: 0.62, blue: 0.65, alpha: 1)
                )
                captureBatch = CaptureBatch(images: [cardigan, dress])
            }
        }
    }

    /// 添加菜单：悬浮在底部「添加」按钮上方的卡片，无箭头
    private var addMenuOverlay: some View {
        ZStack(alignment: .bottom) {
            Color.black.opacity(0.08)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation(.easeOut(duration: 0.15)) { showAddMenu = false }
                }

            VStack(spacing: 0) {
                if cameraAvailable {
                    menuRow(title: "拍照", icon: "camera") {
                        openCamera()
                    }
                    Divider()
                }
                menuRow(title: "从相册上传", icon: "photo.on.rectangle") {
                    showPhotoPicker = true
                }
            }
            .frame(width: 220)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
            .shadow(color: .black.opacity(0.15), radius: 16, y: 4)
            .padding(.bottom, 72)
            .transition(.scale(scale: 0.9, anchor: .bottom).combined(with: .opacity))
        }
    }

    private func menuRow(title: String, icon: String, action: @escaping () -> Void) -> some View {
        Button {
            withAnimation(.easeOut(duration: 0.15)) { showAddMenu = false }
            action()
        } label: {
            HStack {
                Text(title)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(AppColor.textPrimary)
                Spacer()
                Image(systemName: icon)
                    .foregroundStyle(AppColor.accent)
            }
            .padding(.horizontal, AppSpacing.l)
            .padding(.vertical, 14)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func openCamera() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized, .notDetermined:
            showCamera = true
        default:
            showPermissionAlert = true
        }
    }

    private func loadFromLibrary(_ items: [PhotosPickerItem]) async {
        var images: [UIImage] = []
        for item in items {
            if let data = try? await item.loadTransferable(type: Data.self),
               let image = UIImage(data: data) {
                images.append(image)
            }
        }
        pickerItems = []
        if !images.isEmpty {
            captureBatch = CaptureBatch(images: images)
        }
    }
}

#Preview {
    RootTabView()
        .modelContainer(for: [ClothingItem.self, Outfit.self], inMemory: true)
}
