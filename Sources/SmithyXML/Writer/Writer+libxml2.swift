//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import libxml2
import struct Foundation.Data

/// Extends Writer to copy its tree into libxml2, then write the tree to XML data.
extension Writer {

    /// Translates this Writer and its children into XML ready to be sent.
    /// - Returns: A `Data` value containing this writer's UTF-8 XML representation.
    func xmlString() -> Data {
        // Create a libxml document
        let doc = xmlNewDoc(nil)

        // Create the tree and set the root node on the document
        let rootNode = nodify(to: nil, doc: doc)
        xmlDocSetRootElement(doc, rootNode)

        // Create a buffer to hold the XML data
        let buffer = xmlBufferCreate()

        // Write the XML to the buffer
        xmlNodeDump(buffer, doc, rootNode, 0, 0)

        // Transfer the buffer to a Swift Data value
        var data = Data()
        if let buffer {
            data = Data(bytes: buffer.pointee.content, count: Int(buffer.pointee.use))
        }

        // Free up memory and return data
        xmlFreeDoc(doc)
        xmlFree(buffer)
        return data
    }

    /// Translates the data in this `Writer` to a libxml2 node.
    ///
    /// Used to transform the `Writer` tree into a corresponding tree of libxml nodes for rendering to XML.
    /// - Parameters:
    ///   - parentNode: The libxml2 parent node to attach this node to as a child, if any.
    ///   - doc: The libxml2 document these nodes are a part of.
    /// - Returns: The libxml2 node that represents this `Writer`, with libxml2 children nodes for all the `Writer`'s children.
    private func nodify(to parentNode: xmlNodePtr?, doc: xmlDocPtr?) -> xmlNodePtr? {

        // Expose the node name and content as C strings
        nodeInfo.name.utf8CString.withUnsafeBytes { unsafeName in
            content.utf8CString.withUnsafeBytes { unsafeContent in

                // libxml uses C strings with its own xmlChar data type
                // Recast the C strings to libxml-typed strings
                let name = UnsafePointer<xmlChar>(unsafeName.bindMemory(to: xmlChar.self).baseAddress)
                let content = UnsafePointer<xmlChar>(unsafeContent.bindMemory(to: xmlChar.self).baseAddress)

                // Create a node and set its name and type
                let node = xmlNewNode(nil, name)
                node?.pointee.type = nodeInfo.location.xmlElementType

                // Encode the content string, set it on the node, then free it
                let encoded = xmlEncodeEntitiesReentrant(doc, content)
                xmlNodeSetContent(node, encoded)
                xmlFree(encoded)

                // Add the child node to its parent
                xmlAddChild(parentNode, node)

                // Unwrap the namespace if any, then access its prefix & uri as C strings
                if let namespace = nodeInfo.namespace {
                    namespace.prefix.utf8CString.withUnsafeBytes { unsafePrefix in
                        namespace.uri.utf8CString.withUnsafeBytes { unsafeURI in

                            // libxml uses C strings with its own xmlChar data type
                            // Recast the C strings to libxml-typed strings
                            let prefix = UnsafePointer<xmlChar>(unsafePrefix.bindMemory(to: xmlChar.self).baseAddress)
                            let uri = UnsafePointer<xmlChar>(unsafeURI.bindMemory(to: xmlChar.self).baseAddress)

                            // Add the namespace to the node
                            // If the prefix is an empty string, replace it with nil and libxml will
                            // fill in default prefix ("xmlns") for you
                            xmlNewNs(node, uri, prefix?.pointee == 0 ? nil : prefix)
                        }
                    }
                }

                // Nodify all of this writer's children and add them to the node as children
                for child in self.children {
                    _ = child.nodify(to: node, doc: doc)
                }

                // Return the node.  Only the root node return value is used
                return node
            }
        }
    }
}

private extension NodeInfo.Location {

    /// Translates NodeInfo's `Location` property into the corresponding libxml element type.
    var xmlElementType: xmlElementType {
        switch self {
        case .element: return XML_ELEMENT_NODE
        case .attribute: return XML_ATTRIBUTE_NODE
        }
    }
}
