//
//  ISOGraphicalTVMgr.m
//  Halime
//
//  Created by Imdat Solak on Fri Feb 01 2002.
//  Copyright (c) 2001 Imdat Solak. All rights reserved.
//

#import "ISOGraphicalTVMgr.h"
#import "ISOGraphicalTV.h"
#import "ISOLogger.h"
#import "NSPopUpButton_Extensions.h"

@implementation ISOGraphicalTVMgr
- init
{
	[super init];
	target = nil;
	action = nil;
	doubleAction = nil;
	owner = nil;
	selectedPosting = nil;
	return self;
}

- (void)dealloc
{
	[graphicalTV setThread:nil];
	[super dealloc];
}

- (void)toggleDrawer
{
	[drawer toggle:self];
	[graphicalTV setDelegate:self];
}

- (void)setThread:(NSArray *)aThread ofOwner:(id)anObject
{
	owner = anObject;
	[graphicalTV setThread:aThread];
}

- (void)redisplayPosting:(ISONewsPosting *)aPosting
{
	[graphicalTV redisplayPosting:aPosting];
}

- (void)setTarget:(id)anObject
{
	target = anObject;
}

- (void)setAction:(SEL)anAction
{
	action = anAction;
}

- (void)setDoubleAction:(SEL)anAction
{
	doubleAction = anAction;
}

- (BOOL)isShowingGTV
{
	return (([drawer state] == NSDrawerOpeningState) || ([drawer state] == NSDrawerOpenState));
}

- (id)owner
{
	return owner;
}

- (void)setOwner:(id)anObject
{
	owner = anObject;
}

- (ISONewsPosting *)selectedPosting
{
	return selectedPosting;
}

- (void)changeImageSizeTo:(int)aSize
{
	if ((aSize == GTV_IS_16) || (aSize == GTV_IS_32) || (aSize == GTV_IS_48)) {
		[graphicalTV changeImageSizeTo:aSize];
		if (owner && [owner respondsToSelector:@selector(gtv:imageSizeChangedTo:)]) {
			[owner gtv:self imageSizeChangedTo:aSize];
		}
		[imageSizePopup selectItemWithTag:aSize];
	}
}

- (void)changeImageSize:(id)sender
{
	[self changeImageSizeTo:[[imageSizePopup selectedItem] tag]];
}

- (void)toggleDetailedTooltip:(id)sender
{
	[graphicalTV setDetailedTooltip:[detailedTooltipSwitch state]];
}

/* *************** Graphical TV Target Methods ************** */
- (void)graphicalTV:(id)graphicalTV itemSelected:(ISONewsPosting *)aPosting
{
	selectedPosting = aPosting;
	if (target && action && [target respondsToSelector:action]) {
		[target performSelector:action withObject:self];
	}
}

- (void)graphicalTV:(id)graphicalTV itemDoubleClicked:(ISONewsPosting *)aPosting
{
	selectedPosting = aPosting;
	if (target && doubleAction && [target respondsToSelector:doubleAction]) {
		[target performSelector:doubleAction withObject:self];
	}
}

- (void)graphicalTV:(id)graphicalTV itemRightClicked:(ISONewsPosting *)aPosting
{
	selectedPosting = aPosting;
	NSBeep();
}

@end
