//
//  ISOPostingNumberResetter.h
//  Halime
//
//  Created by Imdat Solak on Sun Apr 21 2002.
//  Copyright (c) 2002 Imdat Solak. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "ISONewsGroup.h"
#import "ISOSubscriptionMgr.h"

@interface ISOPostingNumberResetter : NSObject 
{
	id					resetLastPostingNumberPanel;
	id					resetLPNField;
	ISONewsGroup		*workingGroup;
	ISOSubscriptionMgr	*subscriptionMgr;
}

- (void)runSheetForWindow:(id)aWindow withGroup:(ISONewsGroup *)aGroup andSubscriptionMgr:(ISOSubscriptionMgr *)theSubscriptionMgr;
- (void)resetPostingNumber:sender;
- (void)cancel:sender;
@end
