//
//  ISOPostingNumberResetter.m
//  Halime
//
//  Created by Imdat Solak on Sun Apr 21 2002.
//  Copyright (c) 2002 Imdat Solak. All rights reserved.
//

#import "ISOPostingNumberResetter.h"

@implementation ISOPostingNumberResetter

- init
{
	[super init];
	workingGroup = nil;
	subscriptionMgr = nil;
	return self;
}

- (void)dealloc
{
	if (workingGroup) {
		[workingGroup release];
		workingGroup = nil;
	}
	[super dealloc];
}

- (void)runSheetForWindow:(id)aWindow withGroup:(ISONewsGroup *)aGroup andSubscriptionMgr:(ISOSubscriptionMgr *)theSubscriptionMgr
{
	if ((!workingGroup) && (aGroup)) {
		workingGroup = aGroup;
		[workingGroup retain];
		subscriptionMgr = theSubscriptionMgr;
		[resetLPNField setIntValue:[workingGroup lastPostingIndex]];
		[[NSApplication sharedApplication] beginSheet:resetLastPostingNumberPanel 
				modalForWindow:aWindow
				modalDelegate:nil
				didEndSelector:nil
				contextInfo:nil];
	}
}


- (void)_doResetPostingNumber
{
	if (workingGroup) {
		[workingGroup setLastPostingIndex:[resetLPNField intValue]];
		[subscriptionMgr subscriptionChanged:self];
	} else {
		NSBeep();
	}
}


- (void)resetPostingNumber:sender
{
	[self _doResetPostingNumber];
	[resetLastPostingNumberPanel orderOut:self];
	[[NSApplication sharedApplication] endSheet:resetLastPostingNumberPanel];
	if (workingGroup) {
		[workingGroup release];
		workingGroup = nil;
	}
}

- (void)cancel:sender
{
	[resetLastPostingNumberPanel orderOut:self];
	[[NSApplication sharedApplication] endSheet:resetLastPostingNumberPanel];
	if (workingGroup) {
		[workingGroup release];
		workingGroup = nil;
	}
}


@end
