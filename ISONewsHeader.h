//
//  ISONewsHeader.h
//  Halime
//
//  Created by iso on Fri Apr 27 2001.
//  Copyright (c) 2001 Imdat Solak. All rights reserved.
//

#import <Foundation/Foundation.h>
#define K_HASATTACHMENTS		1
#define K_MAYBEHASATTACHMENTS	-1
#define K_HASNOATTACHMENTS		0
#define K_MAYBEATTACHMENT_LINE_LIMIT	300


@interface ISONewsHeader : NSObject
{
	NSMutableDictionary	*headers;
	NSString			*rawHeader;
}

- init;
- initFromString:(NSString *)aString;
- initFromDictionary:(NSDictionary *)aDictionary;

- (int)headerCount;
- (NSMutableDictionary *)fullHeader;
- (NSString *)headerForKey:(NSString *)headerKey;

- (NSString *)rawHeader;
- (NSString *)fromHeader;
- (NSString *)newsgroupsHeader;
- (NSString *)dateHeader;
- (NSString *)subjectHeader;
- (NSString *)linesHeader;
- (NSString *)messageIDHeader;
- (NSString *)organizationHeader;
- (NSString *)contentTypeHeader;
- (NSString *)contentTransferEncodingHeader;
- (NSString *)referencesHeader;
- (NSString *)followUpHeader;
- (NSString *)replyToHeader;
- (NSString *)xFaceHeader;
- (NSString *)xFaceURLHeader;
- (NSString *)bytesHeader;
- (BOOL)isPostingRead;
- setPostingRead:(BOOL)flag;
- (BOOL)isPostingInvalid;
- setPostingInvalid:(BOOL)flag;
- (int)hasAttachments;
- (void)setPostingPath:(NSString *)aPath;
- (NSString *)postingPath;
- (void)setMainGroupName:(NSString *)groupName;
- (NSString *)mainGroupName;
- (void)setArticleServerID:(int)anID;
- (int)articleServerID;
- (BOOL)readFromString:(NSString *)aString;
- (BOOL)writeToString:(NSMutableString *)aString;
- (id)setIsOnHold:(BOOL)flag;
- (BOOL)isOnHold;
- setServerName:(NSString *)serverName;
- (NSString *)serverName;

- (void)setIsForwarded:(BOOL)flag;
- (void)setIsReplied:(BOOL)flag;
- (void)setIsFollowedUp:(BOOL)flag;
- (BOOL)isForwarded;
- (BOOL)isReplied;
- (BOOL)isFollowedUp;
- (void)createComparableDate;
- (NSString *)comparableDate;
- (NSString *)transferableHeader;
- (BOOL)isLocked;
- (void)setIsLocked:(BOOL)flag;
- (BOOL)isFlagged;
- (void)setIsFlagged:(BOOL)flag;

- (void)setIsInDownloadManager:(BOOL)flag;
- (BOOL)isInDownloadManager;
@end
