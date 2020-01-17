//
//  ISOSubsDrawerMgr.m
//  Halime
//
//  Created by Imdat Solak on Sat Feb 16 2002.
//  Copyright (c) 2001 Imdat Solak. All rights reserved.
//

#import "ISOSubsDrawerMgr.h"
#import "NSOutlineView_UIExtensions.h"
#import "ISOSubscriptionWindowMgr.h"
#import "ISOLogger.h"
#import "ISOPreferences.h"

#define DragDropSimplePboardType 	@"GroupsSimplePBoardType"

@implementation ISOSubsDrawerMgr
- init
{
	[super init];
	subscriptionMgr = nil;
	swm = nil;
	return self;
}
- (void)dealloc
{
	[super dealloc];
}

- setSubscriptionMgr:(ISOSubscriptionMgr *)aSubscription
{
	subscriptionMgr = aSubscription;
	[abbreviatedGroupNamesSwitch setState:[subscriptionMgr shouldShowAbbreviatedGroupNames]];
	return self;
}

- (void)setSubscriptionWindowMgr:(ISOSubscriptionWindowMgr *)anSwm
{
	swm = anSwm;
}

- (void)updateGroupsDisplay
{
	[groupsOlv reloadData];
}

/* OUTLINE VIEW SUPPORT */
- (int)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item
{
	if (outlineView == groupsOlv) {
		return [[[subscriptionMgr theSubscription] groups] count];
	} else {
		return 0;
	}
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item
{
	if (outlineView == groupsOlv) {
		return NO;
	} else {
		return NO;
	}
}

- (id)outlineView:(NSOutlineView *)outlineView child:(int)index ofItem:(id)item
{
	if (outlineView == groupsOlv) {
		return [[[subscriptionMgr theSubscription] groups] objectAtIndex:index];
	} else {
		return @"";
	}
}
- (id)outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item
{
	if (item) {
		if ([(NSString *)[tableColumn identifier] compare:@"G_GROUPNAME"] == NSOrderedSame) {
			if ([abbreviatedGroupNamesSwitch state]) {
				return [item abbreviatedGroupName];
			} else {
				return [item groupName];
			}
		} else if ([(NSString *)[tableColumn identifier] compare:@"G_ARTICLES"] == NSOrderedSame) {
			return [NSNumber numberWithInt:[item postingCountFlat]];
		} else if ([(NSString *)[tableColumn identifier] compare:@"G_UNREAD"] == NSOrderedSame) {
			return [NSNumber numberWithInt:[item unreadPostingCountFlat]];
		} else {
			return @"--error--";
		}
	} else {
		return @"--error--";
	}
}

- (void)outlineViewSelectionDidChange:(NSNotification *)aNotification
{
	if ([aNotification object] == groupsOlv) {
		[self newsgroupSelected:self];
		[self updateGroupsDisplay];
	}
}

- (void)outlineView:(NSOutlineView *)outlineView willDisplayCell:(id)cell forTableColumn:(NSTableColumn *)tableColumn item:(id)item
{
	if ([item unreadPostingCountFlat] > 0) {
		[cell setTextColor:[[ISOPreferences sharedInstance] prefsUnreadArticleColor]];
	} else {
		[cell setTextColor:[[ISOPreferences sharedInstance] prefsReadArticleColor]];
	}
}

// ================================================================
//  NSOutlineView data source methods. (dragging related)
// ================================================================

- (BOOL)outlineView:(NSOutlineView *)olv writeItems:(NSArray*)items toPasteboard:(NSPasteboard*)pboard
{
    draggedGroups = items;
    [pboard declareTypes:[NSArray arrayWithObjects: DragDropSimplePboardType, nil] owner:self];
    [pboard setData:[NSData data] forType:DragDropSimplePboardType]; 

    return YES;
}

- (NSDragOperation)outlineView:(NSOutlineView*)olv validateDrop:(id <NSDraggingInfo>)info proposedItem:(id)item proposedChildIndex:(int)childIndex
{
    return (childIndex != NSOutlineViewDropOnItemIndex)? NSDragOperationGeneric:NSDragOperationNone;
}

- (BOOL)outlineView:(NSOutlineView*)olv acceptDrop:(id <NSDraggingInfo>)info item:(id)targetItem childIndex:(int)childIndex
{
    NSPasteboard	*pboard = [info draggingPasteboard];
    NSArray			*itemsToSelect = nil;
	int				newIndex;
    
    if ([pboard availableTypeFromArray:[NSArray arrayWithObjects:DragDropSimplePboardType, nil]] != nil) {
		itemsToSelect = draggedGroups;
		[[subscriptionMgr theSubscription] removeGroupsInArray:draggedGroups];
		if (targetItem) {
			newIndex = [[subscriptionMgr theSubscription] indexOfGroup:targetItem];
		} else {
			newIndex = childIndex;
		}
		if (newIndex == -1) {
			newIndex = 0;
		}
        [[subscriptionMgr theSubscription] insertGroupsFromArray:draggedGroups atIndex:newIndex];
    } 

    [groupsOlv reloadData];
    [groupsOlv selectItems:itemsToSelect byExtendingSelection:NO];
	[subscriptionMgr updateGroupsDisplay];
    return YES;
}

/* ******************* */
- (void)newsgroupSelected:sender
{
	[swm newsgroupSelected:sender];
	[removeGroupButton setEnabled:([groupsOlv selectedRow] >=0)];
}

- (void)addGroupsButtonClicked:sender
{
	[swm addGroupsButtonClicked:sender];
}

- (void)removeGroupButtonClicked:sender
{
	int	rows = [groupsOlv numberOfSelectedRows];
	int	choice = NSAlertOtherReturn;
	if (rows > 1) {
		choice = NSRunAlertPanel(NSLocalizedString(@"Remove Group", @""),
			NSLocalizedString(@"Are you sure you want remove the selected groups and all of their postings? This will delete all postings, headers, and attachments of the postings which are not saved somewhere else...", @""),
			NSLocalizedString(@"Cancel", @""),
			nil,
			NSLocalizedString(@"Remove Groups", @"")
			);
	}
	if (rows > 0 && (choice == NSAlertOtherReturn)) {
		NSArray *selectedItems = [groupsOlv selectedItems];
		[[subscriptionMgr theSubscription] removeGroupsInArray:selectedItems];
		[subscriptionMgr subscriptionDataChanged];
		[groupsOlv reloadData];
		[groupsOlv deselectAll:self];
		[self newsgroupSelected:self];
		[swm _updatePostingDisplay];
	}
}

- (BOOL)isShowingDrawer
{
	return (([drawer state] == NSDrawerOpeningState) || ([drawer state] == NSDrawerOpenState));
}


- (void)showHideDrawer
{
	BOOL isOpen;
	[drawer toggle:self];
	
	isOpen = (([drawer state] == NSDrawerOpeningState) || ([drawer state] == NSDrawerOpenState));
	[[NSUserDefaults standardUserDefaults] setObject:[NSString stringWithString:(isOpen? @"YES":@"NO")] forKey:@"ISOGroupDrawerWasOpen"];
	if (isOpen) {
		[groupsOlv reloadData];
	}
}

- (void)toggleAbbreviatedGroupNames:sender
{
	[groupsOlv reloadData];
	[subscriptionMgr setShouldShowAbbreviatedGroupNames:[abbreviatedGroupNamesSwitch state]];
}

- (void)awakeFromNib
{
    [groupsOlv registerForDraggedTypes:[NSArray arrayWithObjects:DragDropSimplePboardType, nil]];
	[abbreviatedGroupNamesSwitch setState:[subscriptionMgr shouldShowAbbreviatedGroupNames]];
}
@end
