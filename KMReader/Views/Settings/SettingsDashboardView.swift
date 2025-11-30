//
//  SettingsDashboardView.swift
//  Komga
//
//  Created by Komga iOS Client
//

import SwiftUI

struct SettingsDashboardView: View {
  @State private var sections: [DashboardSection] = AppConfig.dashboardSections

  #if os(tvOS)
    @State private var isEditMode = false
    @State private var movingSection: DashboardSection?
    @FocusState private var focusedHandle: DashboardSection?
  #endif

  private func isSectionVisible(_ section: DashboardSection) -> Bool {
    return sections.contains(section)
  }

  private func hideSection(_ section: DashboardSection) {
    if let index = sections.firstIndex(of: section) {
      sections.remove(at: index)
      AppConfig.dashboardSections = sections
    }
  }

  private func showSection(_ section: DashboardSection) {
    if !sections.contains(section) {
      // Add at the end or find a good position based on allCases order
      if let referenceIndex = DashboardSection.allCases.firstIndex(of: section) {
        var insertIndex = sections.count
        for (idx, existingSection) in sections.enumerated() {
          if let existingIndex = DashboardSection.allCases.firstIndex(of: existingSection),
            existingIndex > referenceIndex
          {
            insertIndex = idx
            break
          }
        }
        sections.insert(section, at: insertIndex)
      } else {
        sections.append(section)
      }
      AppConfig.dashboardSections = sections
    }
  }

  private func moveSections(from source: IndexSet, to destination: Int) {
    sections.move(fromOffsets: source, toOffset: destination)
    AppConfig.dashboardSections = sections
  }

  #if os(tvOS)
    private func moveSectionUp(_ section: DashboardSection) {
      guard let index = sections.firstIndex(of: section),
        index > 0
      else { return }
      sections.swapAt(index, index - 1)
      AppConfig.dashboardSections = sections
    }

    private func moveSectionDown(_ section: DashboardSection) {
      guard let index = sections.firstIndex(of: section),
        index < sections.count - 1
      else { return }
      sections.swapAt(index, index + 1)
      AppConfig.dashboardSections = sections
    }
  #endif

  private var hiddenSections: [DashboardSection] {
    DashboardSection.allCases.filter { !isSectionVisible($0) }
  }

  var body: some View {
    List {
      #if os(tvOS)
        HStack {
          Spacer()
          Button {
            isEditMode.toggle()
            if !isEditMode {
              movingSection = nil
              focusedHandle = nil
            }
          } label: {
            Text(isEditMode ? "Done" : "Edit")
          }
          .buttonStyle(.plain)
        }
      #endif

      Section(header: Text("Dashboard Sections")) {
        ForEach(sections) { section in
          HStack {
            #if os(tvOS)
              Text(section.displayName)
                .font(.headline)
            #else
              Label(section.displayName, systemImage: section.icon)
            #endif
            Spacer()
            #if os(tvOS)
              HStack(spacing: 18) {
                Button {
                  if movingSection == section {
                    movingSection = nil
                    focusedHandle = nil
                  } else {
                    movingSection = section
                    focusedHandle = section
                  }
                } label: {
                  Image(systemName: "line.3.horizontal")
                }
                .buttonStyle(.plain)
                .focused($focusedHandle, equals: section)

                if isEditMode {
                  Button {
                    if movingSection == section {
                      movingSection = nil
                      focusedHandle = nil
                    }
                    hideSection(section)
                  } label: {
                    Image(systemName: "minus.circle.fill")
                  }
                  .buttonStyle(.plain)
                }
              }
              .padding(.horizontal, 18)
            #else
              Toggle(
                "",
                isOn: Binding(
                  get: { isSectionVisible(section) },
                  set: { _ in
                    if isSectionVisible(section) {
                      hideSection(section)
                    } else {
                      showSection(section)
                    }
                  }
                ))
            #endif
          }
          #if os(tvOS)
          .listRowBackground(
            Capsule()
              .fill(PlatformHelper.secondarySystemBackgroundColor)
              .opacity(movingSection == section ? 0.5 : 0))
          #endif
        }
        #if os(tvOS)
          .onMoveCommand { direction in
            guard let movingSection = movingSection else { return }
            // force focus on the moving section
            if let focus = focusedHandle, focus != movingSection {
              focusedHandle = movingSection
            }
            withAnimation {
              switch direction {
              case .up:
                moveSectionUp(movingSection)
              case .down:
                moveSectionDown(movingSection)
              default:
                break
              }
            }
          }
        #else
          .onMove(perform: moveSections)
        #endif
      }

      #if os(tvOS)
        if isEditMode && !hiddenSections.isEmpty {
          Section(header: Text("Hidden Sections")) {
            ForEach(hiddenSections) { section in
              HStack {
                Text(section.displayName)
                  .font(.headline)
                Spacer()
                Button {
                  showSection(section)
                } label: {
                  Image(systemName: "plus.circle")
                }
                .buttonStyle(.plain)
              }
              .padding(.vertical, 8)
            }
          }
        }
      #else
        if !hiddenSections.isEmpty {
          Section(header: Text("Hidden Sections")) {
            ForEach(hiddenSections) { section in
              HStack {
                Label {
                  Text(section.displayName)
                } icon: {
                  Image(systemName: section.icon)
                }
                Spacer()
                Toggle(
                  "",
                  isOn: Binding(
                    get: { isSectionVisible(section) },
                    set: { _ in showSection(section) }
                  ))
              }
            }
          }
        }
      #endif

      Section {
        Button {
          // Reset to default
          #if os(tvOS)
            movingSection = nil
            focusedHandle = nil
          #endif
          withAnimation {
            sections = DashboardSection.allCases
            AppConfig.dashboardSections = sections
          }
        } label: {
          HStack {
            Spacer()
            Text("Reset to Default")
            Spacer()
          }
        }
      }
    }
    .optimizedListStyle()
    .inlineNavigationBarTitle("Dashboard")
    .onAppear {
      sections = AppConfig.dashboardSections
      #if os(tvOS)
        movingSection = nil
        focusedHandle = nil
      #endif
    }
  }
}
