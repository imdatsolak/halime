//
//  ISOPostingWindowMgr.h
//  Halime
//
//  Created by Imdat Solak on Mon Dec 24 2001.
//  Copyright (c) 2001 Imdat Solak. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "ISONewsPosting.h"
#import "ISOSubscription.h"

@interface ISOPostingWindowMgr : NSObject
{
	id	subjectField;
	id	newsgroupsField;
	id	fromField;
	id	followUpField;
	id	replyToField;
	id	attachmentsTable;
	id	removeButton;
	id	textView;
	id	identityPopup;
	id	rewrapBeforeSendingSwitch;
	id	window;
	id	encodingPopup;
	
	id	newsgroupsPopup;
	id	followUpToPopup;
	
	BOOL isFollowUp;
	BOOL isReplyTo;
	
	ISONewsPosting	*originalPosting;
	ISONewsPosting	*deferredPosting;
	ISONewsGroup	*theGroup;
	id	storedReferences;
	id	storedMessageID;
	NSMutableArray	*attachments;
	
	id	encMsgWindow;
	id	encAttNameField;
	id	encAttLeftField;
	
	// Additional Headers
	id	additionalHeadersPanel;
	id	headerTable;
	id	headerField;
	id	valueField;
	id	addHeaderButton;
	id	deleteHeaderButton;
	id	changeHeaderButton;
	NSString	*theSelection;
	
	NSMutableArray	*additionalHeaders;
}

- initFromDeferredPosting:(ISONewsPosting *)oldPosting;
- initNewPostingInGroup:(ISONewsGroup *)aGroup;
- initFollowUpTo:(ISONewsPosting *)aPosting inGroup:(ISONewsGroup *)aGroup selectionText:(NSString *)selectionText;
- initFollowUpTo:(ISONewsPosting *)aPosting inGroup:(ISONewsGroup *)aGroup;

- initReplyTo:(ISONewsPosting *)aPosting inGroup:(ISONewsGroup *)aGroup selectionText:(NSString *)selectionText;
- initReplyTo:(ISONewsPosting *)aPosting inGroup:(ISONewsGroup *)aGroup;

- (void)showWindow;
- (void)_setIdentity:(NSString *)userName :(NSString *)eMail :(NSString *)signature;

- (void)identityChanged:sender;
- (void)addAttachmentButtonClicked:sender;
- (void)removeAttachmentButtonClicked:sender;
- (void)sendClicked:sender;
- (void)cancelClicked:sender;
- (void)saveClicked:sender;
- (void)loadClicked:sender;
- (BOOL)windowShouldClose:(id)sender;
- (void)textDidChange:(NSNotification *)aNotification;
- (void)controlTextDidChange:(NSNotification *)aNotification;

- (void)_sendPosting;
- (void)attachmentTableClicked:sender;
- (int)numberOfRowsInTableView:(NSTableView *)aTableView;
- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex;
- (void)recolorizeTextview:sender;
- (void)encodingChanged:sender;

/** TOOLBAR **/
- (void)setupToolbar;
- (NSArray *) toolbarAllowedItemIdentifiers: (NSToolbar *) toolbar;
- (NSArray *) toolbarDefaultItemIdentifiers: (NSToolbar *) toolbar;
- (void)_setToolbarItem:(NSToolbarItem *)anItem label:(NSString *)aLabel paletteLabel:(NSString *)paletteLabel toolTip:(NSString *)toolTip image:(NSString *)imageName target:(id)target action:(SEL)action;
- (NSToolbarItem *) toolbar: (NSToolbar *)toolbar itemForItemIdentifier: (NSString *) itemIdent willBeInsertedIntoToolbar:(BOOL) willBeInserted;
- (void) toolbarWillAddItem: (NSNotification *) notif;
- (void) toolbarDidRemoveItem: (NSNotification *) notif;
- (BOOL) validateToolbarItem: (NSToolbarItem *) toolbarItem;

/* *************** Additional Headers ******************* */
- (void)headerEntryFieldsChanged:(NSNotification *)aNotification;
- (void)additionalHeaders:(id)sender;
- (void)headerTableClicked:(id)sender;
- (void)addHeader:(id)sender;
- (void)deleteHeader:(id)sender;
- (void)changeHeader:(id)sender;
- (void)finishedEditingHeaders:sender;

- (void)newsgroupsPopupClicked:sender;
- (void)followUpToPopupClicked:sender;
- (NSString *)_makeSMTPEmailAddress:(NSString *)aString;
- (NSString *)recipientEmail;
@end
