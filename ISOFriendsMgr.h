//
//  ISOFriendsMgr.h
//  Halime
//
//  Created by Imdat Solak on Tue Jan 29 2002.
//  Copyright (c) 2001 Imdat Solak. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface ISOFriendsMgr : NSObject
{
	NSMutableArray	*friends;
}
+ sharedFriendsMgr;
- (void)_loadFriends;
- (void)_saveFriends;
- init;
- (void)dealloc;
- addFriend:(NSString *)aFriend requester:(id)sender;
- removeFriendAtIndex:(int)anIndex requester:(id)sender;
- replaceFriendAtIndex:(int)anIndex withFriend:(NSString *)aFriend requester:(id)sender;
- (NSString *)friendAtIndex:(int)index;
- (int)friendsCount;
- (void)friendsChanged:sender;
- (NSArray *)friends;
- (void)ping;
@end
