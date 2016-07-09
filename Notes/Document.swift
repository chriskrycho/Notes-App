//
//  Document.swift
//  Notes
//
//  Created by Christopher Krycho on 7/2/16.
//  Copyright © 2016 Metacognitive Software. All rights reserved.
//

import Cocoa


// NOTE: the `: String` *associates the `String` type with this enum. This is... funky, as far as
// I'm concerned.
enum MetaNoteDocumentFilenames: String {
    case TextFile = "Text.rtf"
    case AttachmentsDirectory = "Attachments"
}


enum ErrorCode: Int {
    /// We couldn't find any document as specified.
    case CannotAccessDocument
    /// We couldn't get the file wrappers from the document.
    case CannotLoadFileWrappers
    /// We couldn't load the text from its file wrapper.
    case CannotLoadText
    /// We couldn't load the attachments from their file wrappers.
    case CannotAccessAttachments
    /// We couldn't save the text through its file wrapper.
    case CannotSaveText
    /// We couldn't save the attachment through its file wrapper.
    case CannotSaveAttachment
}


let errorDomain = "NotesErrorDomain"

func err(code: ErrorCode, _ userInfo: [NSObject:AnyObject]? = nil) -> NSError {
    return NSError(domain: errorDomain, code: code.rawValue, userInfo: userInfo)
}


class Document: NSDocument {

    var text: AttributedString = AttributedString()
    var documentFileWrapper: FileWrapper = FileWrapper(directoryWithFileWrappers: [:])

    override init() {
        super.init()
        // Add your subclass-specific initialization here.
    }

    override class func autosavesInPlace() -> Bool {
        return true
    }

    override var windowNibName: String? {
        // Returns the nib file name of the document
        // If you need to use a subclass of NSWindowController or if your document supports multiple
        // NSWindowControllers, you should remove this property and override -makeWindowControllers
        // instead.
        return "Document"
    }

    override func data(ofType typeName: String) throws -> Data {
        // Insert code here to write your document to data of the specified type. If outError !=
        // nil, ensure that you create and set an appropriate error when returning nil.
        // You can also choose to override fileWrapperOfType:error:, writeToURL:ofType:error:, or
        // writeToURL:ofType:forSaveOperation:originalContentsURL:error: instead.
        throw NSError(domain: NSOSStatusErrorDomain, code: unimpErr, userInfo: nil)
    }

    override func read(from data: Data, ofType typeName: String) throws {
        // Insert code here to read your document from the given data of the specified type. If
        // outError != nil, ensure that you create and set an appropriate error when returning
        // false.
        // You can also choose to override readFromFileWrapper:ofType:error: or
        // readFromURL:ofType:error: instead.
        // If you override either of these, you should also override -isEntireFileLoaded to return
        // false if the contents are lazily loaded.
        throw NSError(domain: NSOSStatusErrorDomain, code: unimpErr, userInfo: nil)
    }

    // If I were loading a flat file type instead of a package, I would readFromData and dataOfType.
    override func fileWrapper(ofType typeName: String) throws -> FileWrapper {
        let textRTFData = try self.text.data(
            from: NSRange(0..<self.text.length),
            documentAttributes: [
                NSDocumentTypeDocumentAttribute: NSRTFTextDocumentType
            ]
        )

        if let oldTextFileWrapper = self.documentFileWrapper
            .fileWrappers?[MetaNoteDocumentFilenames.TextFile.rawValue] {
            self.documentFileWrapper.removeFileWrapper(oldTextFileWrapper)
        }

        self.documentFileWrapper.addRegularFile(
            withContents: textRTFData,
            preferredFilename: MetaNoteDocumentFilenames.TextFile.rawValue)

        return self.documentFileWrapper
    }

    override func read(from fileWrapper: FileWrapper, ofType typeName: String) throws {
        // Make sure we have additional file wrappers in this file wrapper.
        guard let fileWrappers = fileWrapper.fileWrappers else {
            throw err(code: .CannotLoadFileWrappers)
        }

        // Make sure we can actually get the document text.
        let key = MetaNoteDocumentFilenames.TextFile.rawValue
        guard let documentTextData = fileWrappers[key]?.regularFileContents else {
            throw err(code: .CannotLoadText)
        }

        // Then load the document text.
        guard let documentText = AttributedString(rtf: documentTextData, documentAttributes: nil)
            else {
                throw err(code: .CannotLoadText)
        }

        // And keep the text in memory.
        self.documentFileWrapper = fileWrapper
        self.text = documentText
    }
}
