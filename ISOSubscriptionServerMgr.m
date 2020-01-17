//
//  ISOSubscriptionServerMgr.m
//  Halime
//
//  Created by iso on Fri Aug 17 2001.
//  Copyright (c) 2001 Imdat Solak. All rights reserved.
//

#import "ISOSubscriptionServerMgr.h"
#import "ISONewsServerMgr.h"
#import "ISOPreferences.h"
#import "ISONewsGroup.h"
#import "ISONewsServer.h"
#import "ISOSubscriptionMgr.h"
#import "ISOSubscription.h"
#import "ISOBeep.h"
#import "ISOLogger.h"

@implementation ISOSubscriptionServerMgr
- (id)init
{
	[super init];
	filteredGroups = nil;
	timer = nil;
	return self;
}

- (void)dealloc
{
	[filteredGroups release];
	[super dealloc];
}

- (void)filterGroups
{
	NSString		*aString = [groupsField stringValue];
	BOOL			matches = ([[groupFieldTitlePopup selectedItem] tag] == 0);
	int				i, count;
	ISONewsGroup	*aGroup;
	NSRange			aRange;
	NSArray			*groups;
	
	if (filteredGroups) {
		[filteredGroups removeAllObjects];
	} else {
		filteredGroups = [[NSMutableArray array] retain];
	}
	groups = [[activeServerMgr newsServer] activeList];
	if ((!aString) || ([aString length] == 0)) {
		[filteredGroups addObjectsFromArray:groups];
	} else {
		count = [groups count];
		for (i=0;i<count;i++) {
			aGroup = [groups objectAtIndex:i];
			aRange = [[aGroup groupName] rangeOfString:aString];
			if ((matches) && (aRange.length == [aString length])) {
				[filteredGroups addObject:aGroup];
			} else if (!matches && (aRange.length != [aString length])) {
				[filteredGroups addObject:aGroup];
			}
		}
	}
}

- (void)timedFilter
{
	[self groupsFieldChanged:self];
}

- (void)sheetDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void  *)context
{
}
- (void)runSheetForWindow:(id)aWindow
{
	changed = NO;
	[serverTable setAutosaveTableColumns:YES];
	[serverTable setAutosaveName:@"ISOServerTable"];
	[groupsTable setAutosaveTableColumns:YES];
	[groupsTable setAutosaveName:@"ISOServerGroupsTable"];
	[[NSApplication sharedApplication] beginSheet:window
			modalForWindow:aWindow
			modalDelegate:self
			didEndSelector:@selector(sheetDidEnd:returnCode:contextInfo:)
			contextInfo:nil];
    [serverTable setDataSource:self];
    [groupsTable setDataSource:self];
    activeServerMgr = nil;
    [serverTable reloadData];
    [groupsTable reloadData];
	if ([[ISOPreferences sharedInstance] serverCount] == 1) {
		[serverTable selectRow:0 byExtendingSelection:NO];
		[self serverSelected:self];
	}
	[groupsTable setDoubleAction:@selector(subscribe:)];
    cancelProgress = NO;
}

- (int)numberOfRowsInTableView:(NSTableView *)aTableView
{
    if (aTableView == serverTable) {
        return [[ISOPreferences sharedInstance] serverCount];
    } else if (aTableView == groupsTable) {
        if (activeServerMgr) {
            return [filteredGroups count];
        } else {
            return 0;
        }
    } else {
        return 0;
    }
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex
{
    if (aTableView == serverTable) {
        return [self serverValueForTableColumn:aTableColumn row:rowIndex];
    } else if (aTableView == groupsTable) {
        return [self groupValueForTableColumn:aTableColumn row:rowIndex];
    } else {
        return nil;
    }
}

- (id)serverValueForTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex
{
	ISONewsServerMgr	*aMgr;
    ISONewsServer		*aServer;
    aMgr = [[ISOPreferences sharedInstance] newsServerMgrForServerAtIndex:rowIndex];
    aServer = [aMgr newsServer];
    if ([(NSString *)[aTableColumn identifier] compare:@"SERVER"] == NSOrderedSame) {
        return [aServer serverName];
    } else {
        NSNumber *aNumber = [NSNumber numberWithInt:[aServer numberOfGroups]];
        [aNumber retain];
        return aNumber;
    }
    return nil;
}

- (id)groupValueForTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex
{
    ISONewsGroup	*aGroup;
    
    aGroup = [filteredGroups objectAtIndex:rowIndex];
    if ([(NSString *)[aTableColumn identifier] compare:@"GROUP"] == NSOrderedSame) {
        return [aGroup groupName];
    } else if ([(NSString *)[aTableColumn identifier] compare:@"ARTICLES"] == NSOrderedSame) {
        NSNumber *aNumber = [NSNumber numberWithInt:[aGroup high] - [aGroup low]];
        [aNumber retain];
        return aNumber;
    } else {
        return [[theSubscriptionMgr theSubscription] isSubscribedTo:aGroup]? @"¥":@"";
    }
    return nil;
}

- (void)serverSelected:sender
{
    int	rowIndex;
    ISONewsServerMgr	*newsServerMgr;
    ISONewsServer		*newsServer;
    
    rowIndex = [serverTable selectedRow];
	if (rowIndex >= 0) {
		newsServerMgr = [[ISOPreferences sharedInstance] newsServerMgrForServerAtIndex:rowIndex];
		newsServer = [newsServerMgr newsServer];
		activeServerMgr = newsServerMgr;
		
		if ([newsServer numberOfGroups] == 0) {
			[statusTextField setStringValue:NSLocalizedString(@"Loading groups, please wait...", @"")];
			[statusTextField display];
			if (![newsServer loadActiveList:self]) {
				int	result = NSRunAlertPanel(NSLocalizedString(@"No Groups for this server loaded",@"Title shown when there are no newsgroups from a specified server are loaded"),
								NSLocalizedString(@"There are currently no groups from this servers downloaded on your machine. Would you like to download the newsgroup list in order to subscribe to groups?", @""),
								NSLocalizedString(@"Download Groups", @"Default Button Title"),
								nil,
								NSLocalizedString(@"Cancel", @"") );
				if (result == NSAlertDefaultReturn) {
					[self _loadGroups:newsServerMgr];
					[self filterGroups];
					[groupsTable reloadData];
				}
			} else {
				[self filterGroups];
				[groupsTable reloadData];
			}
			[statusTextField setStringValue:@""];
			[statusTextField display];
		} else {
			[self filterGroups];
			[groupsTable reloadData];
		}
	}
}

- (void)_loadGroups:(ISONewsServerMgr *)aMgr
{    
    int	result;
    theProgressController = [[ISOProgressController alloc] initWithDelegate:self 
            title:NSLocalizedString(@"Loading Newsgroups",@"")
            andMessage:NSLocalizedString(@"You CAN NOT cancel the operation by hitting Cmd-.", @"")];
	[aMgr setDelegate:self];
    cancelProgress = NO;
    if ([aMgr connect:self]) {
        [theProgressController setIndefinite:YES];
		[theProgressController start:self];
        result = [aMgr updateActiveList:self];
		[theProgressController stop:self];
        [theProgressController dealloc];
        [aMgr disconnect:self];
    }
}

- (void)refreshServerGroups:sender
{
    int	rowIndex;
    ISONewsServerMgr	*newsServerMgr;
    ISONewsServer		*newsServer;
    
    rowIndex = [serverTable selectedRow];
	if (rowIndex >= 0) {
		newsServerMgr = [[ISOPreferences sharedInstance] newsServerMgrForServerAtIndex:rowIndex];
		newsServer = [newsServerMgr newsServer];
		activeServerMgr = newsServerMgr;
		[statusTextField setStringValue:NSLocalizedString(@"Loading groups, please wait...", @"")];
		[statusTextField display];
		[self _loadGroups:newsServerMgr];
		[self filterGroups];
		[groupsTable reloadData];
		[statusTextField setStringValue:@""];
		[statusTextField display];
	}
}

- (void)groupsFieldChanged:sender
{
	if (timer) {
		[timer invalidate];
		timer = nil;
	}
	[self filterGroups];
	[groupsTable reloadData];
}

- (void)groupSelected:sender
{
    [subscribeButton setEnabled:[groupsTable numberOfSelectedRows]>0];
}

- (void)subscribe:sender
{
    NSEnumerator	*rowEnum = [groupsTable selectedRowEnumerator];
    NSNumber		*rowId;
    ISONewsGroup	*aGroup;
    int				rowNo;
    int				numberOfRows = 0;
    int				count;
    NSArray			*rows;

    if (activeServerMgr) {
        numberOfRows = [groupsTable numberOfSelectedRows];
        if (numberOfRows > 0) {
            rowNo = 0;
            rows = [rowEnum allObjects];
            count = [rows count];
            for (rowNo=0; rowNo<count; rowNo++) {
                rowId = [rows objectAtIndex:rowNo];
                aGroup = [filteredGroups objectAtIndex:[rowId intValue]];
                [[theSubscriptionMgr theSubscription] addGroup:aGroup];
            }
        }
        if (numberOfRows > 0) {
            [theSubscriptionMgr subscriptionChanged:self];
			[groupsTable reloadData];
			changed = YES;
        }
    } else {
        [ISOBeep beep:@"You should first select a server to subscribe from."];
    }
}

- (void)cancel:sender
{
	if (timer) {
		[timer invalidate];
		timer = nil;
	}
	[window orderOut:self];
	[[NSApplication sharedApplication] endSheet:window];
	if (changed) {
		[theSubscriptionMgr updateGroupsDisplay];
	}
}

/* ISONewsServerMgr Delegate Method */
- (int)newsServerMgr:(id)sender readGroup:(int)groupNo
{
    NSMutableString *aString = [NSMutableString stringWithCapacity:30];
    
    if ((groupNo % 50) == 0) {
		[theProgressController stepForwardBy:50];
		[aString appendFormat:@"%@ %d", NSLocalizedString(@"Loaded groups:", @""), groupNo];
		[theProgressController setDisplayString:aString];
	}
    return (cancelProgress? -1:0);
}

/* ISOProgressController Delegate Method */
- (BOOL)userWantsToCancelProgress:sender
{
    cancelProgress = YES;
    return YES;
}

- setSubscriptionMgr:(id)aSubscriptionMgr
{
    theSubscriptionMgr = aSubscriptionMgr;
    return self;
}

- (void)subscriptionChanged:sender
{
}


- setSubscriptionEdited:(BOOL)flag
{
	[window setDocumentEdited:flag];
	return self;
}

- (void)controlTextDidChange:(NSNotification *)aNotification
{
	if ([aNotification object] == groupsField) {
		if (timer) {
			[timer invalidate];
			timer = nil;
		}
		timer = [NSTimer scheduledTimerWithTimeInterval:0.7
							target:self
							selector:@selector(timedFilter)
							userInfo:nil
							repeats:NO];
		if ([groupsTable numberOfSelectedRows] >0) {
			[groupsTable deselectAll:self];
		}

	}
}

@end
