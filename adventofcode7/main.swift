//
//  main.swift
//  adventofcode7
//
//  Created by Cruse, Si on 12/7/18.
//  Copyright © 2018 Cruse, Si. All rights reserved.
//

import Foundation

//    --- Day 7: The Sum of Its Parts ---
//    You find yourself standing on a snow-covered coastline; apparently, you landed a little off course. The region is too hilly to see the North Pole from here, but you do spot some Elves that seem to be trying to unpack something that washed ashore. It's quite cold out, so you decide to risk creating a paradox by asking them for directions.
//
//    "Oh, are you the search party?" Somehow, you can understand whatever Elves from the year 1018 speak; you assume it's Ancient Nordic Elvish. Could the device on your wrist also be a translator? "Those clothes don't look very warm; take this." They hand you a heavy coat.
//
//    "We do need to find our way back to the North Pole, but we have higher priorities at the moment. You see, believe it or not, this box contains something that will solve all of Santa's transportation problems - at least, that's what it looks like from the pictures in the instructions." It doesn't seem like they can read whatever language it's in, but you can: "Sleigh kit. Some assembly required."
//
//    "'Sleigh'? What a wonderful name! You must help us assemble this 'sleigh' at once!" They start excitedly pulling more parts out of the box.
//
//    The instructions specify a series of steps and requirements about which steps must be finished before others can begin (your puzzle input). Each step is designated by a single letter. For example, suppose you have the following instructions:
//
//    Step C must be finished before step A can begin.
//    Step C must be finished before step F can begin.
//    Step A must be finished before step B can begin.
//    Step A must be finished before step D can begin.
//    Step B must be finished before step E can begin.
//    Step D must be finished before step E can begin.
//    Step F must be finished before step E can begin.
//    Visually, these requirements look like this:
//
//
//    -->A--->B--
//    /    \      \
//    C      -->D----->E
//    \           /
//    ---->F-----
//    Your first goal is to determine the order in which the steps should be completed. If more than one step is ready, choose the step which is first alphabetically. In this example, the steps would be completed as follows:
//
//    Only C is available, and so it is done first.
//    Next, both A and F are available. A is first alphabetically, so it is done next.
//    Then, even though F was available earlier, steps B and D are now also available, and B is the first alphabetically of the three.
//    After that, only D and F are available. E is not available because only some of its prerequisites are complete. Therefore, D is completed next.
//    F is the only choice, so it is done next.
//    Finally, E is completed.
//    So, in this example, the correct order is CABDFE.
//
//    In what order should the steps in your instructions be completed?

extension Character {
    public static let alphabet = Array("ABCDEFGHIJKLMNOPQRSTUVWXYZ")
    
    var uppercaseValue: Int {
        assert(Character.alphabet.contains(self))
        return Character.alphabet.index(of: self)! + 1
    }
    
    var uppercase: Character {
        return Character(String(self).uppercased())
    }
    
    var isUppercase: Bool {
        return "A"..."Z" ~= self
    }
}

class Step : Hashable, CustomDebugStringConvertible {
    let name: Character
    var predecessors: Set<Character> = []
    var worker: Int? = nil
    var worktimeremaining: Int
    
    init(_ name: Character, worktime: Int) {
        self.name = name
        self.worktimeremaining = worktime + name.uppercaseValue
    }
    
    func addpredecessor(step: Character) {
        predecessors.insert(step)
    }

    func removepredecessor(step: Character) {
        predecessors.remove(step)
    }

    var inprogress: Bool {
        return worker != nil
    }
    
    var blocked: Bool {
        return predecessors.count > 0
    }
    
    func blockedby(step: Character) -> Bool {
        return predecessors.contains(step)
    }
    
    func dowork() {
        assert(inprogress && !blocked)
        worktimeremaining -= 1
    }
    
    // Hashable
    static func == (lhs: Step, rhs: Step) -> Bool {
        return lhs.name == rhs.name
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(name)
    }
    
    var debugDescription: String {
        let result = "\(name) -> "
        var line = ""
        for step in predecessors.sorted(by: { $0 < $1 }) {
            line += "\(step),"
        }
        return result + (line.isEmpty ? "" : line.prefix(line.count - 1))
    }
}

class Steps: CustomDebugStringConvertible {
    private var _steps: Set<Step> = []
    let maxworkers: Int
    let worktime: Int
    var idleworkers: [Int] = []

    init(steps: [String], maxworkers: Int, worktime: Int) {
        self.maxworkers = maxworkers
        self.worktime = worktime
        idleworkers = Array(1...self.maxworkers)
        hydrate(input: steps)
    }
    
    convenience init(contentsOf: URL, maxworkers: Int = 2, worktime: Int = 0) {
        do {
            let data = try String(contentsOf: contentsOf)
            let strings = data.components(separatedBy: .newlines)
            self.init(steps: strings.filter({ $0.count > 0 }), maxworkers: maxworkers, worktime: worktime)
        } catch {
            print(error)
            self.init(steps: [], maxworkers: maxworkers, worktime: worktime)
        }
    }

    private func stepfactory(stepname: Character, predecessorname: Character) {
        let step = _steps.filter { $0.name == stepname }.first
        let predecessor = _steps.filter { $0.name == predecessorname }.first

        if let s = step {
            if let _ = predecessor {
                s.addpredecessor(step: predecessorname)
            } else {
                let p = Step(predecessorname, worktime: worktime)
                s.addpredecessor(step: predecessorname)
                _steps.insert(p)
            }
        } else {
            let s = Step(stepname, worktime: worktime)
            if let _ = predecessor {
                s.addpredecessor(step: predecessorname)
            } else {
                let p = Step(predecessorname, worktime: worktime)
                s.addpredecessor(step: predecessorname)
                _steps.insert(p)
            }
            _steps.insert(s)
        }
    }
   
    // Load data
    private func hydrate(input: [String]) {
        for line in input {
            let elements = line.split(separator: " ")
            let predecessorname = elements[1].first!
            let stepname = elements[7].first!
            stepfactory(stepname: stepname, predecessorname: predecessorname)
        }
    }
    
    // Processing
    func nextstep() -> Step? {
        return _steps.sorted(by: {$0.name < $1.name}).filter{ !$0.blocked && !$0.inprogress }.first
    }

    func activesteps() -> [Step] {
        return _steps.sorted(by: {$0.name < $1.name}).filter{ $0.inprogress }
    }

    func finishedsteps() -> [Step] {
        return _steps.sorted(by: {$0.name < $1.name}).filter{ $0.inprogress && $0.worktimeremaining == 0 }
    }
    
    func execute(step: Step) -> Character? {
        if !step.blocked {
            let impeded_steps = _steps.filter{ $0.blockedby(step: step.name) }
            for s in impeded_steps { s.removepredecessor( step: step.name ) }
            _steps.remove(step)
            return step.name
        } else {
            return nil
        }
    }
    
    func assignwork() {
        var assignedworkers: Set<Int> = []
        for worker in self.idleworkers.sorted() {
            if let step = nextstep() { step.worker = worker; assignedworkers.insert(worker) }
        }
        self.idleworkers = self.idleworkers.filter { !assignedworkers.contains($0) }
    }
    
    func dowork() {
        let steps = activesteps()
        for s in steps { s.dowork() }
    }
    
    func finishwork() -> String {
        let steps = finishedsteps()
        if steps.isEmpty {
            return ""
        } else {
            var result = ""
            for step in steps {
                let impeded_steps = _steps.filter{ $0.blockedby(step: step.name) }
                for s in impeded_steps { s.removepredecessor( step: step.name ) }
                _steps.remove(step)
                self.idleworkers.append(step.worker!)
                result += String(step.name)
            }
            return result
        }
    }
    
    func reportassignments(_ second: Int) -> String {
        let assignedsteps = Array(1...maxworkers).map{ (w) in _steps.filter{ (s) in s.worker == w }.first  }
        return "\(second)\t\(assignedsteps.map{ "\($0?.name ?? ".")\t" }.joined())"
    }
    
    func execute() -> (String, Int, String) {
        let workers: String = Array(1...maxworkers).map{ "Worker \($0)\t" }.joined()
        var log = "Second\t" + workers + "Done\n"
        var result = ""
        var second = 0
        while _steps.count > 0 {
            // Assign work
            assignwork()
            // Report assignments
            log += reportassignments(second)
            // Do 1 seconds worth of work
            dowork()
            // Finish work
            result += finishwork()
            log += result + "\n"
            second += 1
        }
        log += reportassignments(second) + result + "\n"
        return (result, second, log)
    }
    
    // Debugging
    var debugDescription: String {
        var result = ""
        for step in _steps.sorted(by: {$0.name < $1.name}) {
            result += "\(step)\n"
        }
        return result
    }
}

// Test Scenarios
let challenge_test_1 = ([
    "Step C must be finished before step A can begin.",
    "Step C must be finished before step F can begin.",
    "Step A must be finished before step B can begin.",
    "Step A must be finished before step D can begin.",
    "Step B must be finished before step E can begin.",
    "Step D must be finished before step E can begin.",
    "Step F must be finished before step E can begin."
], "CABDFE")

// Utility function for running tests

func testit1(scenario: (input: [String], expected: String), process: ([String]) -> String) -> String {
    let result = process(scenario.input)
    return "\(result == scenario.expected ? "\u{1F49A}" : "\u{1F6D1}")\tresult \(result)\tinput: \(scenario.input)\n"
}

func test1(input: [String]) -> String {
    let steps = Steps(steps: input, maxworkers: 1, worktime: 0)
    print("The test map is\n\(steps)\n")
    return steps.execute().0
}

print(testit1(scenario: challenge_test_1, process: test1))

// Path to the problem input data
let path = URL(fileURLWithPath: FileManager.default.currentDirectoryPath).appendingPathComponent("input.txt")

let steps1 = Steps(contentsOf: path, maxworkers: 1, worktime: 0)
print("The FIRST CHALLENGE map is\n\(steps1)\n")
print("The FIRST CHALLENGE answer is \(steps1.execute().0)\n")

//        --- Part Two ---
//    As you're about to begin construction, four of the Elves offer to help. "The sun will set soon; it'll go faster if we work together." Now, you need to account for multiple people working on steps simultaneously. If multiple steps are available, workers should still begin them in alphabetical order.
//
//    Each step takes 60 seconds plus an amount corresponding to its letter: A=1, B=2, C=3, and so on. So, step A takes 60+1=61 seconds, while step Z takes 60+26=86 seconds. No time is required between steps.
//
//    To simplify things for the example, however, suppose you only have help from one Elf (a total of two workers) and that each step takes 60 fewer seconds (so that step A takes 1 second and step Z takes 26 seconds). Then, using the same instructions as above, this is how each second would be spent:
//
//        Second   Worker 1   Worker 2   Done
//        0        C          .
//        1        C          .
//        2        C          .
//        3        A          F       C
//        4        B          F       CA
//        5        B          F       CA
//        6        D          F       CAB
//        7        D          F       CAB
//        8        D          F       CAB
//        9        D          .       CABF
//        10        E          .       CABFD
//        11        E          .       CABFD
//        12        E          .       CABFD
//        13        E          .       CABFD
//        14        E          .       CABFD
//        15        .          .       CABFDE
//        Each row represents one second of time. The Second column identifies how many seconds have passed as of the beginning of that second. Each worker column shows the step that worker is currently doing (or . if they are idle). The Done column shows completed steps.
//
//        Note that the order of the steps has changed; this is because steps now take time to finish and multiple workers can begin multiple steps simultaneously.
//
//        In this example, it would take 15 seconds for two workers to complete these steps.
//
//    With 5 workers and the 60+ second step durations described above, how long will it take to complete all of the steps?
//

// Test Scenarios
let challenge_test_2 = ([
    "Step C must be finished before step A can begin.",
    "Step C must be finished before step F can begin.",
    "Step A must be finished before step B can begin.",
    "Step A must be finished before step D can begin.",
    "Step B must be finished before step E can begin.",
    "Step D must be finished before step E can begin.",
    "Step F must be finished before step E can begin."
    ], 15)

func testit2(scenario: (input: [String], expected: Int), process: ([String]) -> Int) -> String {
    let result = process(scenario.input)
    return "\(result == scenario.expected ? "\u{1F49A}" : "\u{1F6D1}")\tresult \(result)\tinput: \(scenario.input)\n"
}

func test2(input: [String]) -> Int {
    let steps = Steps(steps: input, maxworkers: 2, worktime: 0)
    print("The test map is\n\(steps)\n")
    return steps.execute().1
}

print(testit2(scenario: challenge_test_2, process: test2))

let steps2 = Steps(contentsOf: path, maxworkers: 5, worktime: 60)

print("The SECOND CHALLENGE map is\n\(steps2)\n")
print("The SECOND CHALLENGE answer is \(steps2.execute().1)\n")
