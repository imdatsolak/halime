//
//  ISOMasterSubscriptionWindowMgr.m
//  Halime
//
//  Created by iso on Fri Aug 17 2001.
//  Copyright (c) 2001 Imdat Solak. All rights reserved.
//

#import "ISOMasterSubscriptionWindowMgr.h"


@implementation ISOMasterSubscriptionWindowMgr

- initWithWindowNibName:(NSString *)nibName
{
    [super initWithWindowNibName:nibName];
    theSubscriptionMgr = nil;
    return self;
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
	[[self window] setDocumentEdited:flag];
	return self;
}

@end
