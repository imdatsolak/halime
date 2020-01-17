//
//  ISONewsPosting.h
//  Halime
//
//  Created by iso on Fri Apr 27 2001.
//  Copyright (c) 2001 Imdat Solak. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "ISONewsHeader.h"
#import "ISONewsBody.h"
#import "ISOPostingContentRep.h"

#define INP_DecodeSuccessfull 				1
#define	INP_DecodeMultipart					2
#define	INP_DecodeError						3
#define INP_DecodeMultipartAdded			4
#define INP_DecodeMultipartMissingPosting	100

@interface ISONewsPosting : NSObject
{
	ISONewsHeader	*theHeader;
	ISONewsBody		*theBody;
    id				mainGroup;
	BOOL			savedToDisk;
	BOOL			needsSaving;
	int				diskIndex;
	NSMutableArray	*attachments;
	NSMutableArray	*subPostings;
	NSString		*decodedSubject;
	NSString		*decodedSender;
	BOOL			decodedSenderHasOwnEncoding;
	BOOL			decodedSubjectHasOwnEncoding;
	BOOL			isAFollowUp;
	BOOL			isAFUSet;
	NSMutableArray	*parents;
	BOOL			onHold;
	BOOL			isOffline;
	BOOL			wantsToBeDownloaded;
	BOOL			isSelected;
	int				hasAttachments;
	NSRect			gtvFrameRect;
	NSStringEncoding	displayEncoding;
	int				gtvImageSize;
	BOOL			detailedTooltip;
	BOOL			isLoadable;
	NSImage			*xFaceImage;
	int				generation;
	BOOL			isSent;
}

- init;
- initFromString:(NSString *)aString;
- initLazyFromString:(NSString *)aString;
- initLazyFromDictionary:(NSDictionary *)headerDictionary;
- initLazyFromOverviewString:(NSString *)aString withOverviewFmt:(NSArray *)overviewFmt;
- initFromFile:(NSString *)filename;
- (void)dealloc;
- (BOOL)readLazyFromString:(NSString *)aString;
- (BOOL)readFromString:(NSString *)aString;
- (BOOL)writeToString:(NSMutableString *)aString;
- (BOOL)writeToFile:(NSString *)filename;
- (BOOL)readFromFile:(NSString *)filename;
- (BOOL)writeToDirectory:(NSString *)fullpath;
- (BOOL)deepWriteToDirectory:(NSString *)fullpath;
- (NSArray *)deepPostingHeadersFlatIfBodyIsLoaded;
- (NSArray *)deepPostingHeadersFlatIfBodyIsNotLoaded;
- (BOOL)setBodyFromString:(NSString *)aString;
- (BOOL)updateFromString:(NSString *)aString;
- (BOOL)isBodyLoaded;
- setMainGroup:(id)aGroup;
- (id)mainGroup;
- (BOOL)isSavedToDisk;
- (BOOL)needsSaving;
- (BOOL)isRead;
- setIsRead:(BOOL)flag;
- setIsRead:(BOOL)flag withNotification:(BOOL)withNotification;
- (BOOL)isThreadRead;
- setThreadIsRead:(BOOL)flag;
- setPostingInvalid:(BOOL)flag;
- (BOOL)isPostingInvalid;
- (NSString *)postingPath;
- (NSString *)mainGroupName;
- (int)articleServerID;
- setArticleServerID:(int)anID;
- (int)hasAttachments;

/* header access methods */
- (NSString *)headerAsRawText;
- (NSString *)headerForKey:(NSString *)headerKey;
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
- (NSString *)characterEncoding;
- (NSArray *)references;
- (NSString *)transferableHeader;
- (NSString *)bytesHeader;
/* Body Access Methods */
- (NSString *)bodyAsText;
- (NSString *)bodyAsRawText;
- (BOOL)reallyHasAttachments;
- (int)decodeMultiIfNecessary:(NSArray *)allPostings forSender:(id)sender;
- (int)decodeIfNecessary;
- (ISOPostingContentRep *)attachmentWithMajorMimeType:(NSString *)aType andIndex:(int)index;
- (ISOPostingContentRep *)pictureWithIndex:(int)index;
- (ISOPostingContentRep *)videoWithIndex:(int)index;
- (ISOPostingContentRep *)soundWithIndex:(int)index;
- (ISOPostingContentRep *)attachmentWithIndex:(int)index;

- (NSArray *)allContentDecoded; /* This returns an array of ISOPostingContentRep */

- (int)_countForMajorMimeType:(NSString *)aType;
- (int)pictureCount;
- (int)videoCount;
- (int)musicCount;
- (int)attachmentCount;
- (BOOL)wouldItExistAfterApplyingFilters:(NSArray *)filterArray;
/** THREADING SUPPORT **/
- cleanUp;
- (id)deepCleanUp;
- (id)postingAtIndex:(int)index;
- (NSArray *)subPostingsFlat;
- (id)addSubPosting:(id)aPosting;
- (id)removeSubPosting:(id)aPosting;
- (BOOL)hasSubPostings;
- (int)subPostingCount;
- (int)subPostingsCountFlat;
- (int)unreadSubpostingsCountFlat;
- (NSArray *)postingPathsFlatIfBodyLoaded;
- (NSString *)decodedSubject;
- (id)setDecodedSubject:(NSString *)dSubject;
- (NSString *)decodedSender;
- (id)setDecodedSender:(NSString *)dSender;
- (BOOL)_decodedHeaderStringFromString:(NSString *)encodedString into:(NSMutableString *)decodedString putCharacterSetInto:(NSMutableString *)charSet;
- (NSFont *)getArticleBodyEncodingFont;
- (NSStringEncoding )contentEncoding;
- (NSString *)decodedBody;
- (BOOL)isAFollowUp;
- (BOOL)isAFUSet;
- (id)setIsAFollowUp:(BOOL)flag;
- (id)addParent:(id)aParent;
- (id)highestParent;
- (id)removeParent:(id)aParent;
- (void)removeAllParents;
- (id)firstUnreadPostingRelativeToPosting:(ISONewsPosting *)aPosting ignoringSelf:(BOOL)ignoringSelf;
- (id)firstUnreadPostingRelativeToPosting:(ISONewsPosting *)aPosting;
- (id)setIsFlagged:(BOOL)flag;
- (BOOL)isFlagged;
- (id)setIsOnHold:(BOOL)flag;
- (BOOL)isOnHold;
- (void)setIsOffline:(BOOL)flag;
- (BOOL)isOffline;
- setServerName:(NSString *)serverName;
- (NSString *)serverName;
- (void)setIsForwarded:(BOOL)flag;
- (void)setIsReplied:(BOOL)flag;
- (void)setIsFollowedUp:(BOOL)flag;
- (BOOL)isForwarded;
- (BOOL)isReplied;
- (BOOL)isFollowedUp;
- (void)removeAllSubPostings;
- (void)setWantsToBeDownloaded:(BOOL)flag;
- (BOOL)wantsToBeDownloaded;
- (BOOL)isLoadable;
- (void)setIsLoadable:(BOOL)flag;
- (NSString *)comparableDate;
/* Graphical Thread Support */
- (NSPoint)drawThreadAtPoint:(NSPoint)aPoint level:(int)level vertLevel:(int)vertLevel putLastXInto:(float *)lastX calculateOnly:(BOOL)calculateOnly inView:(id)aView shouldRect:(NSRect )inRect intersect:(BOOL)intersectFlag;
- (ISONewsPosting *)hitTest:(NSPoint)aPoint;
- (void)drawIfIntersectsRect:(NSRect )aRect;
- (void)redisplayWithOldFrame;
- (NSRect )gtvFrameRect;
- (void)setGTVImageSize:(int)gtvImageSize;
- (void)setIsSelected:(BOOL)flag;
- (BOOL)isSelected;
- (void)setDetailedTooltip:(BOOL)flag;
/* Encoding Things */
- (void)setDisplayEncoding:(NSStringEncoding )anEncoding;
- (NSStringEncoding )displayEncoding;
- (ISONewsHeader *)theHeader;
- (void)setSavedToDisk:(BOOL)flag;
- (void)setNeedsSaving:(BOOL)flag;
- (void)addAttachment:(ISOPostingContentRep *)anAttachment;
/* SORTING */
- (BOOL)sortPostingsBySubjectAscending:(BOOL)flag;
- (BOOL)sortPostingsBySenderAscending:(BOOL)flag;
- (BOOL)sortPostingsByDateAscending:(BOOL)flag;
- (BOOL)sortPostingsBySizeAscending:(BOOL)flag;
- (ISONewsPosting *)firstParent;
- (void)clearGeneration;
- (int)generation;
- (int)numberOfDescendants;
- (int)threadPostingCount;
- (BOOL)isSent;
- (void)setIsSent:(BOOL)flag;
- (NSImage *)xFaceImage;
- (NSArray *)subPostings;
- (BOOL)isLocked;
- (BOOL)isDeepLocked;
- (void)setIsLocked:(BOOL)flag;
- (void)setIsInDownloadManager:(BOOL)flag;
- (BOOL)isInDownloadManager;
- (BOOL)readFromOtherPosting:(id)anotherPosting;
@end

@interface NSObject(ISONewsPostingDecodingRequester)
- (void)multipartFile:(char *)filename decodingAction:(int)action size:(int)size partno:(int)partno numparts:(int)numparts percent:(float)percent;
@end
