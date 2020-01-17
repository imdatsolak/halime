//
//  ISOFriendsFavController.h
//  Halime
//
//  Created by Imdat Solak on Tue Jan 29 2002.
//  Copyright (c) 2001 Imdat Solak. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface ISOFriendsFavController : NSObject
{
	BOOL	displayingFriends;
	
	id		entryTable;
	id		addButton;
	id		removeButton;
	id		changeButton;
	id		entryField;
	id		titleField;
	id		window;
}

- (void)addToFriends:(NSString *)aString inWindow:(id)aWindow;
- (void)addToSubjects:(NSString *)aString inWindow:(id)aWindow;
- runSheetForFriends:(BOOL)forFriends inWindow:(id)aWindow;
- (void)addEntry:sender;
- (void)changeEntry:sender;
- (void)deleteEntry:sender;
- (void)entrySelected:sender;
- (void)okClicked:sender;
- (int)numberOfRowsInTableView:(NSTableView *)aTableView;
- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex;
@end
