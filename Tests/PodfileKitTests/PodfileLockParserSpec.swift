import Nimble
import Quick
import TSCUtility
import XCTest

@testable import PodfilerKit

class PodfileLockParserSpec: QuickSpec {
    override class func spec() {
        @TestState
        var sut: [PodLock]!

        beforeEach {
            let parser = try PodfileLockParser(file: podfileLockFixture)
            sut = try parser.generatePodLock()
        }

        it("parses") {
            expect(sut).to(haveCount(4))
            expect(sut[0]) == PodLock(
                name: "AFNetworking",
                checksum: "cf8e418e16f0c9c7e5c3150d019a3c679d015018",
                version: try XCTUnwrap(Version(string: "1.3.4")),
                source: .specRepo("trunk")
            )
            expect(sut[1]) == PodLock(
                name: "PodTest",
                checksum: "671615d047bc2a9e8c271feb99b749411b66aed2",
                version: try XCTUnwrap(Version(string: "1.0.0")),
                source: .gitCommit("da4e9da48d5a2bf65bad68f5dec35d6ddf8825a1", url: "PodTest-git-source")
            )
            expect(sut[2]) == PodLock(
                name: "Reachability",
                checksum: "b14c20321fa00f7f4600d8c9856fc57e71ef2ffe",
                version: try XCTUnwrap(Version(string: "3.1.0-FOO-SNAPSHOT")),
                source: .path("Reachability")
            )
            expect(sut[3]) == PodLock(
                name: "RxSwift",
                checksum: "4e28be97cbcfeee614af26d83415febbf2bf6f45",
                version: try XCTUnwrap(Version(string: "6.8.0")),
                source: .specRepo("trunk")
            )
        }
    }
}

private let podfileLockFixture = """
PODS:
  - AFNetworking (1.3.4)
  - PodTest (1.0.0):
    - PodTest/subspec_1 (= 1.0.0)
    - PodTest/subspec_2 (= 1.0.0)
  - PodTest/subspec_1 (1.0.0)
  - PodTest/subspec_2 (1.0.0)
  - Reachability (3.1.0-FOO-SNAPSHOT)
    - RxSwift (~> 6.0)
  - RxSwift (6.8.0)

DEPENDENCIES:
  - AFNetworking
  - PodTest (from `PodTest-git-source`)
  - Reachability (from `Reachability`)

SPEC REPOS:
  trunk:
    - AFNetworking
    - RxSwift

EXTERNAL SOURCES:
  PodTest:
    :git: PodTest-git-source
  Reachability:
    :path: Reachability

CHECKOUT OPTIONS:
  PodTest:
    :git: PodTest-git-source
    :commit: da4e9da48d5a2bf65bad68f5dec35d6ddf8825a1

SPEC CHECKSUMS:
  AFNetworking: cf8e418e16f0c9c7e5c3150d019a3c679d015018
  PodTest: 671615d047bc2a9e8c271feb99b749411b66aed2
  Reachability: b14c20321fa00f7f4600d8c9856fc57e71ef2ffe
  RxSwift: 4e28be97cbcfeee614af26d83415febbf2bf6f45

PODFILE CHECKSUM: f371e6714eb9c3c0225b554152a3238a1d5d5391

COCOAPODS: 1.15.2
"""
