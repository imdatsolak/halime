//
//  ISOFriendsFavController.m
//  Halime
//
//  Created by Imdat Solak on Tue Jan 29 2002.
//  Copyright (c) 2001 Imdat Solak. All rights reserved.
//

#import "ISOFriendsMgr.h"
#import "ISOSubjectsMgr.h"

#import "ISOFriendsFavController.h"


@implementation ISOFriendsFavController
- (void)resetButtons
{
	[addButton setEnabled:[[entryField stringValue] length]];
	[removeButton setEnabled:[[entryField stringValue] length] && ([entryTable selectedRow]>=0)];
	[changeButton setEnabled:[[entryField stringValue] length] && ([entryTable selectedRow]>=0)];
}

- (void)sheetDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void  *)context
{
}


- runSheetForFriends:(BOOL)forFriends inWindow:(id)aWindow
{
	displayingFriends = forFriends;
    [entryTable setDataSource:self];
	[[NSApplication sharedApplication] beginSheet:window
			modalForWindow:aWindow
			modalDelegate:self
			didEndSelector:@selector(sheetDidEnd:returnCode:contextInfo:)
			contextInfo:nil];
	[self resetButtons];
    [entryTable reloadData];
	if (forFriends) {
		[titleField setStringValue:NSLocalizedString(@"Editing Friends List", @"")];
	} else {
		[titleField setStringValue:NSLocalizedString(@"Editing Favorite Subjects", @"")];
	}
	return self;
}

- (void)addToFriends:(NSString *)aString inWindow:(id)aWindow
{
	[entryField setStringValue:aString];
	[self runSheetForFriends:YES inWindow:aWindow];
}

- (void)addToSubjects:(NSString *)aString inWindow:(id)aWindow
{
	[entryField setStringValue:aString];
	[self runSheetForFriends:NO inWindow:aWindow];
}

- (void)addEntry:sender
{
	if (displayingFriends) {
		[[ISOFriendsMgr sharedFriendsMgr] addFriend:[entryField stringValue] requester:self];
	} else {
		[[ISOSubjectsMgr sharedSubjectsMgr] addSubject:[entryField stringValue] requester:self];
	}
	[self resetButtons];
    [entryTable reloadData];
}

- (void)changeEntry:sender
{
	int	index = [entryTable selectedRow];
	if (index >= 0 && (index < [self numberOfRowsInTableView:nil])) {
		if (displayingFriends) {
			[[ISOFriendsMgr sharedFriendsMgr] replaceFriendAtIndex:index withFriend:[entryField stringValue] requester:self];
		} else {
			[[ISOSubjectsMgr sharedSubjectsMgr] replaceSubjectAtIndex:index withSubject:[entryField stringValue] requester:self];
		}
	}
	[self resetButtons];
    [entryTable reloadData];
}

- (void)deleteEntry:sender
{
	int	index = [entryTable selectedRow];
	if (index >= 0 && (index < [self numberOfRowsInTableView:nil])) {
		if (displayingFriends) {
			[[ISOFriendsMgr sharedFriendsMgr] removeFriendAtIndex:index requester:self];
		} else {
			[[ISOSubjectsMgr sharedSubjectsMgr] removeSubjectAtIndex:index requester:self];
		}
	}
	[self resetButtons];
    [entryTable reloadData];
}

- (void)entrySelected:sender
{
	int	index = [entryTable selectedRow];
	if (index >= 0 && (index < [self numberOfRowsInTableView:nil])) {
		if (displayingFriends) {
			[entryField setStringValue:[[ISOFriendsMgr sharedFriendsMgr] friendAtIndex:index]];
		} else {
			[entryField setStringValue:[[ISOSubjectsMgr sharedSubjectsMgr] subjectAtIndex:index]];
		}
	}
	[self resetButtons];
}
	
- (void)okClicked:sender
{
	[window orderOut:self];
	[[NSApplication sharedApplication] endSheet:window];
}

- (int)numberOfRowsInTableView:(NSTableView *)aTableView
{
	if (displayingFriends) {
		return [[ISOFriendsMgr sharedFriendsMgr] friendsCount];
	} else {
		return [[ISOSubjectsMgr sharedSubjectsMgr] subjectsCount];
	}
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex
{
	if (displayingFriends) {
		return [[ISOFriendsMgr sharedFriendsMgr] friendAtIndex:rowIndex];
	} else {
		return [[ISOSubjectsMgr sharedSubjectsMgr] subjectAtIndex:rowIndex];
	}
}

- (void)controlTextDidChange:(NSNotification *)aNotification
{
	if ([aNotification object] == entryField) {
		[addButton setEnabled:[[entryField stringValue] length]];
		[removeButton setEnabled:[[entryField stringValue] length] && ([entryTable selectedRow]>=0)];
		[changeButton setEnabled:[[entryField stringValue] length] && ([entryTable selectedRow]>=0)];
	}
}


@end
