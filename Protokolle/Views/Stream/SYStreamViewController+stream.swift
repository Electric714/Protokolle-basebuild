//
//  SYStreamViewController+stream.swift
//  syslog
//
//  Created by samara on 20.05.2025.
//

import Foundation
import UIKit.UIApplication
import IDeviceSwift

// MARK: - Class extension: Stream stuff
extension SYStreamViewController {
	@objc func stopOrStartStream() {
		Task { [weak self] in
			guard let self else { return }
			
			if logManager.isStreaming {
				self.logManager.stop()
			} else {
				do {
					try await self.logManager.os_trace_relay()
				} catch {
					await MainActor.run {
						self.playButton.updateImage(
							systemImageName: "play.circle.fill",
							highlighted: false
						)
						
						UIAlertController.showAlertWithOk(
							title: .localized("Stream"),
							message: error.localizedDescription,
							action: {
								HeartbeatManager.shared.start(true)
							}
						)
					}
				}
			}
		}
	}
	
	func dataSourceApply(snapshot: StepDataSourceSnapshot) {
		// https://stackoverflow.com/questions/73242482/uicollectionview-snapshot-takes-too-long-to-re-apply
		// whyyyyy is this so slowwww
		// this may crash lol
		dataSource.applySnapshotUsingReloadData(snapshot) {
			let label: String = .localized("%lld Messages", arguments: snapshot.numberOfItems)
			self.subtitleLabel.text = label
			UIApplication.sceneDelegate?.currentScene?.title = label
		}
	}
	
	func makeTimer(interval: TimeInterval = Preferences.refreshSpeed) -> Timer {
		return Timer(timeInterval: interval, repeats: true) { [self] _  in
			// if we're paused,
			// or collecting logs in background
			// let's stop here, keep the batch for when we do want
			// to display it
			guard
				logManager.isStreaming,
				UIApplication.shared.applicationState != .background
			else {
				return
			}
						
			addBatch()
			
			if #available(iOS 17.0, *) {
				setNeedsUpdateContentUnavailableConfiguration()
			}
			
			if automaticallyScrollToBottom == true {
				scrollAllTheWayDown()
			}
		}
	}
	
        func addBatch() {
                guard !batch.isEmpty else { return }

                var snapshot = dataSource.snapshot()
                let overflowCount = max(0, allEntries.count - buffer)

                if overflowCount > 0 {
                        if !userInformedAboutThreshold {
                                UIAlertController.showAlertWithOk(
                                        title: .localized("You've reached the threshold"),
                                        message: .localized("To save on performance, we've automatically started clearing logs from the start of the session.")
                                )

                                logManager.isStreaming = false
                                userInformedAboutThreshold = true
                        }

                        let itemsToRemove = allEntries.prefix(overflowCount)
                        allEntries.removeFirst(overflowCount)

                        let deletions = itemsToRemove.filter { snapshot.indexOfItem($0) != nil }
                        if !deletions.isEmpty {
                                snapshot.deleteItems(deletions)
                        }
                }

                let visibleBatch = batch.filter { passesTargetFilter($0.log) }
                snapshot.appendItems(visibleBatch)
                batch = []
                dataSourceApply(snapshot: snapshot)
        }


        func applyTargetFilterToStoredEntries() {
                let combinedEntries = allEntries + batch

                let filteredEntries = combinedEntries.filter { entry in
                        passesTargetFilter(entry.log) && (filter?.entryPassesFilter(entry.log) ?? true)
                }

                allEntries = combinedEntries
                batch = []

                var snapshot: StepDataSourceSnapshot = .init()
                snapshot.appendSections([0])
                snapshot.appendItems(filteredEntries)
                dataSourceApply(snapshot: snapshot)

                if #available(iOS 17.0, *) {
                        setNeedsUpdateContentUnavailableConfiguration()
                }
        }


        @objc func clearAll() {
                var snapshot: StepDataSourceSnapshot = .init()
                allEntries = []
                batch = []
                snapshot.appendSections([0])
                dataSourceApply(snapshot: snapshot)
		
		if #available(iOS 17.0, *) {
			setNeedsUpdateContentUnavailableConfiguration()
		}
	}
}
