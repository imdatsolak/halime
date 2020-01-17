//
//  ISOSplitPostingWindowMgr.m
//  Halime
//
//  Created by Imdat Solak on Wed Apr 03 2002.
//  Copyright (c) 2001 Imdat Solak. All rights reserved.
//

#import "ISOSplitPostingWindowMgr.h"
#import "ISOSubscriptionMgr.h"

@implementation ISOSplitPostingWindowMgr

- (void)windowWillClose:(NSNotification *)aNotification
{
	[[theSubscriptionMgr subscriptionWindowMgr] windowWillClose:aNotification];
}

- (void)window:(id)window spaceBarPressed:(NSEvent *)theEvent
{
	[[theSubscriptionMgr subscriptionWindowMgr] window:window spaceBarPressed:theEvent];
}

- (void)window:(id)window plusKeyPressed:(NSEvent *)theEvent
{
	[[theSubscriptionMgr subscriptionWindowMgr] window:window plusKeyPressed:theEvent];
}

- (void)window:(id)window minusKeyPressed:(NSEvent *)theEvent
{
	[[theSubscriptionMgr subscriptionWindowMgr] window:window minusKeyPressed:theEvent];
}

- (void)window:(id)sender otherKeyPressed:(NSString *)aKey
{
	[[theSubscriptionMgr subscriptionWindowMgr] window:sender otherKeyPressed:aKey];
}
@end
