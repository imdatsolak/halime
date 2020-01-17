//
//  ISOSignatureMgr.h
//  Halime
//
//  Created by Imdat Solak on Mon Jan 28 2002.
//  Copyright (c) 2001 Imdat Solak. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface ISOSignatureMgr : NSObject
{
	id	signatureTable;
	id	addSignatureButton;
	id	removeSignatureButton;
	id	changeSignatureButton;
	
	id	titleField;
	id	signatureField;
	id	randomSigSwitch;

	id	signatureSheet;
	id	sheetOkButton;
	id	sheetCancelButton;
	
	NSMutableArray	*signatures;
	NSMutableArray	*randomSignatures;
	int				lastRandomSigIndex;
}

+ sharedSignatureMgr;
- (void)_loadSignatures;
- (void)_saveSignatures;
- init;
- (void)dealloc;
- (void)updateSignatureTable;
- (void)signatureSelected:sender;
- (void)addSignature:sender;
- (void)removeSignature:sender;
- (void)changeSignature:sender;
- (void)reallyChangeSignature:sender;
- (void)reallyAddSignature:sender;
- (void)cancel:sender;
- (NSString *)signatureTitleAtIndex:(int)index;
- (int)indexOfSignature:(NSString *)sigTitle;
- (NSString *)signatureAtIndex:(int)index;
- (NSString *)randomSignature;

- (int)numberOfRowsInTableView:(NSTableView *)aTableView;
- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex;
- (void)readSignatureFile:(NSString *)filename;
- (void)reallyImportSignatures:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void  *)conInfo;
- (void)importSignatures:sender;
@end
