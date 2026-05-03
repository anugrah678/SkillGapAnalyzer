import SwiftUI

// MARK: - MODEL
struct Skill: Codable, Hashable {
    var name: String
    var level: String
}

// MARK: - NORMALIZATION
func normalize(_ str: String) -> String {
    return str.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
}

// MARK: - MAIN
struct ContentView: View {
    @State private var profiles: [String: [Skill]] = UserDefaults.standard.loadProfiles()
    
    var body: some View {
        NavigationStack {
            LandingView(profiles: $profiles)
        }
    }
}

// MARK: - LANDING
struct LandingView: View {
    @Binding var profiles: [String: [Skill]]
    
    var body: some View {
        ZStack {
            LinearGradient(colors: [.purple, .blue], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
            
            VStack(spacing: 30) {
                Spacer()
                
                Text("Skill Gap Analyzer")
                    .font(.largeTitle)
                    .foregroundColor(.white)
                    .bold()
                
                NavigationLink("Start") {
                    ProfileListView(profiles: $profiles)
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.white)
                .cornerRadius(12)
                .padding()
                
                Spacer()
            }
        }
    }
}

// MARK: - PROFILE LIST
struct ProfileListView: View {
    @Binding var profiles: [String: [Skill]]
    @State private var newName = ""
    
    var body: some View {
        VStack {
            Text("Profiles").font(.title2)
            
            HStack {
                TextField("New Profile", text: $newName)
                    .textFieldStyle(.roundedBorder)
                
                Button("Add") {
                    if !newName.isEmpty {
                        profiles[newName] = []
                        save()
                        newName = ""
                    }
                }
            }
            .padding()
            
            List {
                let keys = Array(profiles.keys).sorted()
                
                ForEach(keys, id: \.self) { name in
                    NavigationLink(name) {
                        DashboardView(profile: name, profiles: $profiles)
                    }
                }
                .onDelete { offsets in
                    for index in offsets {
                        let key = keys[index]
                        profiles.removeValue(forKey: key)
                    }
                    save()
                }
            }
        }
    }
    
    func save() {
        UserDefaults.standard.saveProfiles(profiles)
    }
}

// MARK: - DASHBOARD
struct DashboardView: View {
    var profile: String
    @Binding var profiles: [String: [Skill]]
    
    @State private var inputSkill = ""
    @State private var selectedSkill = "Swift"
    @State private var level = "Beginner"
    
    let skillOptions = [
        "Swift","HTML","CSS","JavaScript","React","NodeJS",
        "Python","Machine Learning","Deep Learning","TensorFlow",
        "AWS","Docker","Kubernetes","Linux",
        "C++","Java","DSA","System Design",
        "Unity","Game Design"
    ]
    
    let levels = ["Beginner","Intermediate","Advanced"]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                
                Text("👋 \(profile)")
                    .font(.title2)
                
                // Input + Dropdown
                VStack(spacing: 10) {
                    
                    TextField("Type skill (or use dropdown)", text: $inputSkill)
                        .textFieldStyle(.roundedBorder)
                    
                    Picker("Skill", selection: $selectedSkill) {
                        ForEach(skillOptions, id: \.self) { Text($0) }
                    }
                    
                    Picker("Level", selection: $level) {
                        ForEach(levels, id: \.self) { Text($0) }
                    }
                    .pickerStyle(.segmented)
                    
                    Button("Add Skill") {
                        let finalSkill = inputSkill.isEmpty ? selectedSkill : inputSkill
                        let normalized = normalize(finalSkill)
                        
                        let exists = profiles[profile]?.contains {
                            normalize($0.name) == normalized
                        } ?? false
                        
                        if !exists {
                            profiles[profile, default: []].append(
                                Skill(name: finalSkill.capitalized, level: level)
                            )
                            save()
                            inputSkill = ""
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                
                // Skills List
                ForEach(profiles[profile] ?? [], id: \.self) { skill in
                    HStack {
                        Text(skill.name)
                        Spacer()
                        Text(skill.level)
                            .foregroundColor(.white)
                            .padding(5)
                            .background(Color.green)
                            .cornerRadius(6)
                        
                        Button {
                            profiles[profile]?.removeAll {
                                normalize($0.name) == normalize(skill.name)
                            }
                            save()
                        } label: {
                            Image(systemName: "trash")
                                .foregroundColor(.red)
                        }
                    }
                    .padding()
                    .background(Color(.systemGray5))
                    .cornerRadius(10)
                }
                
                NavigationLink("Analyze Career + AI") {
                    JobView(userSkills: profiles[profile] ?? [])
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.purple)
                .foregroundColor(.white)
                .cornerRadius(12)
                
            }
            .padding()
        }
    }
    
    func save() {
        UserDefaults.standard.saveProfiles(profiles)
    }
}

// MARK: - JOB VIEW (FIXED)
struct JobView: View {
    
    let jobs: [String: [String]] = [
        "Software Engineer": ["DSA","System Design","Java","C++"],
        "Web Developer": ["HTML","CSS","JavaScript","React"],
        "AI Engineer": ["Python","Machine Learning","TensorFlow"],
        "Cloud Engineer": ["AWS","Docker","Kubernetes","Linux"],
        "Game Developer": ["C++","Unity","Game Design"]
    ]
    
    var userSkills: [Skill]
    
    var body: some View {
        let userNames = userSkills.map { normalize($0.name) }
        let analysis = calculateAnalysis(userNames: userNames)
        
        return ScrollView {
            VStack(spacing: 20) {
                
                Text("Career Analysis")
                    .font(.title2)
                
                // Each Job Card
                ForEach(analysis, id: \.job) { item in
                    VStack(alignment: .leading) {
                        
                        Text(item.job).font(.headline)
                        
                        Text("Match: \(item.percentage)%")
                        
                        ProgressView(value: Double(item.percentage), total: 100)
                        
                        if item.percentage < 100 {
                            ForEach(item.missing, id: \.self) {
                                Text("❌ \($0)")
                            }
                            
                            if let next = item.missing.first {
                                Text("🤖 Learn \(next) next")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                }
                
                // Best Job
                if let best = analysis.max(by: { $0.percentage < $1.percentage }) {
                    Text("🎯 Best Role: \(best.job) (\(best.percentage)%)")
                        .font(.headline)
                        .foregroundColor(.green)
                        .padding()
                }
            }
            .padding()
        }
    }
    
    // MARK: - LOGIC MOVED OUT
    func calculateAnalysis(userNames: [String]) -> [JobResult] {
        var results: [JobResult] = []
        
        for (job, required) in jobs {
            
            let matched = required.filter {
                userNames.contains(normalize($0))
            }
            
            let missing = required.filter {
                !userNames.contains(normalize($0))
            }
            
            let percentage = required.isEmpty ? 0 :
                Int((Double(matched.count) / Double(required.count)) * 100)
            
            results.append(
                JobResult(job: job, percentage: percentage, missing: missing)
            )
        }
        
        return results.sorted { $0.percentage > $1.percentage }
    }
}

// MARK: - RESULT MODEL
struct JobResult {
    var job: String
    var percentage: Int
    var missing: [String]
}

// MARK: - STORAGE
extension UserDefaults {
    
    func saveProfiles(_ profiles: [String: [Skill]]) {
        if let data = try? JSONEncoder().encode(profiles) {
            set(data, forKey: "profiles")
        }
    }
    
    func loadProfiles() -> [String: [Skill]] {
        if let data = data(forKey: "profiles"),
           let decoded = try? JSONDecoder().decode([String: [Skill]].self, from: data) {
            return decoded
        }
        return [:]
    }
}
