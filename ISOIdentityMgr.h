//
//  ISOIdentityMgr.h
//  Halime
//
//  Created by Imdat Solak on Mon Jan 28 2002.
//  Copyright (c) 2001 Imdat Solak. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface ISOIdentityMgr : NSObject
{
	id	identityTable;
	id	addIdentityButton;
	id	removeIdentityButton;
	id	changeIdentityButton;
	
	id	idNameField;
	id	nameField;
	id	emailField;
	id	xFaceField;
	id	xFaceURLField;
	id	randomSigSwitch;
	id	signatureTable;
	id	isDefaultSwitch;
	
	id	identitySheet;
	id	sheetOkButton;
	id	sheetCancelButton;
	
	id	faceImageView;
	NSMutableArray	*identities;
}

+ sharedIdentityMgr;
- (void)_loadIdentities;
- (void)_saveIdentities;
- init;
- (void)dealloc;
- (void)updateIdentityTable;
- (void)identitySelected:sender;
- (void)addIdentity:sender;
- (void)removeIdentity:sender;
- (void)changeIdentity:sender;
- (void)reallyChangeIdentity:sender;
- (void)reallyAddIdentity:sender;
- (void)cancel:sender;
- (void)randomSigSwitchClicked:sender;
- (void)displayXFace:sender;
- (void)displayXFaceURL:sender;
- (int)defaultIdentityIndex;
- (int)identityCount;
- (NSString *)idNameOfIdentityAtIndex:(int)index;
- (NSString *)nameOfIdentityAtIndex:(int)index;
- (NSString *)emailOfIdentityAtIndex:(int)index;
- (NSString *)signatureOfIdentityAtIndex:(int)index;
- (NSString *)xFaceOfIdentityAtIndex:(int)index;
- (NSString *)xFaceURLOfIdentityAtIndex:(int)index;

- (int)numberOfRowsInTableView:(NSTableView *)aTableView;
- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex;

@end
