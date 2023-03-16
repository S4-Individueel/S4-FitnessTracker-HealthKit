//
//  ContentView.swift
//  S4-FitnessTracker-HealthKit
//
//  Created by Reno Muijsenberg on 17/02/2023.
//

import SwiftUI
import HealthKit

struct ContentView: View {
    private var healtStore: HealthStore?
    @State private var stepsLastSevenDays: Double = 0;
    @State private var stepsThisMorning: Double = 0;
    @State private var stepsFromBoot: Double = 0;
    @State private var stepsThisDay: Double = 0;
    
    init() {
        healtStore = HealthStore()
    }
    
    private func getStepsFromLastSevenDays(_ statisticsColletion: HKStatisticsCollection) -> Void {
        let startDate = Calendar.current.date(byAdding: .day, value: -7, to: Date())!
        let endDate = Date()
        
        stepsLastSevenDays = 0
        
        statisticsColletion.enumerateStatistics(from: startDate, to: endDate) { statistics, stop in
            let count = statistics.sumQuantity()?.doubleValue(for: .count())
            
            guard let count = count else { return }

            stepsLastSevenDays += count
        }
    }
    
    private func getStepsFromThisMorning(_ statisticsColletion: HKStatisticsCollection) -> Void {
        // Get the start of today in the user's local time zone
        guard let startDate = Calendar.current.date(bySettingHour: 0, minute: 0, second: 0, of: Date()) else { return }
        // Get the date with time set to 12:00:00 in the user's local time zone
        guard let endDate = Calendar.current.date(bySettingHour: 12, minute: 0, second: 0, of: startDate) else { return }
        
        stepsThisMorning = 0;
        
        statisticsColletion.enumerateStatistics(from: startDate, to: endDate) { statistics, stop in
            let count = statistics.sumQuantity()?.doubleValue(for: .count())
            
            guard let count = count else { return }
            stepsThisMorning += count
        }
    }
    
    //Function to get steps from 00.00 till 12.00 this day
    private func getStepsFromThisDay(_ statisticsColletion: HKStatisticsCollection) {
        // Get the start of today in the user's local time zone
        guard let startDate = Calendar.current.date(bySettingHour: 0, minute: 0, second: 0, of: Date()) else { return }

        // Get the date with time set to 23:59:59 in the user's local time zone
        guard let endDate = Calendar.current.date(bySettingHour: 23, minute: 59, second: 59, of: startDate) else { return }
        
        stepsThisDay = 0;
        
        statisticsColletion.enumerateStatistics(from: startDate, to: endDate) { statistics, stop in
            let count = statistics.sumQuantity()?.doubleValue(for: .count())
            
            guard let count = count else { return }
            stepsThisDay += count
        }
    }
    
    private func getStepsFromDeviceBoot(_ statisticsColletion: HKStatisticsCollection) {
        //Get boot time of device and store in variable
        guard let bootTime = Calendar.current.date(byAdding: .second, value: Int(-ProcessInfo.processInfo.systemUptime), to: Date()) else { return }
    
        stepsFromBoot = 0;
        
        statisticsColletion.enumerateStatistics(from: bootTime, to: Date()) { statistics, stop in
            let count = statistics.sumQuantity()?.doubleValue(for: .count())
            
            guard let count = count else { return }
            stepsFromBoot += count
        }
    }
    
    private func initHealthKit() {
        if let healtStore = healtStore {
            healtStore.requestAuthorization { success in
                if success {
                    healtStore.calculateSteps { statisticsColletion in
                        if let statisticsColletion = statisticsColletion {
                            getStepsFromLastSevenDays(statisticsColletion)
                            getStepsFromThisMorning(statisticsColletion)
                            getStepsFromThisDay(statisticsColletion)
                            getStepsFromDeviceBoot(statisticsColletion)
                        }
                    }
                }
            }
        }
    }
    
    var body: some View {
        VStack {
            Text("Step Counter").font(.largeTitle)
            List {
                HStack {
                    Text("Steps of last 7 days:")
                    Spacer()
                    Text("\(stepsLastSevenDays, specifier: "%.0f")").padding()
                }
                HStack {
                    Text("Steps set this morning:")
                    Spacer()
                    Text("\(stepsThisMorning, specifier: "%.0f")").padding()
                }
                HStack {
                    Text("Steps set this day:")
                    Spacer()
                    Text("\(stepsThisDay, specifier: "%.0f")").padding()
                }
                HStack {
                    Text("Steps set from boot of device:")
                    Spacer()
                    Text("\(stepsFromBoot, specifier: "%.0f")").padding()
                }
            }
        }
        .onAppear {
            initHealthKit()
        }
        .refreshable {
            initHealthKit()
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
