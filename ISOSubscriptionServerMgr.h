//
//  ISOSubscriptionServerMgr.h
//  Halime
//
//  Created by iso on Fri Aug 17 2001.
//  Copyright (c) 2001 Imdat Solak. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "ISONewsServerMgr.h"
#import "ISOProgressController.h"

@interface ISOSubscriptionServerMgr : NSObject
{
    id	serverTable;
    id	groupsField;
    
    id	groupsTable;
    id	subscribeButton;
    id	unsubscribeButton;
    
    ISONewsServerMgr		*activeServerMgr;
    ISOProgressController	*theProgressController;
	NSMutableArray			*filteredGroups;
    BOOL cancelProgress;
    
    id	statusTextField;
    id	theSubscriptionMgr;
	id	window;
	id	groupFieldTitlePopup;
	BOOL	changed;
	NSTimer	*timer;
}
- (void)runSheetForWindow:(id)aWindow;
- (int)numberOfRowsInTableView:(NSTableView *)aTableView;
- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex;
- (id)serverValueForTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex;
- (id)groupValueForTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex;

- (void)serverSelected:sender;
- (void)_loadGroups:(ISONewsServerMgr *)aMgr;
- (void)refreshServerGroups:sender;
- (void)groupsFieldChanged:sender;
- (void)groupSelected:sender;

- (void)subscribe:sender;
- (void)cancel:sender;

/* ISONewsServerMgr Delegate Method */
- (int)newsServerMgr:(id)sender readGroup:(int)groupNo;

/* ISOProgressController Delegate Method */
- (BOOL)userWantsToCancelProgress:sender;
- setSubscriptionMgr:(id)aSubscriptionMgr;
- (void)subscriptionChanged:sender;
- setSubscriptionEdited:(BOOL)flag;

@end
