//
//  ComplexSpec.swift
//  SwiftCheck
//
//  Created by Robert Widmann on 9/2/15.
//  Copyright © 2015 Robert Widmann. All rights reserved.
//

import XCTest
import SwiftCheck

class ComplexSpec : XCTestCase {
	func testProperties() {
		let upper = Gen<Character>.fromElementsOf("A"..."Z" as ClosedInterval<Character>)
		let lower = Gen<Character>.fromElementsOf("a"..."z" as ClosedInterval<Character>)
		let numeric = Gen<Character>.fromElementsOf("0"..."9" as ClosedInterval<Character>)
		let special = Gen<Character>.fromElementsOf(["!", "#", "$", "%", "&", "'", "*", "+", "-", "/", "=", "?", "^", "_", "`", "{", "|", "}", "~", "."])
		let hexDigits = Gen<Character>.oneOf([
			Gen<Character>.fromElementsOf("A"..."F"),
			numeric,
		])

		let localEmail = Gen<Character>.oneOf([
			upper,
			lower,
			numeric,
			special,
		]).proliferateNonEmpty().suchThat({ $0[$0.endIndex.predecessor()] != "." }).fmap(String.init)
		let hostname = Gen<Character>.oneOf([
			lower,
			numeric,
			Gen.pure("-"),
		]).proliferateNonEmpty().fmap(String.init)
		let tld = lower.proliferateNonEmpty().suchThat({ $0.count > 1 }).fmap(String.init)

		let emailGen = wrap3 <^> localEmail <*> Gen.pure("@") <*> hostname <*> Gen.pure(".") <*> tld

		property("Generated email addresses contain 1 @") <- forAll(emailGen) { (e : String) in
			return e.characters.filter({ $0 == "@" }).count == 1
		}

		let ipHexDigits = Gen<String>.oneOf([
			hexDigits.proliferateSized(1).fmap{ String.init($0) + ":" },
			hexDigits.proliferateSized(2).fmap{ String.init($0) + ":" },
			hexDigits.proliferateSized(3).fmap{ String.init($0) + ":" },
			hexDigits.proliferateSized(4).fmap{ String.init($0) + ":" },
		])

		let ipGen = { $0.initial() } <^> (wrap2 <^> ipHexDigits <*> ipHexDigits <*> ipHexDigits <*> ipHexDigits)

		property("Generated IPs contain 3 sections") <- forAll(ipGen) { (e : String) in
			return e.characters.filter({ $0 == ":" }).count == 3
		}

	}
}

/// MARK: String Conveniences

private func wrap(l : String) -> String -> String -> String {
	return { m in { r in l + m + r } }
}

private func wrap2(l : String) -> String -> String -> String -> String {
	return { m in { m2 in { r in l + m + m2 + r } } }
}

private func wrap3(l : String) -> String -> String -> String -> String -> String {
	return { m in { m2 in { m3 in { r in l + m + m2 + m3 + r } } } }
}

extension String {
	func initial() -> String {
		return self[self.startIndex..<self.endIndex.predecessor()]
	}
}
