//
//  ISOMasterSubscriptionWindowMgr.h
//  Halime
//
//  Created by iso on Fri Aug 17 2001.
//  Copyright (c) 2001 Imdat Solak. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface ISOMasterSubscriptionWindowMgr : NSWindowController 
{
    id	theSubscriptionMgr;
}

- initWithWindowNibName:(NSString *)nibName;
- setSubscriptionMgr:(id)aSubscriptionMgr;
- (void)subscriptionChanged:sender;
- setSubscriptionEdited:(BOOL)flag;
@end
