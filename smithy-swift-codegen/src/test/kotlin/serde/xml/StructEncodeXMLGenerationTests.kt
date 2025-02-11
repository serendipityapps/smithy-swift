/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

package serde.xml

import MockHttpRestXMLProtocolGenerator
import TestContext
import defaultSettings
import getFileContents
import io.kotest.matchers.string.shouldContainOnlyOnce
import org.junit.jupiter.api.Test

class StructEncodeXMLGenerationTests {
    @Test
    fun `simpleScalar serialization`() {
        val context = setupTests("Isolated/Restxml/xml-scalar.smithy", "aws.protocoltests.restxml#RestXml")
        val contents = getFileContents(context.manifest, "/RestXml/models/SimpleScalarPropertiesInput+Encodable.swift")
        val expectedContents =
            """
            extension SimpleScalarPropertiesInput: Swift.Encodable {
                enum CodingKeys: Swift.String, Swift.CodingKey {
                    case byteValue
                    case doubleValue = "DoubleDribble"
                    case falseBooleanValue
                    case floatValue
                    case integerValue
                    case longValue
                    case `protocol` = "protocol"
                    case shortValue
                    case stringValue
                    case trueBooleanValue
                }
            
                static func writingClosure(_ value: SimpleScalarPropertiesInput?, to writer: SmithyXML.Writer) throws {
                    guard let value else { writer.detach(); return }
                    try writer[.init("byteValue")].write(value.byteValue)
                    try writer[.init("DoubleDribble")].write(value.doubleValue)
                    try writer[.init("falseBooleanValue")].write(value.falseBooleanValue)
                    try writer[.init("floatValue")].write(value.floatValue)
                    try writer[.init("integerValue")].write(value.integerValue)
                    try writer[.init("longValue")].write(value.longValue)
                    try writer[.init("protocol")].write(value.`protocol`)
                    try writer[.init("shortValue")].write(value.shortValue)
                    try writer[.init("stringValue")].write(value.stringValue)
                    try writer[.init("trueBooleanValue")].write(value.trueBooleanValue)
                }
            }
            """.trimIndent()
        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `008 structure xmlName`() {
        val context = setupTests("Isolated/Restxml/xml-lists-structure.smithy", "aws.protocoltests.restxml#RestXml")
        val contents = getFileContents(context.manifest, "/RestXml/models/StructureListMember+Codable.swift")
        val expectedContents =
            """
            extension RestXmlProtocolClientTypes.StructureListMember: Swift.Codable {
                enum CodingKeys: Swift.String, Swift.CodingKey {
                    case a = "value"
                    case b = "other"
                }
            
                static func writingClosure(_ value: RestXmlProtocolClientTypes.StructureListMember?, to writer: SmithyXML.Writer) throws {
                    guard let value else { writer.detach(); return }
                    try writer[.init("value")].write(value.a)
                    try writer[.init("other")].write(value.b)
                }
            
                public init(from decoder: Swift.Decoder) throws {
                    let containerValues = try decoder.container(keyedBy: CodingKeys.self)
                    let aDecoded = try containerValues.decodeIfPresent(Swift.String.self, forKey: .a)
                    a = aDecoded
                    let bDecoded = try containerValues.decodeIfPresent(Swift.String.self, forKey: .b)
                    b = bDecoded
                }
            }
            """.trimIndent()

        contents.shouldContainOnlyOnce(expectedContents)
    }

    private fun setupTests(smithyFile: String, serviceShapeId: String): TestContext {
        val context = TestContext.initContextFrom(smithyFile, serviceShapeId, MockHttpRestXMLProtocolGenerator()) { model ->
            model.defaultSettings(serviceShapeId, "RestXml", "2019-12-16", "Rest Xml Protocol")
        }
        context.generator.generateCodableConformanceForNestedTypes(context.generationCtx)
        context.generator.generateSerializers(context.generationCtx)
        context.generationCtx.delegator.flushWriters()
        return context
    }
}
