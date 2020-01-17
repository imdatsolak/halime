//
//  ISOSentPostingsMgr.h
//  Halime
//
//  Created by Imdat Solak on Sun Jan 13 2002.
//  Copyright (c) 2001 Imdat Solak. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ISONewsPosting.h"

@interface ISOSentPostingsMgr : NSObject
{
	NSMutableArray	*sentPostingIDs;
	BOOL	needsSaving;
}

+ (id)sharedInstance;
- (id)init;
- (BOOL)needsSaving;
- (BOOL)save;
- (void)dealloc;
- (BOOL)addSentPostingID:(NSString *)aString;
- (BOOL)expireSentPostingIDs;
- (BOOL)isPostingAReplyToMyPostings:(ISONewsPosting *)aPosting;
@end
