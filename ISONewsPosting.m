//
//  ISONewsPosting.m
//  Halime
//
//  Created by iso on Fri Apr 27 2001.
//  Copyright (c) 2001 Imdat Solak. All rights reserved.
//

#import "ISONewsPosting.h"
#import "ISONewsGroup.h"
#import "ISOResourceMgr.h"
#import "ISOPreferences.h"
#import "ISOSentPostingsMgr.h"
#import "ISOSPAMFilterMgr.h"
#import "ISOOfflineMgr.h"
#import "ISOLogger.h"
#import "NSString_Extensions.h"
#import <CoreFoundation/CFString.h>
#import <CoreFoundation/CFData.h>
#import <CoreFoundation/CFStringEncodingExt.h>
#import <uudeview.h>
#import <regex.h>
#import "Functions.h"
#import "ISOGraphicalTV.h"

#define K_QPBEGIN_STRING	@"=?"
#define K_QPEND_STRING		@"?="


extern char * UUGetFileName (char *subject, char *ptonum, char *ptonend);

@implementation ISONewsPosting
//static NSDictionary	*encodings = nil;
static NSDictionary	*mimeTypeDictionary = nil;
static NSDictionary *cfstringEncodings = nil;

int ISO_UUDecodeQP (char *datain, char *dataout, int *state,
	    long maxpos, int method, int flags,
	    char *boundary)
{
  char *line=datain, *p1, *p2;
  int val;
  int	uulboundary;

  uulboundary = -1;
  dataout[0] = '\0';

    if (boundary && line[0]=='-' && line[1]=='-' &&
	strncmp (line+2, boundary, strlen (boundary)) == 0) {
      if (line[strlen(boundary)+2]=='-')
	uulboundary = 1;
      else
	uulboundary = 0;
      return UURET_OK;
    }

    p1 = p2 = line;

    while (*p2) {
      while (*p2 && *p2 != '=')
	p2++;
      if (*p2 == '\0')
	break;
      *p2 = '\0';
	  strcat(dataout, p1);
      p1  = ++p2;

      if (isxdigit (*p2) && isxdigit (*(p2+1))) {
	val  = ((isdigit(*p2))    ?  (*p2-'0')   : (tolower(*p2)-'a'+10)) << 4;
	val |= ((isdigit(*(p2+1)))?(*(p2+1)-'0') : (tolower(*(p2+1))-'a'+10));

	dataout[strlen(dataout)+1] = '\0';
	dataout[strlen(dataout)] = val;
	p2 += 2;
	p1  = p2;
      }
      else if (*p2 == '\012' || *(p2+1) == '\015') {
	*p2 = '\0';
	break;
      }
      else {
	dataout[strlen(dataout)+1] = '\0';
	dataout[strlen(dataout)] = '=';
      }
    }
    /*
     * p2 points to a nullbyte right after the CR/LF/CRLF
     */
    val = 0;
    while (p2>p1 && isspace (*(p2-1))) {
      if (*(p2-1) == '\012' || *(p2-1) == '\015')
	val = 1;
      p2--;
    }
    *p2 = '\0';

	strcat(dataout, p1);
  return UURET_OK;
}

int MultipartInProgress(void *opaque, uuprogress *uup)
{
	id	controller = opaque;
	
	if (controller && [controller respondsToSelector:@selector(multipartFile:decodingAction:size:partno:numparts:percent:)]) {
		[controller multipartFile:uup->curfile 
					decodingAction:uup->action
					size:uup->fsize
					partno:uup->partno
					numparts:uup->numparts
					percent:uup->percent];
	}
	return UURET_OK;
}

- (void)_checkDownloadManagerStatus
{
	if ([self isInDownloadManager]) {
		[[ISOOfflineMgr sharedOfflineMgr] addToDownloads:self];
	}
}

- init
{
	self = [super init];
	theHeader = nil;
	theBody = nil;
    mainGroup  = nil;
	savedToDisk = NO;
	diskIndex = -1;
	needsSaving = YES;
	attachments = nil;
	onHold = NO;
	isOffline = NO;
	wantsToBeDownloaded = NO;
	isSelected = NO;
	hasAttachments = 0;
	detailedTooltip = NO;
	isLoadable = NO;
	xFaceImage = nil;
	generation = 0;
	isSent = NO;
	if (!mimeTypeDictionary) {
		mimeTypeDictionary = [[ISOPreferences sharedInstance] mimeTypeDictionary];
	}
	if (cfstringEncodings == nil) {
		cfstringEncodings = [[ISOPreferences sharedInstance] cfstringEncodings];
	}
	subPostings = [[NSMutableArray array] retain];
	parents = [[NSMutableArray array] retain];
	decodedSubject = nil;
	decodedSender = nil;
	isAFUSet = NO;
	isAFollowUp = NO;
	displayEncoding = MAC_ISOUNKNOWNENCODINGINT;
	decodedSenderHasOwnEncoding = NO;
	decodedSubjectHasOwnEncoding = NO;
	gtvImageSize = GTV_IS_32;
	return self;
}

/* This is the init-Method for initializing with the HEADER Only */
- initLazyFromDictionary:(NSDictionary *)headerDictionary
{
	if ([self init] != nil) {
		theHeader = [[ISONewsHeader alloc] initFromDictionary:headerDictionary];
		if (theHeader) { 
			theBody = nil;
			needsSaving = NO;
			[self _checkDownloadManagerStatus];
			return self;
		} else {
			[self dealloc];
			return nil;
		}
	}
	return nil;
}

- initLazyFromString:(NSString *)aString
{
	if ([self init] != nil) {
		if ([self readLazyFromString:aString]) {
			return self;
		} else {
			[self dealloc];
			return nil;
		}
	}
	return nil;
}

- initLazyFromOverviewString:(NSString *)aString withOverviewFmt:(NSArray *)overviewFmt
{
	NSMutableString	*headString = [NSMutableString stringWithCapacity:[aString length]+128];
	NSMutableString	*keyString;
	NSString		*workString;
	NSScanner		*aScanner;
	NSString		*tempStr;
	NSString		*blankString = @"\t";
	int				i, count;
	NSRange			aRange, bRange;
	int				articleId;
	
	count = [overviewFmt count];
	aScanner = [NSScanner scannerWithString:aString];
	[aScanner scanInt:&articleId];
	workString = [NSString stringWithString:aString];
	aRange = [workString rangeOfString:blankString];
	i = 0;
	while (aRange.length == 1) {
		workString = [workString substringFromIndex:aRange.location+1];
		aRange = [workString rangeOfString:blankString];
		if (aRange.length != 1) {
			aRange.location = [workString length]-1;
		}
		if (i >= [overviewFmt count]) {
			[ISOActiveLogger logWithDebuglevel:50 :@"overViewFmt Info is shorter than the Overview itself..."]; 
		} else {
			keyString = [NSMutableString stringWithString:[overviewFmt objectAtIndex:i]];
			if ([keyString hasPrefix:@"Xref:full"]) {
				keyString = [NSMutableString stringWithString:@"Xref:"];
				if ([workString hasPrefix:@"Xref: "]) {
					workString = [workString substringFromIndex:6]; // Skip first six chars
					aRange.location -= 5;
				}
			}
			if (aRange.location <= 0) {
				tempStr = [NSString stringWithString:@""];
			} else {
				tempStr = [workString substringToIndex:aRange.location];
			}
			bRange = [keyString rangeOfString:@"\r"];
			if (bRange.length != 1) {
				bRange = [keyString rangeOfString:@"\n"];
			}
			if (bRange.length == 1) {
				keyString = [NSMutableString stringWithString:[keyString substringToIndex:bRange.location]];
			}
			[headString appendString:keyString];
			[headString appendString:@" "];
			[headString appendString:tempStr];
			[headString appendString:@"\r\n"];
		}
		i++;
	}
	[headString appendString:@"\r\n"];
	if ([self initLazyFromString:headString]) {
		[theHeader setArticleServerID:articleId];
		return self;
	} else {
		return nil;
	}
}

- initFromString:(NSString *)aString
{
	if ([self init] != nil) {
		if ([self readFromString:aString]) {
			return self;
		} else {
			[self dealloc];
			return nil;
		}
	}
	return nil;
}

- initFromFile:(NSString *)filename
{
	[self init];
	if ([self readFromFile:filename]) {
		savedToDisk = YES;
		needsSaving = NO;
		return self;
	} else {
		[self dealloc];
		return nil;
	}
}

- (void)dealloc
{
	[subPostings release];
	subPostings = nil;
	[parents release];
	parents = nil;
	[theHeader release];
	theHeader = nil;
	[theBody release];
	theBody = nil;
	[attachments release];
	attachments = nil;
	[xFaceImage release];
	xFaceImage = nil;
	[decodedSubject release];
	decodedSubject = nil;
	[decodedSender release];
	decodedSender = nil;
	[super dealloc];
}

- (BOOL)readFromString:(NSString *)aString
{
	if (theHeader) {
		[theHeader release];
	}
	if (theBody) {
		[theBody release];
	}
	theHeader = [[ISONewsHeader alloc] initFromString:aString];
	if (theHeader) { 
		theBody = [[ISONewsBody alloc] initFromString:aString];
		if (theBody) {
			hasAttachments = [theBody hasAttachments];
		}
		needsSaving = YES;
		[self _checkDownloadManagerStatus];
		return YES; // IS Lazy reader ;-)
	}
	return NO;
}

- (BOOL)readLazyFromString:(NSString *)aString
{
	if (theHeader) {
		[theHeader release];
	}
	if (theBody) {
		[theBody release];
	}
	theHeader = [[ISONewsHeader alloc] initFromString:aString];
	if (theHeader) { 
		theBody = nil;
		[self _checkDownloadManagerStatus];
		return YES;
	}
	return NO;
}

- (BOOL)writeToString:(NSMutableString *)aString
{
	if ([theHeader writeToString:aString]) {
		[theBody writeToString:aString];
		return YES;
	}
	return NO;
}

- (BOOL)writeToFile:(NSString *)filename
{
	NSMutableString	*aString;
	BOOL			retVal = NO;

	if (filename) {
		aString = [NSMutableString stringWithCapacity:1];
		if ([self writeToString:aString]) {
			if ([aString writeToFile:filename atomically:NO]) {
				retVal = YES;
			}
		}
	}
	return retVal;
}

- (BOOL)readFromFile:(NSString *)filename
{
	BOOL		retVal = NO;
	NSString	*aString = [NSString stringWithContentsOfFile:filename];
	
	if (aString) {
		if ([self readFromString:aString]) {
			retVal = YES;
		}
	}
	return retVal;
}

- (BOOL)writeToDirectory:(NSString *)fullpath
{
	NSMutableString	*finalFilename;
	
	if ((theBody != nil) && needsSaving) {
		finalFilename = [NSMutableString stringWithString:fullpath];
		[finalFilename appendString:@"/"];
		[finalFilename appendString:[theHeader messageIDHeader]];
		[finalFilename appendString:@".news"];
		
		[theHeader setPostingPath:finalFilename];

		savedToDisk = YES;
		if ([self writeToFile:finalFilename]) {
			needsSaving = NO;
			return YES;
		} else {
			return NO;
		}
	} else {
		return YES;
	}
}

- (BOOL)deepWriteToDirectory:(NSString *)fullpath
{
	int 	i, count;
	
	count = [subPostings count];
	for (i=0;i<count;i++) {
		[[subPostings objectAtIndex:i] deepWriteToDirectory:fullpath];
	}
	[self writeToDirectory:fullpath];
	return YES;
}

- (NSArray *)deepPostingHeadersFlatIfBodyIsNotLoaded:(BOOL)flag
{
	NSMutableArray		*postingHeaders = nil;
	NSMutableDictionary	*headerDict = nil;
	int 	i, count;
	
	postingHeaders = [NSMutableArray array];
	if (flag) {
		if (![self isBodyLoaded]) {
			headerDict = [NSMutableDictionary dictionaryWithDictionary:[theHeader fullHeader]];
		}
	} else {
		if ([self isBodyLoaded] || isLoadable) {
			headerDict = [NSMutableDictionary dictionaryWithDictionary:[theHeader fullHeader]];
		}
			
	}
	if (headerDict) {
		[postingHeaders addObject:headerDict];
	}
	count = [subPostings count];
	for (i=0;i<count;i++) {
		[postingHeaders addObjectsFromArray:[[subPostings objectAtIndex:i] deepPostingHeadersFlatIfBodyIsNotLoaded:flag]];
	}
	return postingHeaders;
}

- (NSArray *)deepPostingHeadersFlatIfBodyIsLoaded
{
	return [self deepPostingHeadersFlatIfBodyIsNotLoaded:NO];
}

- (NSArray *)deepPostingHeadersFlatIfBodyIsNotLoaded
{
	return [self deepPostingHeadersFlatIfBodyIsNotLoaded:YES];
}

- (BOOL)setBodyFromString:(NSString *)aString
{
    if (theBody) {
        [theBody release];
	}
	theBody = [[ISONewsBody alloc] initFromString:aString];
	if (theBody) {
		hasAttachments = [theBody hasAttachments];
		isOffline = NO;
		needsSaving = YES;
		return YES;
	}
    return NO;
}

- (BOOL)updateFromString:(NSString *)aString
{
	if ([self setBodyFromString:aString]) {
		return [theHeader readFromString:aString];
	} else {
		return NO;
	}
}

- (BOOL)isBodyLoaded
{
    return ((theBody != nil) || (isLoadable));
}

- setMainGroup:(id)aGroup
{
    mainGroup = aGroup;
	needsSaving = YES;
	[theHeader setMainGroupName:[aGroup groupName]];
    return self;
}

- (id)mainGroup
{
    return mainGroup;
}

- (BOOL)isSavedToDisk
{
	return savedToDisk;
}

- (BOOL)needsSaving
{
	return needsSaving;
}

- (BOOL)isRead
{
	return [theHeader isPostingRead];
}

- setIsRead:(BOOL)flag
{
	return [self setIsRead:flag withNotification:YES];
}

- setIsRead:(BOOL)flag withNotification:(BOOL)withNotification
{
	needsSaving = needsSaving || ([self isRead] != flag);
	[theHeader setPostingRead:flag];
	if (withNotification && mainGroup && needsSaving) {
		if (flag) {
			[[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:@"ISOPostingRead" object:self]];
		} else {
			[[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:@"ISOPostingUnread" object:self]];
		}
	}
	return self;
}

- (BOOL)isThreadRead
{
	if ([theHeader isPostingRead]) {
		BOOL isRead = YES;
		int i, count;
		NSArray *spFlat = [self subPostingsFlat];
		
		count = [spFlat count];
		i = 0;
		while (i<count && isRead) {
			isRead = [[spFlat objectAtIndex:i] isRead];
			i++;
		}
		return isRead;
	} else {
		return NO;
	}
}

- setThreadIsRead:(BOOL)flag
{
	int i, count;
	NSArray *spFlat = [self subPostingsFlat];
	
	count = [spFlat count];
	for (i=0;i<count;i++) {
		[[spFlat objectAtIndex:i] setIsRead:flag];
	}
	[self setIsRead:flag];
	return self;
}

- (BOOL)isPostingInvalid
{
	return [theHeader isPostingInvalid];
}

- setPostingInvalid:(BOOL)flag
{
	needsSaving = needsSaving || ([self isPostingInvalid] != flag);
	[theHeader setPostingInvalid:flag];
	return self;
}

- (NSString *)postingPath
{
	return [theHeader postingPath];
}

- (NSString *)mainGroupName
{
	return [theHeader mainGroupName];
}


- (int)articleServerID
{
	return [theHeader articleServerID];
}

- setArticleServerID:(int)anID
{
	needsSaving = needsSaving || ([self articleServerID] != anID);
	[theHeader setArticleServerID:anID];
	return self;
}

- (int)hasAttachments
{
	if (attachments && [attachments count]) {
		return K_HASATTACHMENTS;
	}
	if (hasAttachments) {
		return K_HASATTACHMENTS;
	}
	return [theHeader hasAttachments];
}

/* Header Access Methods */
- (NSString *)headerAsRawText
{
	return [theHeader rawHeader];
}

- (NSString *)headerForKey:(NSString *)headerKey
{
	return [theHeader headerForKey:headerKey];
}

- (NSString *)fromHeader
{
	return [theHeader fromHeader];
}

- (NSString *)newsgroupsHeader
{
	return [theHeader newsgroupsHeader];
}

- (NSString *)dateHeader
{
	return [theHeader dateHeader];
}

- (NSString *)subjectHeader
{
	return [theHeader subjectHeader];
}

- (NSString *)linesHeader
{
	return [theHeader linesHeader];
}

- (NSString *)messageIDHeader
{
	return [theHeader messageIDHeader];
}

- (NSString *)organizationHeader
{
	return [theHeader organizationHeader];
}

- (NSString *)contentTypeHeader
{
	return [theHeader contentTypeHeader];
}

- (NSString *)contentTransferEncodingHeader
{
	return [theHeader contentTransferEncodingHeader];
}

- (NSString *)referencesHeader
{
	return [theHeader referencesHeader];
}

- (NSString *)followUpHeader
{
	return [theHeader followUpHeader];
}


- (NSString *)replyToHeader
{
	return [theHeader replyToHeader];
}

- (NSString *)characterEncoding
{
	NSString	*aString = [self contentTypeHeader];
	NSRange		aRange;
	
	aRange = [aString rangeOfString:@"charset="];
	if (aRange.length == 8) {
		aString = [aString substringFromIndex:aRange.location + aRange.length];
		aRange = [aString rangeOfString:@";"];
		if (aRange.length == 1) {
			aString = [aString substringToIndex:aRange.location];
		}
		if ([aString hasPrefix:@"\""]) {
			aString = [aString substringFromIndex:1];
		}
		if ([aString hasSuffix:@"\""]) {
			aString = [aString substringToIndex:[aString length]-1];
		}
		return aString;
	}
	return @"";
}

/* Body access methods */
- (NSString *)bodyAsText
{
	if ((!theBody || ![theBody body]) && isLoadable) {
		[self readFromFile: [self postingPath]];
	}
	if ([theBody body]) {
		return [theBody body]; // This will change to return the TEXT part only
	} else if (isOffline) {
		return NSLocalizedString(@"<The body of this posting is not loaded.>\n<You are currently OFFLINE, so the body cannot be loaded.>\n<Please choose 'Go Online' from the 'Subscription'-Menu and try again>", @"");
	} else {
		return NSLocalizedString(@"<Body not loaded due to some weird error>", @"");
	}
}

- (NSString *)bodyAsRawText
{
	if ((!theBody || ![theBody body]) && isLoadable) {
		[self readFromFile: [self postingPath]];
	}
	if ([theBody body]) {
		return [theBody body];
	} else if (isOffline) {
		return NSLocalizedString(@"<The body of this posting is not loaded.>\n<You are currently OFFLINE, so the body cannot be loaded.>\n<Please choose 'Go Online' from the 'Subscription'-Menu and try again>", @"");
	} else {
		return NSLocalizedString(@"<Body not loaded due to some weird error>", @"");
	}
}

- (BOOL)reallyHasAttachments
{
	[self decodeIfNecessary];
	if (attachments) {
		return ([attachments count] > 0);
	} else {
		return NO;
	}
}


- (int)_addMissingPostingsFrom:(NSArray *)allPostings toItem:(uulist *)item putPostingsInto:(NSMutableArray *)mpArray
{
	int				returnvalue = INP_DecodeSuccessfull;
	int				i, count;
	int				foundCount;
	ISONewsPosting	*onePosting;
	char			*aPath;
	char			*filename;
	char			*ptr;

	if (!item) {
		return INP_DecodeError;
	}
	if (item->filename) {
		filename = malloc(strlen(item->filename)+1);
		bzero(filename, strlen(item->filename)+1);
		strcpy(filename, item->filename);
	} else {
		ptr = UUGetFileName([[self subjectHeader] cString], NULL, NULL);
		filename = malloc(strlen(ptr)+1);
		bzero(filename, strlen(ptr)+1);
		strcpy(filename, ptr);
		free(ptr);
	}
	count = [allPostings count];
	foundCount = 0;
	i=0;
	while (i<count && (returnvalue != INP_DecodeError)) {
		onePosting = [allPostings objectAtIndex:i];
		if (onePosting != self) {
			ptr = UUGetFileName([[onePosting subjectHeader] cString], NULL, NULL);
			[ISOActiveLogger logWithDebuglevel:20 :@"Checking for filename: [%s] against [%s]", filename, ptr];
			if (ptr && (strstr(filename, ptr) != NULL)) {
				if ([onePosting isBodyLoaded] && (returnvalue == INP_DecodeSuccessfull)) {
					foundCount++;
					if ([onePosting needsSaving]) {
						[onePosting setSavedToDisk:YES];
						if ([[onePosting theHeader] postingPath] && [onePosting bodyAsRawText]) {
							[onePosting writeToFile:[[onePosting theHeader] postingPath]];
							[onePosting setNeedsSaving:NO];
						} else {
							[onePosting writeToDirectory:@"/private/tmp"];
							[onePosting setNeedsSaving:YES];
						}
					}
					[mpArray addObject:onePosting];
					aPath = malloc ([[onePosting postingPath] length] + 1);
					memset(aPath, 0, [[onePosting postingPath] length] + 1);
					[[onePosting postingPath] getCString:aPath];
					if (UULoadFile(aPath, NULL, 0) != UURET_OK) {
						returnvalue = INP_DecodeError;
					}
					free(aPath);
				} else if ((returnvalue != INP_DecodeError) && (![onePosting isBodyLoaded])) {
					[[ISOOfflineMgr sharedOfflineMgr] addToDownloads:onePosting];
					returnvalue = INP_DecodeMultipartAdded;
					foundCount++;
				}
			}
			if (ptr) {
				free(ptr);
			}
		} else {
			foundCount++;
		}
		i++;
	}
	free(filename);
	return returnvalue;
}

- (int)decodeMultiIfNecessary:(NSArray *)allPostings forSender:(id)sender
{
	int	returnvalue = INP_DecodeSuccessfull;
	char					*aPath;
	char					*targetPath;
	int						itemNo;
	uulist					*item;
	char					buf[32];
	ISOPostingContentRep	*aRep;
	char					*ext;
	NSString				*stringPath;
	NSString				*contentType, *extension;
	NSString				*tempPath;
	NSMutableArray			*mpArray = [NSMutableArray array];
	int						i, mpCount;
	
	if ([self isBodyLoaded] && (!attachments)) {
		if (needsSaving) {
			savedToDisk = YES;
			if ([theHeader postingPath] && [self bodyAsRawText]) {
				[self writeToFile:[theHeader postingPath]];
				needsSaving = NO;
			} else {
				[self writeToDirectory:@"/private/tmp"];
				needsSaving = YES;
			}
		}
		attachments = [[NSMutableArray arrayWithCapacity:1] retain];
		UUInitialize();
		UUSetOption(UUOPT_FAST, 0, NULL);
		UUSetOption(UUOPT_DESPERATE, 0, NULL);
		UUSetOption(UUOPT_IGNREPLY, 0, NULL);
		UUSetBusyCallback(sender, MultipartInProgress, 2000);
		aPath = malloc ([[self postingPath] length] + 1);
		memset(aPath, 0, [[self postingPath] length] + 1);
		[[self postingPath] getCString:aPath];
		if (UULoadFile(aPath, NULL, 0) == UURET_OK) {
			itemNo = 0;
			item = UUGetFileListItem(itemNo);
			if (item) {
				if ((item->state & UUFILE_MISPART) || (item->state & UUFILE_NOEND) || (item->state & UUFILE_NOBEGIN)) {
					returnvalue = [self _addMissingPostingsFrom:allPostings toItem:item putPostingsInto:mpArray];
					if (returnvalue == INP_DecodeSuccessfull) {
						UUSmerge(0);
						UUSmerge(1);
						UUSmerge(99);
						//item = UUGetFileListItem(itemNo);
						if ((item->state & UUFILE_MISPART) || (item->state & UUFILE_NOEND) || (item->state & UUFILE_NOBEGIN)) {
							[ISOActiveLogger logWithDebuglevel:1 :@"Missing parts: %d", item->state];
							returnvalue = INP_DecodeMultipartMissingPosting;
						}
					}
				}
				if (returnvalue == INP_DecodeSuccessfull) {
					targetPath = malloc([[self postingPath] length] + 128);
					memset(targetPath, 0, [[self postingPath] length] + 128);
					[[self postingPath] getCString:targetPath];
					strcat(targetPath, ".att");
					tempPath = [NSString stringWithCString:targetPath];
					if (![ISOResourceMgr createDirectory:tempPath]) {
						[ISOActiveLogger logWithDebuglevel:1 :@"Couldn't create path: %@", tempPath];
					}
					strcat(targetPath, "/");
					if (item->filename) {
						strcat(targetPath, item->filename);
					} else {
						sprintf(buf, "%d.txt", itemNo);
						strcat(targetPath, buf);
					}
					if (UUDecodeFile(item, targetPath) == UURET_OK) {
						ext = malloc(strlen(targetPath)+1);
						memset(ext, 0, strlen(targetPath)+1);
						if (strrchr(targetPath, '.')) {
							strcpy (ext, strrchr(targetPath, '.')+1);
						} else {
							strcpy(ext, "txt");
						}
						stringPath = [NSString stringWithCString:targetPath];
						extension = [[NSString stringWithCString:ext] lowercaseString];
						if ([mimeTypeDictionary objectForKey:extension]) { /* Let's try to guess the content-type */
							contentType = [mimeTypeDictionary objectForKey:extension];
						} else if (item->mimetype) {
							contentType = [NSString stringWithCString:item->mimetype];
						} else {
							contentType = [NSString stringWithString:@"application/octet-stream"];
						}
						aRep = [[ISOPostingContentRep alloc] initLazyWithContentType:contentType extension:extension forPath:stringPath];
						[attachments addObject:aRep];
						mpCount = [mpArray count];
						for (i=0;i<mpCount;i++) {
							[[mpArray objectAtIndex:i] addAttachment:aRep];
						}
						[mpArray removeAllObjects];
						free(ext);
					} else {
						returnvalue = INP_DecodeError;
					}
					itemNo++;
					free(targetPath);
				}
			}
		}
		free(aPath);
		UUCleanUp();
		if ([attachments count] == 0) {
			[attachments release];
			attachments = nil;
		}
	}
	return returnvalue;
}

- (int)decodeIfNecessary
{
	int						returnvalue = INP_DecodeSuccessfull;
	char					*aPath;
	char					*targetPath;
	int						itemNo;
	uulist					*item;
	char					buf[32];
	ISOPostingContentRep	*aRep;
	char					*ext;
	NSString				*stringPath;
	NSString				*contentType, *extension;
	NSString				*tempPath;
	
	if ([self isBodyLoaded] && (!attachments)) {
		if (needsSaving) {
			savedToDisk = YES;
			if ([theHeader postingPath] && [self bodyAsRawText]) {
				[self writeToFile:[theHeader postingPath]];
				needsSaving = NO;
			} else {
				[self writeToDirectory:@"/private/tmp"];
				needsSaving = YES;
			}
		}
		attachments = [[NSMutableArray arrayWithCapacity:1] retain];
		UUInitialize();
		UUSetOption(UUOPT_FAST, 0, NULL);
		UUSetOption(UUOPT_DESPERATE, 0, NULL);
		UUSetOption(UUOPT_IGNREPLY, 0, NULL);
//		UUSetOption(UUOPT_USETEXT, 1, NULL);
		
		aPath = malloc ([[self postingPath] length] + 1);
		memset(aPath, 0, [[self postingPath] length] + 1);
		[[self postingPath] getCString:aPath];
		if (UULoadFile(aPath, NULL, 0) == UURET_OK) {
			itemNo = 0;
			while (item = UUGetFileListItem(itemNo)) {
				if ((item->state & UUFILE_MISPART) || (item->state & UUFILE_NOEND) || (item->state & UUFILE_NOBEGIN)) {
					returnvalue = INP_DecodeMultipart;
					break;
				} else {
					targetPath = malloc([[self postingPath] length] + 128);
					memset(targetPath, 0, [[self postingPath] length] + 128);
					[[self postingPath] getCString:targetPath];
					strcat(targetPath, ".att");
					tempPath = [NSString stringWithCString:targetPath];
					if (![ISOResourceMgr createDirectory:tempPath]) {
						[ISOActiveLogger logWithDebuglevel:1 :@"Couldn't create path: %@", tempPath];
					}
					strcat(targetPath, "/");
					if (item->filename) {
						strcat(targetPath, item->filename);
					} else {
						sprintf(buf, "%d.txt", itemNo);
						strcat(targetPath, buf);
					}
					if (UUDecodeFile(item, targetPath) == UURET_OK) {
						ext = malloc(strlen(targetPath)+1);
						memset(ext, 0, strlen(targetPath)+1);
						if (strrchr(targetPath, '.')) {
							strcpy (ext, strrchr(targetPath, '.')+1);
						} else {
							strcpy(ext, "txt");
						}
						stringPath = [NSString stringWithCString:targetPath];
						extension = [[NSString stringWithCString:ext] lowercaseString];
						if ([mimeTypeDictionary objectForKey:extension]) { /* Let's try to guess the content-type */
							contentType = [mimeTypeDictionary objectForKey:extension];
						} else if (item->mimetype) {
							contentType = [NSString stringWithCString:item->mimetype];
						} else {
							contentType = [NSString stringWithString:@"application/octet-stream"];
						}
						aRep = [[ISOPostingContentRep alloc] initLazyWithContentType:contentType extension:extension forPath:stringPath];
						[attachments addObject:aRep];
						free(ext);
					} else {
						returnvalue = INP_DecodeError;
					}
					itemNo++;
					free(targetPath);
				}
			}
		}
		free(aPath);
		UUCleanUp();
		if ([attachments count] == 0) {
			[attachments release];
			attachments = nil;
		}
	}
	return returnvalue;
}

- (ISOPostingContentRep *)attachmentWithMajorMimeType:(NSString *)aType andIndex:(int)index
{
	int 					i, count;
	int						otherCount;
	ISOPostingContentRep	*aRep;
	NSRange					aRange;
	
	count = [attachments count];
	if ((index >= 0) && (index < [self _countForMajorMimeType:aType])) {
		otherCount = -1;
		for (i=0;i<count;i++) {
			aRep = [attachments objectAtIndex:i];
			aRange = [[aRep contentType] rangeOfString:aType options:NSCaseInsensitiveSearch];
			if (aRange.length == [aType length]) {
				otherCount++;
				if (otherCount == index) {
					return aRep;
				}
			}
		}
	}
	return nil;
}

- (ISOPostingContentRep *)pictureWithIndex:(int)index
{
	return [self attachmentWithMajorMimeType:@"image/" andIndex:index];
}

- (ISOPostingContentRep *)videoWithIndex:(int)index
{
	return [self attachmentWithMajorMimeType:@"video/" andIndex:index];
}

- (ISOPostingContentRep *)soundWithIndex:(int)index
{
	return [self attachmentWithMajorMimeType:@"audio/" andIndex:index];
}

- (ISOPostingContentRep *)attachmentWithIndex:(int)index
{
	if ((index >= 0) && (index < [attachments count])) {
		return [attachments objectAtIndex:index];
	} else {
		return nil;
	}
}


- (NSArray *)allContentDecoded
{
	return attachments;
}

- (int)_countForMajorMimeType:(NSString *)aType
{
	int 					i, count;
	int						otherCount;
	ISOPostingContentRep	*aRep;
	NSRange					aRange;
	
	count = [attachments count];
	otherCount = 0;
	for (i=0;i<count;i++) {
		aRep = [attachments objectAtIndex:i];
		aRange = [[aRep contentType] rangeOfString:aType options:NSCaseInsensitiveSearch];
		if (aRange.length == [aType length]) {
			otherCount++;
		}
	}
	return otherCount;
}

- (int)pictureCount
{
	return [self _countForMajorMimeType:@"image/"];
}

- (int)videoCount
{
	return [self _countForMajorMimeType:@"video/"];
}

- (int)musicCount
{
	return [self _countForMajorMimeType:@"audio/"];
}

- (int)attachmentCount
{
	if (attachments) {
		return [attachments count];
	} else {
		return 0;
	}
}

- (NSString *)_getNumberOfCrosspostedGroups
{
	NSString	*xRefHeader = [theHeader headerForKey:@"Xref:"];
	int			count = 0;

	if (xRefHeader) {
		NSScanner	*scanner = [NSScanner scannerWithString:xRefHeader];
		while (![scanner isAtEnd] && [scanner scanUpToString:@":" intoString:nil]) {
			count++;
			[scanner scanString:@":" intoString:nil];
		}
	}
	return [NSString stringWithFormat:@"%d", count];
}

- (BOOL)_checkSpecialFiltersWithOp:(int)operator value:(NSString *)value header:(NSString *)header headerType:(int)headerType
{
	NSString	*valueToCompare;
	NSString	*headerToCompare;
	BOOL		matches = NO;
	
	switch (headerType) {
		case K_SPAMDATEMENU:
			valueToCompare = ISOCreateComparableDateFromDateHeader(value);
			headerToCompare = [theHeader comparableDate];
			break;
		case K_SPAMNEWSGROUPSCOUNTMENU:
			valueToCompare = value;
			headerToCompare = [self _getNumberOfCrosspostedGroups];
			break;
		case K_SPAMSIZEMENU:
			valueToCompare = value;
			if ([self bytesHeader]) {
				headerToCompare = [self bytesHeader];
			} else {
				headerToCompare = [NSString stringWithFormat:@"%d", [[self linesHeader] intValue] * 60];
			}
			break;
		default:
			headerToCompare = header;
			valueToCompare = value;
			break;
	}
	switch (operator) {
		case K_SPAMISOPERATOR:
			if ([headerToCompare caseInsensitiveCompare:valueToCompare] == NSOrderedSame) {
				matches = YES;
			}
			break;
		case K_SPAMISNOTOPERATOR:
			if ([headerToCompare caseInsensitiveCompare:valueToCompare] != NSOrderedSame) {
				matches = YES;
			}
			break;
		case K_SPAMISGREATERTHANOPERATOR:
			matches = ([headerToCompare intValue] > [valueToCompare intValue]);
			break;
		case K_SPAMISLOWERTHANOPERATOR:
			matches = ([headerToCompare intValue] < [valueToCompare intValue]);
			break;
		default:
			matches = NO;
			break;
	}
	return matches;
}

- (BOOL)wouldItExistAfterApplyingFilters:(NSArray *)filterArray
{
	NSArray		*s_spamFilterHeaders = [NSArray arrayWithObjects:
				@"From:",
				@"Subject:",
				@"Newsgroups:",
				@"Date:",
				@"Xref:",
				@"Bytes:",
				@"References:",
				@"Message-ID:",
				nil];
	int 		i, count;
	BOOL		retvalue = YES;
	
	if (filterArray) {
		count = [filterArray count];
		i=0;
		[self setWantsToBeDownloaded:NO];
		while (i<count && retvalue) {
			NSDictionary	*oneFilter;
			NSString		*header;
			NSNumber		*what;
			NSNumber		*operator;
			NSString		*value;
			NSNumber		*action;
			BOOL			matches;
			NSRange			aRange;
			int				headerType;
			
			oneFilter = [filterArray objectAtIndex:i];
			what = [oneFilter objectForKey:@"SPAMFILTERWHAT"];
			operator = [oneFilter objectForKey:@"SPAMFILTEROPERATOR"];
			value = [oneFilter objectForKey:@"SPAMFILTERVALUE"];
			action = [oneFilter objectForKey:@"SPAMFILTERACTION"];
			headerType = [what intValue];
			if (!action) {
				action = [NSNumber numberWithInt:K_SPAMIGNOREACTION];
			}
			header = [theHeader headerForKey:[s_spamFilterHeaders objectAtIndex:headerType]];
			matches = NO;
			if (header) {
				switch ([operator intValue]) {
					case K_SPAMCONTAINSOPERATOR:
						if (([what intValue] == K_SPAMREFERENCESMENU) || ([what intValue] == K_SPAMMESSAGEIDMENU)) {
							NSArray	*anArray = [value componentsSeparatedByString:@" "];
							int i, count;
							i = 0;
							count = [anArray count];
							while (i<count && !matches) {
								NSString	*arrValue = [anArray objectAtIndex:i];
								aRange = [header rangeOfString:arrValue options:NSCaseInsensitiveSearch];
								if (aRange.length == [arrValue length]) {
									matches = YES;
								}
								i++;
							}
						} else {
							[ISOActiveLogger logWithDebuglevel:10 :@"header: [%@] CONTAINS? [%@]", header, value];
							aRange = [header rangeOfString:value options:NSCaseInsensitiveSearch];
							if (aRange.length == [value length]) {
								matches = YES;
							}
						}
						break;
					case K_SPAMDOESNOTCONTAINOPERATOR:
						aRange = [header rangeOfString:value options:NSCaseInsensitiveSearch];
						if (aRange.length != [value length]) {
							matches = YES;
						}
						break;
					case K_SPAMISOPERATOR:
					case K_SPAMISNOTOPERATOR:
					case K_SPAMISGREATERTHANOPERATOR:
					case K_SPAMISLOWERTHANOPERATOR:
						matches = [self _checkSpecialFiltersWithOp:[operator intValue] value:value header:header headerType:headerType];
						break;
					case K_SPAMREGEXMATCHES:
					case K_SPAMREGEXDOESNOTMATCH:
						{
							regex_t	preg;
							int		ret = 0;
							
							if (regcomp(&preg, [value cString], REG_EXTENDED | REG_NOSUB) == 0) {
								ret = regexec(&preg, [header cString], 0, NULL, 0);
								regfree(&preg);
							}
							if ([operator intValue] == K_SPAMREGEXMATCHES) {
								matches = (ret == 0);
							} else {
								matches = (ret == REG_NOMATCH);
							}
						}
					default:
					break;
				}
				if (matches) {
					switch ([action intValue]) {
						case K_SPAMIGNOREACTION:
							retvalue = NO;
							break;
						case K_SPAMDOWNLOADACTION:
							retvalue = YES;
							[self setWantsToBeDownloaded:YES];
							break;
						case K_SPAMMARKREADACTION:
							[self setIsRead:YES];
							retvalue = YES;
							break;
						case K_SPAMFLAGACTION:
							[self setIsFlagged:YES];
							retvalue = YES;
							break;
						case K_MARKFORDOWNLOAD:
							[[ISOOfflineMgr sharedOfflineMgr] addToDownloads:self];
							retvalue = YES;
							break;
						default:
							break;
					}
				}
			}
			i++;
		}
	}
	return retvalue;
}

- (id)cleanUp
{
	NSMutableString *aPath;
	NSString *tmp = @"/tmp";
	
	if ([self postingPath]) {
		aPath = [NSMutableString stringWithString:[self postingPath]];
		if (![[NSFileManager defaultManager] removeFileAtPath:aPath handler:nil]) {
			[[NSFileManager defaultManager] movePath:aPath toPath:tmp handler:nil];
		}
		[aPath appendString:@".att"];
		[[NSFileManager defaultManager] removeFileAtPath:aPath handler:nil];
	}
	return self;
}

- (id)deepCleanUp
{
	int i, count;
	
	count = [subPostings count];
	for (i=0;i<count;i++) {
		[[subPostings objectAtIndex:i] deepCleanUp];
	}
	[self cleanUp];
	return self;
}

- (NSArray *)subPostingsFlat
{
	NSMutableArray	*anArray = [NSMutableArray array];
	int				i, count;
	
	count = [subPostings count];
	for (i=0;i<count;i++) {
		[anArray addObject:[subPostings objectAtIndex:i]];
		[anArray addObjectsFromArray:[[subPostings objectAtIndex:i] subPostingsFlat]];
	}
	if ([anArray count]) {
		return anArray;
	} else {
		return nil;
	}
}

- (id)addSubPosting:(id)aPosting
{
	if (aPosting && subPostings) {
		[subPostings addObject:aPosting];
		[aPosting addParent:self];
	}
	return self;
}

- (id)removeSubPosting:(id)aPosting
{
	[subPostings removeObject:aPosting];
	[aPosting removeParent:self];
	return self;
}

- (BOOL)hasSubPostings
{
	return ([subPostings count] > 0);
}

- (int)subPostingCount
{
	return [subPostings count];
}

- (int)subPostingsCountFlat
{
	int i, count;
	int	totalCount = 0;
	
	count = [subPostings count];
	for (i=0;i<count;i++) {
		totalCount += [[subPostings objectAtIndex:i] subPostingsCountFlat];
	}
	totalCount += count;
	return totalCount;
}

- (int)unreadSubpostingsCountFlat
{
	int i, count;
	int	totalCount = 0;
	
	count = [subPostings count];
	for (i=0;i<count;i++) {
		ISONewsPosting	*aPosting = [subPostings objectAtIndex:i];
		if (![aPosting isRead]) {
			totalCount++;
		}
		totalCount += [aPosting unreadSubpostingsCountFlat];
	}
	return totalCount;
}

- (NSArray	*)references
{
	if ([self referencesHeader]) {
		NSMutableArray	*anArray = [NSMutableArray arrayWithArray:[[self referencesHeader] componentsSeparatedByString:@"<"]];
		int		i, count = [anArray count];
		for (i=count-1;i>=0;i--) {
			NSString *oneString = [anArray objectAtIndex:i];
			if ([oneString length] >2) {
				NSString	*newString;
				while ([oneString length] && ([oneString hasSuffix:@" "] || [oneString hasSuffix:@"\t"])) {
					oneString = [oneString substringToIndex:[oneString length]-1];
				}
				if ([oneString length] && [oneString compare:@" "] != NSOrderedSame) {
					newString = [NSString stringWithFormat:@"<%@", oneString];
					[anArray replaceObjectAtIndex:i withObject:newString];
				}
			} else {
				[anArray removeObjectAtIndex:i];
			}
		}
		return anArray;
	} else {
		return nil;
	}
}

- (NSString *)transferableHeader
{
	return [theHeader transferableHeader];
}

- (NSString *)bytesHeader
{
	return [theHeader bytesHeader];
}

- (id)postingAtIndex:(int)index
{
	if ((index >= 0) && (index < [subPostings count])) {
		return [subPostings objectAtIndex:index];
	} else {
		return nil;
	}
}

- (NSArray *)postingPathsFlatIfBodyLoaded
{
    NSMutableArray	*anArray = [NSMutableArray arrayWithCapacity:[subPostings count]+1];
    int 			i, count;
    ISONewsPosting	*aPosting;

	count = [subPostings count];
	for (i=0;i<count;i++) {
		aPosting = [subPostings objectAtIndex:i];
		[anArray addObjectsFromArray:[aPosting postingPathsFlatIfBodyLoaded]];
	}
	if ([self isBodyLoaded]) {
		[anArray addObject:[self postingPath]];
	}
	return anArray;
}

- (NSString *)decodedSubject
{
	NSMutableString	*decodedString = [NSMutableString string];
	NSMutableString	*characterSet = [NSMutableString string];
	CFStringEncoding cEncoding;
	
	if (!decodedSubject) {
		decodedSubjectHasOwnEncoding = NO;
		if ([self _decodedHeaderStringFromString:[self subjectHeader] into:decodedString putCharacterSetInto:characterSet]) {
			cEncoding = [[cfstringEncodings objectForKey:[characterSet uppercaseString]] intValue];
			[self setDecodedSubject:[decodedString unicodeStringWithCFStringEncoding:cEncoding]];
			decodedSubjectHasOwnEncoding = YES;
		} else if (displayEncoding != MAC_ISOUNKNOWNENCODINGINT) {
			[self setDecodedSubject:[[self subjectHeader] unicodeStringWithCFStringEncoding:displayEncoding]];
		} else {
			cEncoding = [[ISOPreferences sharedInstance] prefsDefaultPostingEncoding];
			if (cEncoding == MAC_ISOUNKNOWNENCODINGINT) {
				cEncoding = [[cfstringEncodings objectForKey:@"US-ASCII"] intValue];
			}
			[self setDecodedSubject:[[self subjectHeader] unicodeStringWithCFStringEncoding:cEncoding]];
		}
	}
	return decodedSubject;
}

- (id)setDecodedSubject:(NSString *)dSubject
{
	if (decodedSubject) {
		[decodedSubject release];
		decodedSubject = nil;
	}
	if (dSubject) {
		decodedSubject = [NSString stringWithString:dSubject];
		[decodedSubject retain];
	}
	return self;
}
	
- (NSString *)decodedSender
{
	NSMutableString	*decodedString = [NSMutableString string];
	NSMutableString	*characterSet = [NSMutableString string];
	CFStringEncoding cEncoding;
	
	if (!decodedSender) {
		decodedSenderHasOwnEncoding = NO;
		if ([self _decodedHeaderStringFromString:[self fromHeader] into:decodedString putCharacterSetInto:characterSet]) {
			cEncoding = [[cfstringEncodings objectForKey:[characterSet uppercaseString]] intValue];
			[self setDecodedSender:[decodedString unicodeStringWithCFStringEncoding:cEncoding]];
			decodedSenderHasOwnEncoding = YES;
		} else if (displayEncoding != MAC_ISOUNKNOWNENCODINGINT) {
			[self setDecodedSender:[[self fromHeader] unicodeStringWithCFStringEncoding:displayEncoding]];
		} else {
			cEncoding = [[ISOPreferences sharedInstance] prefsDefaultPostingEncoding];
			if (cEncoding == MAC_ISOUNKNOWNENCODINGINT) {
				cEncoding = [[cfstringEncodings objectForKey:@"US-ASCII"] intValue];
			}
			[self setDecodedSender:[[self fromHeader] unicodeStringWithCFStringEncoding:cEncoding]];
		}
	}
	return decodedSender;
}

- (id)setDecodedSender:(NSString *)dSender
{
	if (decodedSender) {
		[decodedSender release];
		decodedSender = nil;
	}
	if (dSender) {
		decodedSender = [NSString stringWithString:dSender];
		[decodedSender retain];
	}
	return self;
}


- (BOOL)_decodedHeaderStringFromString:(NSString *)encodedString into:(NSMutableString *)decodedString putCharacterSetInto:(NSMutableString *)charSet
{
	NSString		*workString = [NSString stringWithString:encodedString];
	NSString		*characterSet = nil;
	NSString		*encoding = nil;
	NSString		*encodedText = nil;
	NSScanner		*headerScanner;
	BOOL			decoded = NO;
	NSRange			aRange;
	
	// gh.nospam@gmx.de (=?ISO-8859-1?Q?Gerhard_H=F6lscher?=)
	/* Re: Petition gegen $100 =?ISO-8859-1?Q?Geb=FChr?==?ISO-8859-1?Q?_f=FCr?= .mac Service
	=?
	ISO...
	?
	Q|B
	?
	STRING
	?=
	=?
	ISO...
	?
	Q|B
	?
	STRING
	?=
	*/

	[decodedString setString:@""];
	aRange = [workString rangeOfString:K_QPBEGIN_STRING];
	if ((aRange.location != NSNotFound) && (aRange.location != 0)) {
		[decodedString appendString:[workString substringToIndex:aRange.location]];
	}
	while (aRange.location != NSNotFound) {
		int	scannerPosition;
		workString = [workString substringFromIndex:aRange.location + aRange.length];
		headerScanner = [NSScanner scannerWithString:workString];
		if ([headerScanner scanUpToString:@"?" intoString:&characterSet] &&
			[headerScanner scanString:@"?" intoString:nil] &&
			[headerScanner scanUpToString:@"?" intoString:&encoding] &&
			[headerScanner scanString:@"?" intoString:nil] &&
			[headerScanner scanUpToString:K_QPEND_STRING intoString:&encodedText]) {
			[headerScanner scanString:K_QPEND_STRING intoString:nil];
			scannerPosition = [headerScanner scanLocation];
			if (scannerPosition < [workString length]) {
				workString = [workString substringFromIndex:scannerPosition];
			} else {
				workString = [NSString string];
			}
			[charSet setString:characterSet];
			if ([encoding caseInsensitiveCompare:@"Q"] == NSOrderedSame) {	
				char	*srcBuf;
				char	*destBuf;
				int		len;
				
				len = [encodedText length];
				srcBuf = malloc(len+1);
				memset(srcBuf, 0, len+1);
				destBuf = malloc((len*4)+1);
				memset(destBuf, 0, (len*4)+1);
				strcpy(srcBuf, [encodedText cString]);
				if (ISO_UUDecodeQP(srcBuf, destBuf, NULL, 0, 0, 0, NULL) == UURET_OK) {
					[decodedString appendString:[NSString stringWithCString:destBuf]];
					decoded = YES;
				} else {
					[decodedString appendString:encodedString];
					decoded = NO;
				}
			} else if ([encoding caseInsensitiveCompare:@"B"] == NSOrderedSame) {
				FILE	*srcfp;
				FILE	*dstfp;
				char	*destBuf;
				int		len;
				
				srcfp = fopen("/private/tmp/.halime.hdr.jp.b64", "w+");
				if (srcfp) {
					fprintf(srcfp, "%s\n", [encodedText cString]);
					/* *******************************************************************************
					* The following is a weird work-around for UUDeview:
					* UUDeview doesn't support TINY Base64, i.e. base64 less than 3 lines. 
					* But in my case, I have usually only one line, so I have to add an additional
					* 3 1/2 lines to get UUDeview to decode the text.
					* The following encoding contains: "THIS IS JUST A TEXT AS FILLER FOR UUDEVIEW" 
					* multiple times.
					* I hope, Frank can fix this bug some time in near future...
					********************************************************************************* */
					fprintf(srcfp, "VEhJUyBJUyBKVVNUIEEgVEVYVCBBUyBGSUxMRVIgRk9SIFVVREVWSUVXIApUSElTIElTIEpVU1Qg\n");
					fprintf(srcfp, "QSBURVhUIEFTIEZJTExFUiBGT1IgVVVERVZJRVcgClRISVMgSVMgSlVTVCBBIFRFWFQgQVMgRklM\n");
					fprintf(srcfp, "TEVSIEZPUiBVVURFVklFVyAKVEhJUyBJUyBKVVNUIEEgVEVYVCBBUyBGSUxMRVIgRk9SIFVVREVW\n");
					fprintf(srcfp, "VVVERVZJRVcgClRISVMgSVMgSlVTVCBBIFRFWFQgQVMgRklMTEVSIEZPUiBVVURFVklFVyAK\n");
					fclose(srcfp);
					UUInitialize();
					UUSetOption(UUOPT_TINYB64, 1, NULL);
					UUSetOption(UUOPT_FAST, 1, NULL);
					if (UULoadFile("/private/tmp/.halime.hdr.jp.b64", NULL, 0) == UURET_OK) {
						uulist *anItem;
						
						anItem = UUGetFileListItem(0);
						if (UUDecodeToTemp(anItem) == UURET_OK) {
							anItem = UUGetFileListItem(0);
							dstfp = fopen(anItem->binfile, "r");
							fseek(dstfp, 0, SEEK_END);
							len = ftell(dstfp);
							destBuf = malloc(len+1);
							memset(destBuf, 0, len+1);
							fseek(dstfp, 0, SEEK_SET);
							fread(destBuf, len, 1, dstfp);
							if (strstr(destBuf, "THIS IS JUST A TEXT AS FILLER FOR UUDEVIEW") != NULL) {
								strstr(destBuf, "THIS IS JUST A TEXT AS FILLER FOR UUDEVIEW")[0] = '\0';
							}
							[decodedString appendString:[NSString stringWithCString:destBuf]];
							decoded = YES;
						} else {
							[decodedString appendString:encodedString];
							decoded = NO;
						}
					} else {
						[decodedString appendString:encodedString];
						decoded = NO;
					}
					UUCleanUp();
				} else {
					[decodedString appendString:encodedString];
					decoded = NO;
				}
			} else {
				[decodedString appendString:encodedString];
				decoded = NO;
			}
		}
		aRange = [workString rangeOfString:K_QPBEGIN_STRING];
	}
	if ([workString length]) {
		[decodedString appendString:workString];
	}
	return decoded;
}

- (NSFont *)getArticleBodyEncodingFont
{
	return [[ISOPreferences sharedInstance] articleBodyFontForEncoding:[self contentEncoding]];
}

- (NSStringEncoding )contentEncoding
{
	NSString 			*encoding = [[self characterEncoding] uppercaseString];
	NSStringEncoding	theEncoding;

	theEncoding = displayEncoding;
	if (theEncoding == MAC_ISOUNKNOWNENCODINGINT) {
		if ([encoding length] && (CFStringConvertIANACharSetNameToEncoding((CFStringRef )encoding)!=kCFStringEncodingInvalidId)) {
			theEncoding = CFStringConvertIANACharSetNameToEncoding((CFStringRef )encoding);
		} else {
			theEncoding = [[ISOPreferences sharedInstance] prefsDefaultPostingEncoding];
		}
	}
	return theEncoding;
}

- (NSString *)decodedBody
{
	return [[self bodyAsText] unicodeStringWithCFStringEncoding:[self contentEncoding]];
}


- (BOOL)isAFollowUp
{
	if (!isAFUSet) {
		[self setIsAFollowUp:[[ISOSentPostingsMgr sharedInstance] isPostingAReplyToMyPostings:self]];
	}
	return isAFollowUp;
}

- (BOOL)isAFUSet
{
	return isAFUSet;
}

- (id)setIsAFollowUp:(BOOL)flag
{
	isAFUSet = YES;
	isAFollowUp = flag;
	return self;
}

- (id)addParent:(id)aParent
{
	[parents addObject:aParent];
	[self clearGeneration];
	return self;
}

- (id)highestParent
{
	if ([parents count] == 0) {
		return self;
	} else {
		return [[parents objectAtIndex:0] highestParent];
	}
}

- (id)removeParent:(id)aParent
{
	[parents removeObject:aParent];
	return self;
}

- (void)removeAllParents
{
	[parents removeAllObjects];
}

- (id)firstUnreadPostingRelativeToPosting:(ISONewsPosting *)aPosting ignoringSelf:(BOOL)ignoringSelf
{
	if (!ignoringSelf && (aPosting != self) && (![self isRead])) {
		return self;
	} else {
		NSArray	*subpFlat = [self subPostingsFlat];
		int		count, i;
		int		startRow;
		if (aPosting && [subpFlat containsObject:aPosting]) {
			startRow = [subpFlat indexOfObject:aPosting] + 1;
		} else {
			startRow = 0;
		}
		count = [subpFlat count];
		for (i=startRow;i<count;i++) {
			if (![[subpFlat objectAtIndex:i] isRead] && (![[subpFlat objectAtIndex:i] isPostingInvalid])) {
				return [subpFlat objectAtIndex:i];
			}
		}
	}
	return nil;
}

- (id)firstUnreadPostingRelativeToPosting:(ISONewsPosting *)aPosting
{
	return [self firstUnreadPostingRelativeToPosting:aPosting ignoringSelf:NO];
}

- (id)setIsFlagged:(BOOL)flag
{
	[theHeader setIsFlagged:flag];
	return self;
}

- (BOOL)isFlagged
{
	return [theHeader isFlagged];
}

- (id)setIsOnHold:(BOOL)flag
{
	needsSaving = needsSaving || ([self isOnHold] != flag);
	[theHeader setIsOnHold:flag];
	return self;
}

- (BOOL)isOnHold
{
	return [theHeader isOnHold];
}

- (void)setIsOffline:(BOOL)flag
{
	isOffline = flag;
}

- (BOOL)isOffline
{
	return isOffline;
}

- setServerName:(NSString *)serverName
{
	needsSaving = YES;
	[theHeader setServerName:serverName];
	return self;
}

- (NSString *)serverName
{
	return [theHeader serverName];
}

- (void)setIsForwarded:(BOOL)flag
{
	needsSaving = needsSaving || ([self isForwarded] != flag);
	[theHeader setIsForwarded:flag];
}

- (void)setIsReplied:(BOOL)flag
{
	needsSaving = needsSaving || ([self isReplied] != flag);
	[theHeader setIsReplied:flag];
}

- (void)setIsFollowedUp:(BOOL)flag
{
	needsSaving = needsSaving || ([self isFollowedUp] != flag);
	[theHeader setIsFollowedUp:flag];
}

- (BOOL)isForwarded
{
	return [theHeader isForwarded];
}

- (BOOL)isReplied
{
	return [theHeader isReplied];
}

- (BOOL)isFollowedUp
{
	return [theHeader isFollowedUp];
}

- (void)removeAllSubPostings
{
	int i, count;
	
	count = [subPostings count];
	
	for (i=count-1; i>=0; i--) {
		ISONewsPosting	*subPosting = [subPostings objectAtIndex:i];
		
		[subPosting removeAllSubPostings];
		[subPosting removeParent:self];
//		[subPostings removeObject:subPosting];
	}
	[subPostings removeAllObjects];
}

- (void)setWantsToBeDownloaded:(BOOL)flag
{
	wantsToBeDownloaded = flag;
}

- (BOOL)isLoadable
{
	return isLoadable;
}

- (void)setIsLoadable:(BOOL)flag
{
	isLoadable = flag;
}

- (BOOL)wantsToBeDownloaded
{
	return wantsToBeDownloaded;
}

- (NSString *)comparableDate
{
	return [theHeader comparableDate];
}

- (void)_createXFaceImage
{
	if (!xFaceImage) {
		xFaceImage = ISOCreateXFaceImageFromString([theHeader xFaceHeader]);
		if (!xFaceImage) {
			xFaceImage = ISOCreateXFaceURLImageFromString([theHeader xFaceURLHeader]);
		}
	}
}

#define K_LEVELINDENT	15
#define K_GAP			5
- (void)drawInFrameRect:(NSRect )frameRect
{
	int			indentWidth;
	NSPoint		myPosition;
	NSPoint		myImagePosition;
	NSPoint		myLinePosition;
	NSString	*txtImageName = [NSString stringWithFormat:@"txt_%d", gtvImageSize];
	NSString	*rtfImageName = [NSString stringWithFormat:@"rtfd_%d", gtvImageSize];
	NSImage		*theImage;
	float		myWidth, myHeight;
	
	[self xFaceImage];
	if (xFaceImage) {
		theImage = xFaceImage;
		[theImage recache];
		[theImage setSize:NSMakeSize(gtvImageSize, gtvImageSize)];
	} else {
		theImage = [NSImage imageNamed:([self hasAttachments]==0)? txtImageName:rtfImageName];
	}
	indentWidth = K_LEVELINDENT;
	myWidth = [theImage size].width;
	myHeight = [theImage size].height;
	
	myPosition = frameRect.origin;
	myPosition.y += [theImage size].height/2;
	
	myLinePosition.x = myPosition.x;
	myLinePosition.y = myPosition.y;
	
	myImagePosition.x = myPosition.x;
	myImagePosition.y = myPosition.y + [theImage size].height/2;
	
	// First paint the image
	if ([self isBodyLoaded]) {
		[theImage compositeToPoint:myImagePosition operation:NSCompositeSourceOver];
	} else {
		[theImage dissolveToPoint:myImagePosition fraction:0.3];
	}
	
	if (![self isRead]) {
		NSImage	*unreadImage = [NSImage imageNamed:@"unread"];
		[unreadImage compositeToPoint:myImagePosition operation:NSCompositeSourceOver];
	}
	if ([self isFlagged]) {
		NSPoint flagPoint;
		NSImage	*flaggedImage = [NSImage imageNamed:@"flagged"];
		
		flagPoint.y = myImagePosition.y - [theImage size].height + [flaggedImage size].height;
		flagPoint.x = myImagePosition.x;
		[flaggedImage compositeToPoint:flagPoint operation:NSCompositeSourceOver];
	}
	if ([self isFollowedUp]) {
		NSPoint fupPosition = myImagePosition;
		NSImage	*followedUpImage = [NSImage imageNamed:@"followed_up"];
		
		fupPosition.x = myImagePosition.x + [theImage size].width - [followedUpImage size].width;
		[followedUpImage compositeToPoint:fupPosition operation:NSCompositeSourceOver];
	}
	if ([self isForwarded]) {
		NSPoint forwardedPosition = myImagePosition;
		NSImage	*forwardedImage = [NSImage imageNamed:@"forwarded"];
		
		forwardedPosition.y = myImagePosition.y - [theImage size].height + [forwardedImage size].height;
		forwardedPosition.x = myImagePosition.x + [theImage size].width - [forwardedImage size].width;
		[forwardedImage compositeToPoint:forwardedPosition operation:NSCompositeSourceOver];
	}
	if ([self isReplied]) {
		NSPoint repliedPosition = myImagePosition;
		NSImage	*repliedImage = [NSImage imageNamed:@"replied"];
		
		repliedPosition.y = myImagePosition.y - [theImage size].height + [repliedImage size].height;
		repliedPosition.x = myImagePosition.x + [theImage size].width - [repliedImage size].width;
		[repliedImage compositeToPoint:repliedPosition operation:NSCompositeSourceOver];
	}
	if (isSelected) {
/*		NSPoint selectedPosition = myImagePosition;
		NSImage	*selectedImage = [NSImage imageNamed:@"selected_posting"];
		
		selectedPosition.y = myImagePosition.y - [theImage size].height + [selectedImage size].height;
		selectedPosition.x = myImagePosition.x + [theImage size].width - [selectedImage size].width;
		[selectedImage compositeToPoint:selectedPosition operation:NSCompositeSourceOver];
*/
		[[NSColor redColor] set];
		NSFrameRectWithWidth(gtvFrameRect, 2.0);
	}
}


- (NSPoint)drawThreadAtPoint:(NSPoint)aPoint level:(int)level vertLevel:(int)vertLevel putLastXInto:(float *)lastX calculateOnly:(BOOL)calculateOnly inView:(id)aView shouldRect:(NSRect )inRect intersect:(BOOL)intersectFlag
{
	int			i, count;
	NSRect		lineRect;
	int			indentWidth;
	NSPoint		myPosition;
	NSPoint		oldSubPostingPosition;
	NSPoint		myImagePosition;
	NSPoint		myLinePosition;
	float		myLineWidth;
	NSPoint		positionAfterDrawing;		
	NSPoint		subPostingPosition;
	NSString	*txtImageName = [NSString stringWithFormat:@"txt_%d", gtvImageSize];
	NSString	*rtfImageName = [NSString stringWithFormat:@"rtfd_%d", gtvImageSize];
	NSImage		*theImage;
	float		myWidth, myHeight;
	int			highestX;
	NSRect		intersectRect;
	BOOL		doesIntersect;
	float		lastLineX, lastLineY;
	
	[self xFaceImage];
	if (xFaceImage) {
		theImage = xFaceImage;
		[theImage recache];
		[theImage setSize:NSMakeSize(gtvImageSize, gtvImageSize)];
	} else {
		theImage = [NSImage imageNamed:([self hasAttachments]==0)? txtImageName:rtfImageName];
	}
	indentWidth = K_LEVELINDENT;
	myWidth = [theImage size].width;
	myHeight = [theImage size].height;
	
	myPosition = aPoint;
	myLinePosition.x = myPosition.x;
	myLinePosition.y = myPosition.y;
	myLineWidth = K_LEVELINDENT;
	
	myImagePosition.x = myPosition.x;
	myImagePosition.y = myPosition.y + [theImage size].height/2;
	
	positionAfterDrawing.x = myPosition.x + myWidth;
	positionAfterDrawing.y = myPosition.y + myHeight;
	
	gtvFrameRect.origin = myImagePosition;
	gtvFrameRect.origin.y -= [theImage size].height;
	gtvFrameRect.size = [theImage size];
	intersectRect = NSIntersectionRect(inRect, gtvFrameRect);
	doesIntersect = ((intersectRect.size.width > 0.0) || (intersectRect.size.height > 0.0));
	// First paint the image
	if (!calculateOnly && (!intersectFlag || doesIntersect)) {
		[self drawInFrameRect:gtvFrameRect];
	}
	count = [subPostings count];
	
	subPostingPosition.x = myPosition.x + myWidth;
	subPostingPosition.y = myPosition.y + myHeight;
	
	oldSubPostingPosition = subPostingPosition;
	highestX = myPosition.x + myWidth;
	lastLineX = myPosition.x + (myWidth / 2);
	lastLineY = myPosition.y + (myHeight / 2);
	for (i=0;i<count;i++) {
		if ((lastLineY > oldSubPostingPosition.y + 5)) {
			lineRect.origin.x = lastLineX;
			lineRect.origin.y = oldSubPostingPosition.y;
			lineRect.size.width = 1;
			lineRect.size.height = lastLineY - oldSubPostingPosition.y;
			[[NSColor blackColor] set];
			NSFrameRect(lineRect);
		}
		oldSubPostingPosition = subPostingPosition;
		subPostingPosition = [[subPostings objectAtIndex:i] drawThreadAtPoint:subPostingPosition level:level+1 vertLevel:i putLastXInto:lastX calculateOnly:calculateOnly inView:aView shouldRect:inRect intersect:intersectFlag];
		if (highestX < *lastX) {
			highestX = *lastX;
		}
		subPostingPosition.x = myPosition.x + myWidth;

		lineRect.origin.x = lastLineX;
		lineRect.origin.y = lastLineY;
		lineRect.size.width = 1;
		lineRect.size.height = oldSubPostingPosition.y - lastLineY;
		[[NSColor blackColor] set];
		NSFrameRect(lineRect);

		lineRect.origin.x = lastLineX;
		lineRect.origin.y = lastLineY + (oldSubPostingPosition.y - lastLineY);
		lineRect.size.width = myWidth / 2;
		lineRect.size.height = 1;
		NSFrameRect(lineRect);

		lastLineY = subPostingPosition.y;
	}
	positionAfterDrawing.y = MAX(subPostingPosition.y, positionAfterDrawing.y);
	*lastX = highestX;
	if (calculateOnly) {
		NSRect aRect = gtvFrameRect;
		aRect.origin.y -= [theImage size].height/2;
		[aView addToolTipRect:aRect owner:self userData:nil];
	}
	return positionAfterDrawing;
}

- (ISONewsPosting *)hitTest:(NSPoint)aPoint
{
	int	i, count;
	if ((gtvFrameRect.origin.x <= aPoint.x) &&
		(gtvFrameRect.origin.y <= aPoint.y) &&
		((gtvFrameRect.origin.x + gtvFrameRect.size.width) >= aPoint.x) &&
		((gtvFrameRect.origin.y + gtvFrameRect.size.height) >= aPoint.y) ) {
			return self;
	} else {
		count = [subPostings count];
		for (i=0;i<count;i++) {
			ISONewsPosting *aP = [((ISONewsPosting *)[subPostings objectAtIndex:i]) hitTest:aPoint];
			if (aP) {
				return aP;
			}
		}
	}
	return nil;
}

- (void)drawIfIntersectsRect:(NSRect )aRect
{
	NSRect	intersectRect = NSIntersectionRect(aRect, gtvFrameRect);
	int	i, count;
	
	if ((intersectRect.size.width > 0.0) || (intersectRect.size.height > 0.0)) {
		[self redisplayWithOldFrame];
	}
	count = [subPostings count];
	for (i=0;i<count;i++) {
		[((ISONewsPosting *)[subPostings objectAtIndex:i]) drawIfIntersectsRect:aRect];
	}
}

- (NSRect )gtvFrameRect
{
	return gtvFrameRect;
}

- (void)setGTVImageSize:(int)aSize
{
	int	i, count;

	gtvImageSize = aSize;
	count = [subPostings count];
	for (i=0;i<count;i++) {
		[((ISONewsPosting *)[subPostings objectAtIndex:i]) setGTVImageSize:aSize];
	}
}

- (void)redisplayWithOldFrame
{
	[self drawInFrameRect:gtvFrameRect];
}

- (void)setIsSelected:(BOOL)flag
{
	isSelected = flag;
}

- (BOOL)isSelected
{
	return isSelected;
}

/* NSToolTipOwner Informal Protocol */
- (NSString *)someBody
{
	NSMutableString *str = [NSMutableString stringWithString:@"\n\n"];
	if ([self isBodyLoaded]) {
		NSArray	*anArray = [[self decodedBody] componentsSeparatedByString:@"\n"];
		int		i, count;
		int		charlength = 0;
		count = [anArray count];
		i=0;
		while (charlength < 256 && i<count) {
			NSString *aString = [anArray objectAtIndex:i];
			if (![aString hasPrefix:@">"] && 
				![aString hasPrefix:@"]"] && 
				![aString hasPrefix:@"|"] && 
				![aString hasPrefix:@"}"] ) {
					[str appendString:aString];
					charlength += [aString length];
			}
			i++;
		}
		return str;
	} else {
		[str setString:[NSString stringWithFormat:@"\n\n%@", NSLocalizedString(@"<The body of this posting is not yet loaded. Click on the posting to load it.>", @"")]];
	}
	return str;
}

- (NSString *)view:(NSView *)view stringForToolTip:(NSToolTipTag)tag point:(NSPoint)point userData:(void *)data
{
	NSString	*toolTip;
	if ([self linesHeader]) {
		toolTip = [NSString stringWithFormat:@"%@:\t%@\n%@:\t%@\n%@:\t%@%@",
								NSLocalizedString(@"From", @""),
								[self decodedSender],
								NSLocalizedString(@"Subject", @""),
								[self decodedSubject],
								NSLocalizedString(@"Lines", @""),
								[self linesHeader],
								(detailedTooltip)? [self someBody]:@""];
	} else {
		toolTip = [NSString stringWithFormat:@"%@:\t%@\n%@:\t%@%@",
								NSLocalizedString(@"From", @""),
								[self decodedSender],
								NSLocalizedString(@"Subject", @""),
								[self decodedSubject],
								(detailedTooltip)? [self someBody]:@""];
	}
	return toolTip;
}

- (void)setDetailedTooltip:(BOOL)flag
{
	int	i, count;

	detailedTooltip = flag;
	count = [subPostings count];
	for (i=0;i<count;i++) {
		[((ISONewsPosting *)[subPostings objectAtIndex:i]) setDetailedTooltip:detailedTooltip];
	}
}

- (void)setDisplayEncoding:(NSStringEncoding )anEncoding
{
	NSStringEncoding oldEncoding = displayEncoding;
	
	displayEncoding = anEncoding;
	if (displayEncoding != oldEncoding) {
		if (!decodedSenderHasOwnEncoding) {
			[self setDecodedSender:nil];
		}
		if (!decodedSubjectHasOwnEncoding) {
			[self setDecodedSubject:nil];
		}
	}
}

- (NSStringEncoding )displayEncoding
{
	return displayEncoding;
}

- (ISONewsHeader *)theHeader
{
	return theHeader;
}

- (void)setSavedToDisk:(BOOL)flag
{
	savedToDisk = flag;
}

- (void)setNeedsSaving:(BOOL)flag
{
	needsSaving = flag;
}

- (void)addAttachment:(ISOPostingContentRep *)anAttachment
{
	if (!attachments && (anAttachment != nil)) {
		attachments = [[NSMutableArray arrayWithCapacity:1] retain];
	}
	if (anAttachment) {
		[attachments addObject:anAttachment];
	}
}

/* Sorting in Threaded Mode */

- (BOOL)sortPostingsBySubjectAscending:(BOOL)flag
{
	id		oldPostings;
	BOOL	retval = NO;
	int		i, count;
	
	oldPostings = subPostings;
	subPostings = [[NSMutableArray arrayWithArray:[oldPostings sortedArrayUsingFunction:compareSubjects context:&flag]] retain];
	if (!subPostings) {
		subPostings = oldPostings;
		retval = NO;
	} else {
		[oldPostings release];
		retval = YES;
	}

	count = [subPostings count];
	for (i=0;i<count;i++) {
		ISONewsPosting *aPosting = [subPostings objectAtIndex:i];
		if (aPosting && [aPosting hasSubPostings]) {
			[aPosting sortPostingsBySubjectAscending:flag];
		}
	}
	return retval;
}

- (BOOL)sortPostingsBySenderAscending:(BOOL)flag
{
	id		oldPostings;
	BOOL	retval = NO;
	int		i, count;
	
	oldPostings = subPostings;
	subPostings = [[NSMutableArray arrayWithArray:[oldPostings sortedArrayUsingFunction:compareSender context:&flag]] retain];
	if (!subPostings) {
		subPostings = oldPostings;
		retval = NO;
	} else {
		[oldPostings release];
		retval = YES;
	}

	count = [subPostings count];
	for (i=0;i<count;i++) {
		ISONewsPosting *aPosting = [subPostings objectAtIndex:i];
		if ([aPosting hasSubPostings]) {
			[aPosting sortPostingsBySenderAscending:flag];
		}
	}
	return retval;
}

- (BOOL)sortPostingsByDateAscending:(BOOL)flag
{
	id		oldPostings;
	BOOL	retval = NO;
	int		i, count;
	
	oldPostings = subPostings;
	subPostings = [[NSMutableArray arrayWithArray:[oldPostings sortedArrayUsingFunction:compareDate context:&flag]] retain];
	if (!subPostings) {
		subPostings = oldPostings;
		retval = NO;
	} else {
		[oldPostings release];
		retval = YES;
	}
	
	count = [subPostings count];
	for (i=0;i<count;i++) {
		ISONewsPosting *aPosting = [subPostings objectAtIndex:i];
		if ([aPosting hasSubPostings]) {
			[aPosting sortPostingsByDateAscending:flag];
		}
	}
	return retval;
	
}

- (BOOL)sortPostingsBySizeAscending:(BOOL)flag
{
	id		oldPostings;
	BOOL	retval = NO;
	int		i, count;
	
	oldPostings = subPostings;
	subPostings = [[NSMutableArray arrayWithArray:[oldPostings sortedArrayUsingFunction:compareSize context:&flag]] retain];
	if (!subPostings) {
		subPostings = oldPostings;
		retval = NO;
	} else {
		[oldPostings release];
		retval = YES;
	}
	count = [subPostings count];
	for (i=0;i<count;i++) {
		ISONewsPosting *aPosting = [subPostings objectAtIndex:i];
		if ([aPosting hasSubPostings]) {
			[aPosting sortPostingsBySizeAscending:flag];
		}
	}
	return retval;
}

- (ISONewsPosting *)firstParent
{
	if ([parents count]) {
		return [parents objectAtIndex:0];
	} else {
		return nil;
	}
}

- (void)clearGeneration
{
	generation = 0;
}

- (int)generation
{
	if (generation == 0) {
		ISONewsPosting *aPosting = self;
		while (aPosting = [aPosting firstParent]) {
			generation++;
		}
	}
	return generation;
}

- (int)numberOfDescendants
{
	return [self subPostingsCountFlat];
}

- (int)threadPostingCount
{
	return [self numberOfDescendants] + 1; // + self :-)
}

- (BOOL)isSent
{
	return isSent;
}

- (void)setIsSent:(BOOL)flag
{
	isSent = flag;
}

- (NSImage *)xFaceImage
{
	if (!xFaceImage && ([theHeader xFaceHeader] || [theHeader xFaceURLHeader])) {
		[self _createXFaceImage];
	}
	return xFaceImage;
}

- (NSArray *)subPostings
{
	return subPostings;
}

- (BOOL)isLocked
{
	return [theHeader isLocked] || [self isInDownloadManager];
}

- (BOOL)isDeepLocked
{
	BOOL	isDeepLocked = NO;
	int i, count;

	isDeepLocked = [self isLocked] || [self isInDownloadManager];
	if (!isDeepLocked) {
		count = [subPostings count];
		i = 0;
		while (!isDeepLocked && i<count) {
			isDeepLocked = [[subPostings objectAtIndex:i] isDeepLocked];
			i++;
		}
	}
	return isDeepLocked;
}

- (void)setIsLocked:(BOOL)flag
{
	int i, count;
	
	needsSaving = needsSaving || ([self isLocked] != flag);
	[theHeader setIsLocked:flag];
	
	count = [subPostings count];
	for (i=0;i<count;i++) {
		[[subPostings objectAtIndex:i] setIsLocked:flag];
	}
}

- (void)setIsInDownloadManager:(BOOL)flag
{
	needsSaving = needsSaving || ([self isInDownloadManager] != flag);
	[theHeader setIsInDownloadManager:flag];
}

- (BOOL)isInDownloadManager
{
	return [theHeader isInDownloadManager];
}


- (BOOL)readFromOtherPosting:(id)anotherPosting
{
	if (anotherPosting) {
		NSMutableString *aString = [NSMutableString stringWithString:[anotherPosting headerAsRawText]];
		[aString appendString:@"\r\n\r\n"];
		[aString appendString:[anotherPosting bodyAsRawText]];
		[theHeader readFromString:aString];
		if (theBody) {
			[theBody release];
		}
		if (theHeader) { 
			theBody = [[ISONewsBody alloc] initFromString:aString];
			if (theBody) {
				hasAttachments = [theBody hasAttachments];
			}
			needsSaving = YES;
			return YES;
		}
	}
	return NO;
}

@end
