//
//  SettingsServersView.swift
//  Komga
//
//  Created by Komga iOS Client
//

import SwiftData
import SwiftUI

struct SettingsServersView: View {
  enum Mode {
    case management
    case onboarding
  }

  private let mode: Mode

  init(mode: Mode = .management) {
    self.mode = mode
  }

  @Environment(AuthViewModel.self) private var authViewModel
  @Environment(\.dismiss) private var dismiss
  @Environment(\.modelContext) private var modelContext
  @Query(sort: [
    SortDescriptor(\KomgaInstance.lastUsedAt, order: .reverse),
    SortDescriptor(\KomgaInstance.name, order: .forward),
  ]) private var instances: [KomgaInstance]
  @AppStorage("themeColorHex") private var themeColor: ThemeColor = .orange

  @State private var instancePendingDeletion: KomgaInstance?
  @State private var editingInstance: KomgaInstance?
  @State private var showLogin = false
  @State private var showLogoutAlert = false

  private var activeInstanceId: String? {
    AppConfig.currentInstanceId
  }

  var body: some View {
    List {
      if let introText {
        Section {
          Text(introText)
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.leading)
            .padding(.vertical, 4)
        }
      }

      Section(footer: footerText) {
        if instances.isEmpty {
          Text("Login to a Komga server to see it listed here.")
            .foregroundStyle(.secondary)
            .padding(.vertical, 16)
        } else {
          ForEach(instances) { instance in
            serverRow(for: instance)
          }
        }
      }

      addServerSection

      if mode == .management, authViewModel.isLoggedIn {
        Section {
          Button(role: .destructive) {
            showLogoutAlert = true
          } label: {
            HStack {
              Spacer()
              Label("Logout", systemImage: "rectangle.portrait.and.arrow.right")
              Spacer()
            }
          }
        }
      }
    }
    .navigationTitle(navigationTitle)
    #if canImport(UIKit)
      .navigationBarTitleDisplayMode(.inline)
    #endif
    .sheet(item: $editingInstance) { instance in
      SettingsServerEditView(instance: instance)
    }
    .alert(
      "Delete Server",
      isPresented: Binding(
        get: { instancePendingDeletion != nil },
        set: { isPresented in
          if !isPresented {
            instancePendingDeletion = nil
          }
        }
      ),
      presenting: instancePendingDeletion
    ) { instance in
      Button("Delete", role: .destructive) {
        delete(instance)
      }
      Button("Cancel", role: .cancel) {}
    } message: { instance in
      if isActive(instance) {
        Text("Deleting \(instance.name) will logout the current session and remove cached data for this server.")
      } else {
        Text("This will remove \(instance.name), its credentials, and all cached data for this server.")
      }
    }
    .alert("Logout", isPresented: $showLogoutAlert) {
      Button("Cancel", role: .cancel) {}
      Button("Logout", role: .destructive) {
        authViewModel.logout()
      }
    } message: {
      Text("Are you sure you want to logout?")
    }
    .navigationDestination(isPresented: $showLogin) {
      LoginView()
    }
    .onChange(of: authViewModel.isLoggedIn) { _, loggedIn in
      if loggedIn && mode == .onboarding {
        dismiss()
      }
    }
  }

  private var navigationTitle: String {
    switch mode {
    case .management:
      return "Servers"
    case .onboarding:
      return "Get Started"
    }
  }

  private var introText: String? {
    switch mode {
    case .management:
      return nil
    case .onboarding:
      return "Choose an existing Komga server or add a new one to begin."
    }
  }

  private var footerText: some View {
    Text("Credentials are stored locally so you can switch servers without re-entering them.")
  }

  private var addServerSection: some View {
    Section {
      Button {
        showLogin = true
      } label: {
        Label(addButtonTitle, systemImage: "plus.circle")
      }
    }
  }

  private var addButtonTitle: String {
    switch mode {
    case .management:
      return "Add Another Server"
    case .onboarding:
      return "Connect to a Server"
    }
  }

  private func serverRow(for instance: KomgaInstance) -> some View {
    Button {
      switchTo(instance)
    } label: {
      HStack {
        VStack(alignment: .leading, spacing: 6) {
          HStack(spacing: 6) {
            Text(instance.name.isEmpty ? instance.serverURL : instance.name)
              .font(.headline)
            if isActive(instance) {
              Label("Active", systemImage: "checkmark.circle.fill")
                .font(.caption)
                .foregroundStyle(.green)
            }
          }
          Text(instance.serverURL)
            .font(.footnote)
            .foregroundStyle(.secondary)
          Text("User: \(instance.username)")
            .font(.footnote)
            .foregroundStyle(.secondary)
          Text(instance.isAdmin ? "Role: Admin" : "Role: User")
            .font(.caption)
            .foregroundStyle(instance.isAdmin ? .green : .secondary)
        }
        Spacer()
      }
      .padding(.vertical, 6)
    }
    .buttonStyle(.plain)
    .swipeActions(edge: .trailing) {
      if !isActive(instance) {
        Button {
          editingInstance = instance
        } label: {
          Label("Edit", systemImage: "pencil")
        }
        .tint(.blue)

        Button(role: .destructive) {
          instancePendingDeletion = instance
        } label: {
          Label("Delete", systemImage: "trash")
        }
      }
    }
    .contextMenu {
      if !isActive(instance) {
        Button {
          editingInstance = instance
        } label: {
          Label("Edit", systemImage: "pencil")
        }

        Button(role: .destructive) {
          instancePendingDeletion = instance
        } label: {
          Label("Delete", systemImage: "trash")
        }
      }
    }
  }

  private func isActive(_ instance: KomgaInstance) -> Bool {
    activeInstanceId == instance.id.uuidString
  }

  private func switchTo(_ instance: KomgaInstance) {
    authViewModel.switchTo(instance: instance)
    instance.lastUsedAt = Date()
    saveChanges()
  }

  private func delete(_ instance: KomgaInstance) {
    if isActive(instance) {
      authViewModel.logout()
    }
    modelContext.delete(instance)
    saveChanges()
    instancePendingDeletion = nil
    Task {
      await CacheManager.clearCaches(instanceId: instance.id.uuidString)
    }
    LibraryManager.shared.removeLibraries(for: instance.id.uuidString)
  }

  private func saveChanges() {
    do {
      try modelContext.save()
    } catch {
      ErrorManager.shared.alert(error: error)
    }
  }
}
