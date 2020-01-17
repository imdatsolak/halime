//
//  ISOOutPostingMgr.h
//  Halime
//
//  Created by Imdat Solak on Sat Jan 26 2002.
//  Copyright (c) 2001 Imdat Solak. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "ISONewsPosting.h"


@interface ISOOutPostingMgr : NSObject
{
	NSMutableArray	*outPostings;
}

+ sharedOutPostingMgr;
- init;
- (void)dealloc;
- addOutPosting:(ISONewsPosting *)aPosting requester:(id)sender;
- removeOutPosting:(ISONewsPosting *)aPosting requester:(id)sender;
- (void)outpostingsChanged:sender;
- (void)ping;
@end
