//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@_spi(SmithyXML) import SmithyXML

class XMLEncoderTests: XCTestCase {

    private struct HasNestedElements: Encodable {

        static func write(_ value: HasNestedElements, to writer: Writer) throws {
            try writer[.init("a")].write(value.a)
            try writer[.init("b")].write(value.b)
        }

        let a: String
        let b: String
    }

    func test_encodesXMLWithNestedElements() throws {
        let data = try SmithyXML.XMLReadWrite.documentWritingClosure(
            rootNodeInfo: .init("test")
        )(
            HasNestedElements(a: "a", b: "b"),
            HasNestedElements.write(_:to:)
        )
        let xml = "<test><a>a</a><b>b</b></test>"
        XCTAssertEqual(String(data: data, encoding: .utf8), xml)
    }

    private struct HasNestedElementAndAttribute: Encodable {

        static func write(_ value: HasNestedElementAndAttribute, to writer: Writer) throws {
            try writer[.init("a")].write(value.a)
            try writer[.init("b", location: .attribute)].write(value.b)
        }

        let a: String
        let b: String
    }

    func test_encodesXMLWithElementAndAttribute() throws {
        let data = try SmithyXML.XMLReadWrite.documentWritingClosure(
            rootNodeInfo: .init("test")
        )(
            HasNestedElementAndAttribute(a: "a", b: "b"),
            HasNestedElementAndAttribute.write(_:to:)
        )
        let xml = "<test b=\"b\"><a>a</a></test>"
        XCTAssertEqual(String(data: data, encoding: .utf8), xml)
    }

    func test_encodesXMLWithElementAndAttributeAndNamespace() throws {
        let data = try SmithyXML.XMLReadWrite.documentWritingClosure(
            rootNodeInfo: .init("test", namespace: .init(prefix: "", uri: "https://www.def.com/1.0"))
        )(
            HasNestedElementAndAttribute(a: "a", b: "b"),
            HasNestedElementAndAttribute.write(_:to:)
        )
        let xml = "<test xmlns=\"https://www.def.com/1.0\" b=\"b\"><a>a</a></test>"
        XCTAssertEqual(String(data: data, encoding: .utf8), xml)
    }

    func test_encodesXMLWithElementAndAttributeAndSpecialChars() throws {
        let data = try SmithyXML.XMLReadWrite.documentWritingClosure(
            rootNodeInfo: .init("test")
        )(
            HasNestedElementAndAttribute(a: "'<a&z>'", b: "\"b&s\""),
            HasNestedElementAndAttribute.write(_:to:)
        )
        let xml = "<test b=\"&quot;b&amp;s&quot;\"><a>\'&lt;a&amp;z&gt;\'</a></test>"
        XCTAssertEqual(String(data: data, encoding: .utf8), xml)
    }
}
