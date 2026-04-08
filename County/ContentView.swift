//
//  ContentView.swift
//  County
//
//  Created by Quinten de Haard on 19/03/2026.
//

import SwiftUI
import SwiftData
import WidgetKit

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Countdown.date) private var countdowns: [Countdown]
    @State private var showingAddSheet = false
    @State private var selection = Set<Countdown.ID>()

    var body: some View {
        NavigationStack {
            Group {
                if countdowns.isEmpty {
                    ContentUnavailableView(
                        "No Countdowns",
                        systemImage: "calendar.badge.clock",
                        description: Text("Tap + to add your first countdown")
                    )
                } else {
                    List(selection: $selection) {
                        let upcoming = countdowns.filter { !$0.isPast }
                        let past = countdowns.filter { $0.isPast }

                        if !upcoming.isEmpty {
                            Section("Upcoming") {
                                ForEach(upcoming) { countdown in
                                    CountdownRow(countdown: countdown)
                                        .contextMenu {
                                            Button(role: .destructive) {
                                                withAnimation {
                                                    modelContext.delete(countdown)
                                                    syncToWidget()
                                                }
                                            } label: {
                                                Label("Delete", systemImage: "trash")
                                            }
                                        }
                                }
                                .onDelete { offsets in
                                    deleteCountdowns(from: upcoming, at: offsets)
                                }
                            }
                        }

                        if !past.isEmpty {
                            Section("Past") {
                                ForEach(past) { countdown in
                                    CountdownRow(countdown: countdown)
                                        .contextMenu {
                                            Button(role: .destructive) {
                                                withAnimation {
                                                    modelContext.delete(countdown)
                                                    syncToWidget()
                                                }
                                            } label: {
                                                Label("Delete", systemImage: "trash")
                                            }
                                        }
                                }
                                .onDelete { offsets in
                                    deleteCountdowns(from: past, at: offsets)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("County")
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    if !selection.isEmpty {
                        Button(role: .destructive, action: deleteSelected) {
                            Label("Delete \(selection.count)", systemImage: "trash")
                        }
                    }
                }
                ToolbarItem {
                    Button(action: { showingAddSheet = true }) {
                        Label("Add Countdown", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddSheet) {
                AddCountdownView()
            }
            .onChange(of: countdowns.map(\.date)) {
                syncToWidget()
            }
            .onAppear {
                syncToWidget()
            }
        }
    }

    private func deleteSelected() {
        withAnimation {
            for countdown in countdowns where selection.contains(countdown.id) {
                modelContext.delete(countdown)
            }
            selection.removeAll()
        }
        syncToWidget()
    }

    private func deleteCountdowns(from list: [Countdown], at offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(list[index])
            }
        }
        syncToWidget()
    }

    private func syncToWidget() {
        let entries = countdowns
            .filter { !$0.isPast }
            .prefix(10)
            .map { CountdownEntry(name: $0.name, date: $0.date) }
        SharedData.save(Array(entries))
        WidgetCenter.shared.reloadAllTimelines()
    }
}

struct CountdownRow: View {
    let countdown: Countdown

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(countdown.name)
                    .font(.headline)
                Text(countdown.date, format: .dateTime.day().month(.wide).year())
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            VStack(alignment: .trailing) {
                Text("\(abs(countdown.daysLeft))")
                    .font(.system(.title, design: .rounded, weight: .bold))
                    .foregroundStyle(countdown.isPast ? .secondary : .primary)
                Text(countdown.isPast ? "days ago" : (countdown.daysLeft == 1 ? "day left" : "days left"))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

struct AddCountdownView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var date = Date()

    var body: some View {
        NavigationStack {
            Form {
                TextField("Name", text: $name, prompt: Text("Enter name"))
                DatePicker("Date", selection: $date, displayedComponents: .date)
            }
            .formStyle(.grouped)
            .navigationTitle("New Countdown")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        let countdown = Countdown(name: name, date: date)
                        modelContext.insert(countdown)
                        dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
        .frame(minWidth: 300, minHeight: 200)
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Countdown.self, inMemory: true)
}
