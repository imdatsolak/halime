//
//  ISOSubsDrawerMgr.h
//  Halime
//
//  Created by Imdat Solak on Sat Feb 16 2002.
//  Copyright (c) 2001 Imdat Solak. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "ISOSubscriptionMgr.h"
@class ISOSubscriptionWindowMgr;

@interface ISOSubsDrawerMgr : NSObject
{
	id							drawer;

    id							groupsOlv;
	id							boxesOlv;
    id							serverNameField;
	id							removeGroupButton;
	id							activeGroup;
	id							abbreviatedGroupNamesSwitch;
	ISOSubscriptionMgr			*subscriptionMgr;
	ISOSubscriptionWindowMgr	*swm;
	NSArray						*draggedGroups;
	
}

- init;
- (void)dealloc;
- setSubscriptionMgr:(ISOSubscriptionMgr *)aSubscription;
- (void)setSubscriptionWindowMgr:(ISOSubscriptionWindowMgr *)anSwm;
- (void)updateGroupsDisplay;
- (int)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item;
- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item;
- (id)outlineView:(NSOutlineView *)outlineView child:(int)index ofItem:(id)item;
- (id)outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item;
- (void)outlineViewSelectionDidChange:(NSNotification *)aNotification;
- (void)outlineView:(NSOutlineView *)outlineView willDisplayCell:(id)cell forTableColumn:(NSTableColumn *)tableColumn item:(id)item;
- (BOOL)outlineView:(NSOutlineView *)olv writeItems:(NSArray*)items toPasteboard:(NSPasteboard*)pboard;
- (NSDragOperation)outlineView:(NSOutlineView*)olv validateDrop:(id <NSDraggingInfo>)info proposedItem:(id)item proposedChildIndex:(int)childIndex;
- (BOOL)outlineView:(NSOutlineView*)olv acceptDrop:(id <NSDraggingInfo>)info item:(id)targetItem childIndex:(int)childIndex;
- (void)newsgroupSelected:sender;
- (void)addGroupsButtonClicked:sender;
- (void)removeGroupButtonClicked:sender;
- (BOOL)isShowingDrawer;
- (void)showHideDrawer;
- (void)toggleAbbreviatedGroupNames:sender;
@end
