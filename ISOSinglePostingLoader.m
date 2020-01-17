//
//  ISOSinglePostingLoader.m
//  Halime
//
//  Created by Imdat Solak on Wed Jan 08 2003.
//  Copyright (c) 2003 Imdat Solak. All rights reserved.
//

#import "ISOSinglePostingLoader.h"


@implementation ISOSinglePostingLoader

- init
{
	[super init];
	workingGroup = nil;
	subscriptionMgr = nil;
	windowMgr = nil;
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

- (void)runSheetForWindow:(id)aWindow withGroup:(ISONewsGroup *)aGroup andSubscriptionMgr:(ISOSubscriptionMgr *)theSubscriptionMgr windowMgr:(ISOSubscriptionWindowMgr *)aMgr
{
	if ((!workingGroup) && (aGroup)) {
		windowMgr = aMgr;
		workingGroup = aGroup;
		[workingGroup retain];
		subscriptionMgr = theSubscriptionMgr;
		[loadingMessageField setStringValue:@""];
		[messageIDField setStringValue:@""];
		[[NSApplication sharedApplication] beginSheet:messageIDPanel 
				modalForWindow:aWindow
				modalDelegate:nil
				didEndSelector:nil
				contextInfo:nil];
	}
}

- (void)loadPosting:sender
{
	NSMutableString *mIDToDownload = [NSMutableString string];
	ISONewsPosting	*loadedPosting = nil;
	NSRange aRange, bRange;
	if ([[messageIDField stringValue] length]) {
		[loadingMessageField setStringValue:NSLocalizedString(@"Loading...", @"Loading...")];
	
		aRange = [[messageIDField stringValue] rangeOfString:@"<"];
		bRange = [[messageIDField stringValue] rangeOfString:@">"];
		if (aRange.location == NSNotFound) {
			[mIDToDownload appendString:@"<"];
		}
		[mIDToDownload appendString:[messageIDField stringValue]];
		if (bRange.location == NSNotFound) {
			[mIDToDownload appendString:@">"];
		}
		loadedPosting = [workingGroup loadPostingWithMessageID:mIDToDownload withPostingLoader:nil];
		[messageIDPanel orderOut:self];
		if (loadedPosting == nil) {
			NSRunAlertPanel(NSLocalizedString(@"Couldn't load MessageID", @""),
				NSLocalizedString(@"Couldn't load a posting with the message ID given. The posting doesn't exist or the message ID was wrong.", @""),
				NSLocalizedString(@"OK", @"OK"),
				nil,nil
			);
		} else if (windowMgr) {
			[windowMgr selectPosting:loadedPosting];
		}
	} else {
		[messageIDPanel orderOut:self];
	}
	[[NSApplication sharedApplication] endSheet:messageIDPanel];
	if (workingGroup) {
		[workingGroup release];
		workingGroup = nil;
	}
}

- (void)cancel:sender
{
	[messageIDPanel orderOut:self];
	[[NSApplication sharedApplication] endSheet:messageIDPanel];
	if (workingGroup) {
		[workingGroup release];
		workingGroup = nil;
	}
}

@end
