//
//  ISOSinglePostingLoader.h
//  Halime
//
//  Created by Imdat Solak on Wed Jan 08 2003.
//  Copyright (c) 2003 Imdat Solak. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "ISONewsGroup.h"
#import "ISOSubscriptionMgr.h"
#import "ISOSubscriptionWindowMgr.h"

@interface ISOSinglePostingLoader : NSObject
{
	id					messageIDPanel;
	id					messageIDField;
	id					loadingMessageField;
	id					windowMgr;
	ISONewsGroup		*workingGroup;
	ISOSubscriptionMgr	*subscriptionMgr;
}

- (void)runSheetForWindow:(id)aWindow withGroup:(ISONewsGroup *)aGroup andSubscriptionMgr:(ISOSubscriptionMgr *)theSubscriptionMgr windowMgr:(ISOSubscriptionWindowMgr *)aMgr;
- (void)loadPosting:sender;
- (void)cancel:sender;
@end
