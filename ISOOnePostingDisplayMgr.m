//
//  ISOOnePostingDisplayMgr.m
//  Halime
//
//  Created by Imdat Solak on Sun Sep 15 2002.
//  Copyright (c) 2002 Imdat Solak. All rights reserved.
//

#import "ISOOnePostingDisplayMgr.h"
#import "ISOPreferences.h"
#import "ISOOfflineMgr.h"
#import "ISOBeep.h"
#import "ISOSubscriptionMgr.h"
#import "ISOSubscriptionWindowMgr.h"
#import "ISOResourceMgr.h"
#import "ISOViewOptionsMgr.h"
#import "ISODragImageView.h"
#import <uudeview.h>
#import "NSTextView_Extensions.h"

@implementation ISOOnePostingDisplayMgr
- init
{
	[super init];
	thePosting = nil;
	theSubscriptionMgr = nil;
	subscriptionWindowMgr = nil;
	return self;
}

- setOwner:(id)anObject
{
	subscriptionWindowMgr = anObject;
	return self;
}

- setSubscriptionMgr:(ISOSubscriptionMgr *)aMgr
{
	NSSize aSize;
	theSubscriptionMgr = aMgr;
	[picturesTable setDoubleAction:@selector(picturesDoubleClicked:)];
	[videosTable setDoubleAction:@selector(videosDoubleClicked:)];
	[musicTable setDoubleAction:@selector(musicDoubleClicked:)];
	[otherTable setDoubleAction:@selector(attachmentDoubleClicked:)];
	[pictureView setDoubleTarget:self];
	[pictureView setDoubleAction:@selector(picturesDoubleClicked:)];
	[textField setEditable:NO];
	[textField setSelectable:YES];
	aSize = [pictureScrollView contentSize];
	[pictureView setFrame:NSMakeRect(0,0,aSize.width, aSize.height)];
	return self;
}

- (void)dealloc
{
	[super dealloc];
}

- setPosting:(ISONewsPosting *)aPosting
{
	thePosting = aPosting;
	return self;
}

/* TABLE Methods */
- (int)numberOfRowsInTableView:(NSTableView *)aTableView
{
	if (!thePosting) {
		return 0;
	} else {
		if (aTableView == picturesTable) {
			return [thePosting pictureCount];
		} else if (aTableView == videosTable) {
			return [thePosting videoCount];
		} else if (aTableView == musicTable) {
			return [thePosting musicCount];
		} else if (aTableView == otherTable) {
			return [thePosting attachmentCount];
		} else {
			return 0;
		}
	}
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex
{
	if (aTableView == picturesTable) {
		return [self picturesTableValueForTableColumn:aTableColumn row:rowIndex];
    } else if (aTableView == videosTable) {
		return [self videosTableValueForTableColumn:aTableColumn row:rowIndex];
    } else if (aTableView == musicTable) {
		return [self musicTableValueForTableColumn:aTableColumn row:rowIndex];
    } else if (aTableView == otherTable) {
		return [self otherTableValueForTableColumn:aTableColumn row:rowIndex];
    } else {
        return 0;
    }
}

- (id)picturesTableValueForTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex
{
	if ((rowIndex >= 0) && thePosting) {
		ISOPostingContentRep *currentRep = [thePosting pictureWithIndex:rowIndex];
		if (currentRep) {
			if ([(NSString *)[aTableColumn identifier] compare:@"PICTURE_NAME"] == NSOrderedSame) {
				return [currentRep repName];
			} else if ([(NSString *)[aTableColumn identifier] compare:@"PICTURE_SIZE"] == NSOrderedSame) {
				return [NSNumber numberWithInt:[currentRep repSize]];
			}
		}
	}
	return nil;
}

- (id)videosTableValueForTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex
{
	if ((rowIndex >= 0) && thePosting) {
		ISOPostingContentRep *currentRep = [thePosting videoWithIndex:rowIndex];
		if (currentRep) {
			if ([(NSString *)[aTableColumn identifier] compare:@"VIDEO_NAME"] == NSOrderedSame) {
				return [currentRep repName];
			} else if ([(NSString *)[aTableColumn identifier] compare:@"VIDEO_SIZE"] == NSOrderedSame) {
				return [NSNumber numberWithInt:[currentRep repSize]];
			} else if ([(NSString *)[aTableColumn identifier] compare:@"VIDEO_TYPE"] == NSOrderedSame) {
				return [currentRep contentType];
			}
		}
	}
	return nil;
}

- (id)musicTableValueForTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex
{
	if ((rowIndex >= 0) && thePosting) {
		ISOPostingContentRep *currentRep = [thePosting soundWithIndex:rowIndex];
		if (currentRep) {
			if ([(NSString *)[aTableColumn identifier] compare:@"MUSIC_NAME"] == NSOrderedSame) {
				return [currentRep repName];
			} else if ([(NSString *)[aTableColumn identifier] compare:@"MUSIC_SIZE"] == NSOrderedSame) {
				return [NSNumber numberWithInt:[currentRep repSize]];
			} else if ([(NSString *)[aTableColumn identifier] compare:@"MUSIC_TYPE"] == NSOrderedSame) {
				return [currentRep contentType];
			}
		}
	}
	return nil;
}

- (id)otherTableValueForTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex
{
	if ((rowIndex >= 0) && thePosting) {
		ISOPostingContentRep *currentRep = [thePosting attachmentWithIndex:rowIndex];
		if (currentRep) {
			if ([(NSString *)[aTableColumn identifier] compare:@"OTHER_NAME"] == NSOrderedSame) {
				return [currentRep repName];
			} else if ([(NSString *)[aTableColumn identifier] compare:@"OTHER_SIZE"] == NSOrderedSame) {
				return [NSNumber numberWithInt:[currentRep repSize]];
			} else if ([(NSString *)[aTableColumn identifier] compare:@"OTHER_TYPE"] == NSOrderedSame) {
				return [currentRep contentType];
			}
		}
	}
	return nil;
}

- (void)tableViewSelectionDidChange:(NSNotification *)aNotification
{
	id	selectionTable = [aNotification object];
    if (selectionTable == picturesTable) {
		[self pictureSelected:selectionTable];
    } else if (selectionTable == videosTable) {
		[self videoSelected:selectionTable];
    } else if (selectionTable == musicTable) {
		[self musicSelected:selectionTable];
    } else if (selectionTable == otherTable) {
		[self otherSelected:selectionTable];
	}
}



/* ***************************************************************************************** */
- (void)_addFilteredHeadersFromPosting:(ISONewsPosting *)aPosting toString:(NSMutableAttributedString *)aString boldAttrib:(NSMutableDictionary *)bold unboldAttrib:(NSMutableDictionary *)unbold
{
	NSString			*tempStr;
    BOOL				showSender = [theSubscriptionMgr viewOptionValueForKey:VOM_PBFrom];
    BOOL				showSubject = [theSubscriptionMgr viewOptionValueForKey:VOM_PBSubject];
    BOOL				showDate = [theSubscriptionMgr viewOptionValueForKey:VOM_PBDate];
    BOOL				showGroups = [theSubscriptionMgr viewOptionValueForKey:VOM_PBNewgroups];
	BOOL				showReplyTo = [theSubscriptionMgr viewOptionValueForKey:VOM_PBReplyTo];
    BOOL				showOrganization = [theSubscriptionMgr viewOptionValueForKey:VOM_PBOrganization];
    BOOL				showFollowUp = [theSubscriptionMgr viewOptionValueForKey:VOM_PBFollowupTo];

	if (showSender && [aPosting fromHeader]) {
		[aString appendAttributedString:[[NSAttributedString alloc] initWithString:NSLocalizedString(@"From:", @"") attributes:bold]];
		tempStr = [NSString stringWithFormat:@" %@\n", [aPosting decodedSender]];
		[aString appendAttributedString:[[NSAttributedString alloc] initWithString:tempStr attributes:unbold]];
	}
	if (showGroups && [aPosting newsgroupsHeader]) {
		[aString appendAttributedString:[[NSAttributedString alloc] initWithString:NSLocalizedString(@"Newsgroups:", @"") attributes:bold]];
		tempStr = [NSString stringWithFormat:@" %@\n", [aPosting newsgroupsHeader]];
		[aString appendAttributedString:[[NSAttributedString alloc] initWithString:tempStr attributes:unbold]];
	}
	if (showSubject && [aPosting subjectHeader]) {
		[aString appendAttributedString:[[NSAttributedString alloc] initWithString:NSLocalizedString(@"Subject:", @"") attributes:bold]];
		tempStr = [NSString stringWithFormat:@" %@\n", [aPosting decodedSubject]];
		[aString appendAttributedString:[[NSAttributedString alloc] initWithString:tempStr attributes:unbold]];
	}
	if (showDate && [aPosting dateHeader]) {
		[aString appendAttributedString:[[NSAttributedString alloc] initWithString:NSLocalizedString(@"Date:", @"") attributes:bold]];

		tempStr = [NSString stringWithFormat:@" %@\n", [aPosting dateHeader]];
		[aString appendAttributedString:[[NSAttributedString alloc] initWithString:tempStr attributes:unbold]];
	}
	if (showOrganization && [aPosting organizationHeader]) {
		[aString appendAttributedString:[[NSAttributedString alloc] initWithString:NSLocalizedString(@"Organization:", @"") attributes:bold]];

		tempStr = [NSString stringWithFormat:@" %@\n", [aPosting organizationHeader]];
		[aString appendAttributedString:[[NSAttributedString alloc] initWithString:tempStr attributes:unbold]];
	}
	if (showFollowUp && [aPosting followUpHeader]) {
		[aString appendAttributedString:[[NSAttributedString alloc] initWithString:NSLocalizedString(@"Followup-To:", @"") attributes:bold]];

		tempStr = [NSString stringWithFormat:@" %@\n", [aPosting followUpHeader]];
		[aString appendAttributedString:[[NSAttributedString alloc] initWithString:tempStr attributes:unbold]];
	}
	if (showReplyTo && [aPosting replyToHeader]) {
		[aString appendAttributedString:[[NSAttributedString alloc] initWithString:NSLocalizedString(@"Reply-To:", @"") attributes:bold]];

		tempStr = [NSString stringWithFormat:@" %@\n", [aPosting replyToHeader]];
		[aString appendAttributedString:[[NSAttributedString alloc] initWithString:tempStr attributes:unbold]];
	}
}

- (void)_addAllHeadersFromPosting:(ISONewsPosting *)aPosting toString:(NSMutableAttributedString *)aString boldAttrib:(NSMutableDictionary *)bold unboldAttrib:(NSMutableDictionary *)unbold
{
	NSDictionary	*headers = [[aPosting theHeader] fullHeader];
	NSEnumerator	*enumerator = [headers keyEnumerator];
	NSString 		*key;
	NSString		*tempStr;
	
	while ((key = (NSString *)[enumerator nextObject])) {
		if (![key hasPrefix:@"X-Halime"]) {
			NSString *oneHeader;
			if ([key compare:@"From:"] == NSOrderedSame) {
				oneHeader = [aPosting decodedSender];
			} else if ([key compare:@"Subject:"] == NSOrderedSame) {
				oneHeader = [aPosting decodedSubject];
			} else {
				oneHeader = [headers objectForKey:key];
			}
			if (oneHeader && [oneHeader length]) {
				[aString appendAttributedString:[[NSAttributedString alloc] initWithString:NSLocalizedString(key, @"") attributes:bold]];
				tempStr = [NSString stringWithFormat:@" %@\n",  oneHeader];
				[aString appendAttributedString:[[NSAttributedString alloc] initWithString:tempStr attributes:unbold]];
			}
		}
	}
}

- (NSMutableAttributedString *)viewableBody:(ISONewsPosting *)aPosting
{
    NSMutableAttributedString 	*aString;
	NSMutableDictionary			*bold = [NSMutableDictionary dictionaryWithCapacity:2];
	NSMutableDictionary			*unbold = [NSMutableDictionary dictionaryWithCapacity:2];
    NSFont						*newFont;
	NSRange						aRange;
    NSImage						*separatorImage;
    NSTextAttachment			*attachment;
    NSCell    					*cell;
    NSAttributedString			*attachmentString;	
	NSImage						*xFaceImage = [aPosting xFaceImage];
	
    aString = [[NSMutableAttributedString alloc] init];
	[bold setObject:[[ISOPreferences sharedInstance] prefsHeadersColor] forKey:NSForegroundColorAttributeName];
	[unbold setObject:[[ISOPreferences sharedInstance] prefsHeadersColor] forKey:NSForegroundColorAttributeName];

	newFont = [aPosting getArticleBodyEncodingFont];
	newFont = [[NSFontManager sharedFontManager] convertFont:newFont toHaveTrait:NSBoldFontMask];
	[bold setObject:newFont forKey:NSFontAttributeName];
	
	newFont = [[NSFontManager sharedFontManager] convertFont:newFont toNotHaveTrait:NSBoldFontMask];
	[unbold setObject:newFont forKey:NSFontAttributeName];
	
	if ([[theSubscriptionMgr theSubscription] shouldShowFullHeaders]) {
		[self _addAllHeadersFromPosting:aPosting toString:aString boldAttrib:bold unboldAttrib:unbold];
	} else {
		[self _addFilteredHeadersFromPosting:aPosting toString:aString boldAttrib:bold unboldAttrib:unbold];
	}
	[unbold setObject:[NSColor blackColor] forKey:NSForegroundColorAttributeName];

    [aString appendAttributedString:[[NSAttributedString alloc] initWithString:@"\n" attributes:unbold]];
    [aString appendAttributedString:[[NSAttributedString alloc] initWithString:[aPosting decodedBody] attributes:unbold]];
	aRange.location = 0;
	aRange.length = [aString length];
	[aString fixFontAttributeInRange:aRange];

	// XFace-Support
	if (xFaceImage) {
		separatorImage = [NSImage imageNamed:@"separator"];
		attachment = [[[NSTextAttachment alloc] init] autorelease];
		cell = [attachment attachmentCell];
		[cell setImage:separatorImage];
	
		attachmentString = [NSMutableAttributedString attributedStringWithAttachment:attachment];
		[aString appendAttributedString:attachmentString];
		[aString appendAttributedString:[[NSAttributedString alloc] initWithString:@"\n" attributes:unbold]];
	
		attachment = [[[NSTextAttachment alloc] init] autorelease];
		cell = [attachment attachmentCell];
		[xFaceImage recache];
		[xFaceImage setSize:NSMakeSize(48, 48)];
		[cell setImage:xFaceImage];
	
		attachmentString = [NSMutableAttributedString attributedStringWithAttachment:attachment];
		[aString appendAttributedString:attachmentString];
	}

    return aString;
}

/* Selecting, saving, etc. */
/* This is for SELECTING ONE item in the appropriate list */
- (ISOPostingContentRep *)_getSelectedAttachmentWithMajorMimeType:(NSString *)majMime andIndex:(int)rowIndex
{
	ISOPostingContentRep	*postingContentRep;

	if (rowIndex < [thePosting attachmentCount]) {
		if (!majMime) {
			postingContentRep = [thePosting attachmentWithIndex:rowIndex];
		} else {
			postingContentRep = [thePosting attachmentWithMajorMimeType:majMime andIndex:rowIndex];
		}
		return postingContentRep;
	}
	return nil;
}

- (ISOPostingContentRep *)_getSelectedPicture
{
	int rowIndex = [picturesTable selectedRow];
	return [self _getSelectedAttachmentWithMajorMimeType:@"image/" andIndex:rowIndex];
}


- (void)pictureSelected:sender
{
	ISOPostingContentRep	*postingContentRep;
	NSImage					*theImage;
	
	[pictureView setImage:nil];
	[savePictureButton setEnabled:NO];
	postingContentRep = [self _getSelectedPicture];
	if (postingContentRep) {
		theImage = [[NSImage alloc] initWithData:[postingContentRep data]];
		if (theImage) {
			[theImage setScalesWhenResized:YES];
			if ([scaleImageToFitSwitch state] == 1) {
				NSSize aSize = [pictureScrollView contentSize];
				NSSize bSize = [theImage size];
				float			scaleFactor;
				[pictureView setFrame:NSMakeRect(0,0,aSize.width, aSize.height)];
				scaleFactor = MIN(aSize.width / bSize.width, aSize.height / bSize.height);
				bSize.width *= scaleFactor;
				bSize.height *= scaleFactor;
				[theImage setSize:bSize];
			} else {
				NSSize aSize = [theImage size];
				[pictureView setFrame:NSMakeRect(0,0,aSize.width, aSize.height)];
			}
			[pictureView setImageScaling:[scaleImageToFitSwitch state]? NSScaleProportionally:NSScaleNone];
			[pictureView setImage:theImage];
			[pictureView setImageFilename:[postingContentRep path]];
			[theImage autorelease];
			[savePictureButton setEnabled:YES];
		}
	}
}

- (ISOPostingContentRep *)_getSelectedMovie
{
	int rowIndex = [videosTable selectedRow];
	return [self _getSelectedAttachmentWithMajorMimeType:@"video/" andIndex:rowIndex];
}


- (void)videoSelected:sender
{
	ISOPostingContentRep	*postingContentRep;
	NSMovie					*theMovie;
	
	[saveMusicButton setEnabled:NO];
	[videoView setMovie:nil];
	postingContentRep = [self _getSelectedMovie];
	if (postingContentRep && [postingContentRep path] && [[postingContentRep path] length]) {
		NSURL	*theURL = [NSURL fileURLWithPath:[postingContentRep path]];
		if (theURL) {
			theMovie = [[NSMovie alloc] initWithURL:theURL byReference:YES];
			if (theMovie) {
				[videoView setMovie:theMovie];
				[theMovie autorelease];
				[saveMusicButton setEnabled:YES];
				[videoView gotoPosterFrame:self];
			}
		}
	}
	[videoView showController:YES adjustingSize:NO];
	[videoView display];
}

- (ISOPostingContentRep *)_getSelectedMusic
{
	int rowIndex = [musicTable selectedRow];
	return [self _getSelectedAttachmentWithMajorMimeType:@"audio/" andIndex:rowIndex];
}

- (void)musicSelected:sender
{
	ISOPostingContentRep	*postingContentRep;
	NSMovie					*theMovie;
	
	[saveMusicButton setEnabled:NO];
	[musicView setMovie:nil];
	postingContentRep = [self _getSelectedMusic];
	if (postingContentRep && [postingContentRep path] && [[postingContentRep path] length]) {
		NSURL	*theURL = [NSURL fileURLWithPath:[postingContentRep path]];
		if (theURL) {
			theMovie = [[NSMovie alloc] initWithURL:theURL byReference:YES];
			if (theMovie) {
				[musicView setMovie:theMovie];
				[theMovie autorelease];
				[musicView gotoPosterFrame:self];
				[saveMusicButton setEnabled:YES];
			}
		}
	}
	[musicView display];
}

- (ISOPostingContentRep *)_getSelectedAttachment
{
	int rowIndex = [otherTable selectedRow];
	return [self _getSelectedAttachmentWithMajorMimeType:nil andIndex:rowIndex];
}

- (void)otherSelected:sender
{
    int rowIndex;
    rowIndex = [otherTable selectedRow];
	if (rowIndex < [thePosting attachmentCount]) {
		[saveOtherButton setEnabled:YES];
	} else {
		[saveOtherButton setEnabled:NO];
	}
}

- (void)picturesDoubleClicked:sender
{
	ISOPostingContentRep	*postingContentRep;
	
	postingContentRep = [self _getSelectedPicture];
	if (postingContentRep) {
		if (![[NSWorkspace sharedWorkspace] openFile:[postingContentRep path]]) {
			[ISOBeep beep:@"Could open the selected picture. There seems to be no application available to open the picture. You can try saving and opening it directly in the Finder."];
		}
	}
}

- (void)videosDoubleClicked:sender
{
	ISOPostingContentRep	*postingContentRep;
	
	postingContentRep = [self _getSelectedMovie];
	if (postingContentRep) {
		if (![[NSWorkspace sharedWorkspace] openFile:[postingContentRep path]]) {
			[ISOBeep beep:@"Could open the selected video. There seems to be no application available to open the video. You can try saving and opening it directly in the Finder."];
		}
	}
}

- (void)musicDoubleClicked:sender
{
	ISOPostingContentRep	*postingContentRep;
	
	postingContentRep = [self _getSelectedMusic];
	if (postingContentRep) {
		if (![[NSWorkspace sharedWorkspace] openFile:[postingContentRep path]]) {
			[ISOBeep beep:@"Could open the selected music file. There seems to be no application available to open the music file. You can try saving and opening it directly in the Finder."];
		}
	}
}

- (void)attachmentDoubleClicked:sender
{
	ISOPostingContentRep	*postingContentRep;
	
	postingContentRep = [self _getSelectedAttachment];
	if (postingContentRep) {
		if (![[NSWorkspace sharedWorkspace] openFile:[postingContentRep path]]) {
			[ISOBeep beep:@"Could open the selected file. There seems to be no application available to open the file. You can try saving and opening it directly in the Finder."];
		}
	}
}

/* ------------------------------------------------ */
- (void)saveText:sender
{
	[self saveRawSource:sender];
}

- (void)reallySaveAttachment:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void  *)conInfo
{
	int				numberOfItems = 1;
	NSString		*fileName;
	NSFileManager	*fileManager = [NSFileManager defaultManager];
	
	[sheet orderOut:self];
	if (conInfo) {
		if (numberOfItems == 1) {
			if (returnCode == NSFileHandlingPanelOKButton) {
				fileName = [((NSSavePanel *)sheet) filename];
				[[ISOPreferences sharedInstance] setGenericPref:[fileName stringByDeletingLastPathComponent] forKey:@"ISOManualAttachmentsDirectory"];
				if (![fileManager copyPath:[((ISOPostingContentRep *)conInfo) path] toPath:fileName handler:nil]) {
					NSRunAlertPanel(NSLocalizedString(@"Couldn't save file", @""),
						NSLocalizedString(@"Couldn't save the selected attachment to the specified file", @""),
						NSLocalizedString(@"Damn", @""),
						nil,
						nil);
				}
			}
		} else {
		}
	}
}

- (void)_saveAttachment:(ISOPostingContentRep *)aRep withMessage:(NSString *)aMessage
{
	NSSavePanel			 *savePanel;
	
	if (aRep) {
		savePanel = [NSSavePanel savePanel];
		[savePanel setTitle:aMessage];
		[savePanel setRequiredFileType:[aRep extension]];
		[savePanel beginSheetForDirectory:[[ISOPreferences sharedInstance] genericPrefForKey:@"ISOManualAttachmentsDirectory"]
					file:[aRep repName]
					modalForWindow:[subscriptionWindowMgr window]
					modalDelegate:self
					didEndSelector:@selector(reallySaveAttachment:returnCode:contextInfo:)
					contextInfo:aRep];
	}
}


- (void)savePicture:sender
{
	[self _saveAttachment:[self _getSelectedPicture] withMessage:NSLocalizedString(@"Save Picture", @"")];
}

- (void)saveVideo:sender
{
	[self _saveAttachment:[self _getSelectedMovie] withMessage:NSLocalizedString(@"Save Movie/Video", @"")];
}

- (void)saveMusic:sender
{
	[self _saveAttachment:[self _getSelectedMusic] withMessage:NSLocalizedString(@"Save Music", @"")];
}

- (void)saveOther:sender
{
	[self _saveAttachment:[self _getSelectedAttachment] withMessage:NSLocalizedString(@"Save Attachment", @"")];
}

- (void)reallySaveRawSource:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void  *)con
{
	ISONewsPosting 	*aPosting;
	NSMutableString	*aString;
	
	[sheet orderOut:self];
	aPosting = thePosting;
	if (aPosting) {
		aString = [NSMutableString stringWithString:[aPosting headerAsRawText]];
		[aString appendString:@"\r\n\r\n"];
		[aString appendString:[aPosting bodyAsRawText]];
		if (returnCode == NSFileHandlingPanelOKButton) {
			NSString *fileName = [((NSSavePanel *)sheet) filename];
			[[ISOPreferences sharedInstance] setGenericPref:[fileName stringByDeletingLastPathComponent] forKey:@"ISOManualRawSourceDirectory"];
			if (![aString writeToFile:fileName atomically:NO]) {
				NSRunAlertPanel(NSLocalizedString(@"Couldn't save file", @""),
					NSLocalizedString(@"Couldn't save the posting to the specified file...", @""),
					NSLocalizedString(@"Damn", @""),
					nil,
					nil);
			}
		}
	}
}

- (void)saveRawSource:sender
{
	ISONewsPosting 	*aPosting;
	NSSavePanel		*savePanel;
	NSMutableString	*proposedFilename;
	NSRange			aRange;
	
	aPosting = thePosting;
	if (aPosting) {
		savePanel = [NSSavePanel savePanel];
		[savePanel setTitle:NSLocalizedString(@"Save Picture", @"")];
		[savePanel setRequiredFileType:@"txt"];
		proposedFilename = [NSMutableString stringWithString:[aPosting subjectHeader]];
		[proposedFilename appendString:@".txt"];
		aRange = [proposedFilename rangeOfString:@":"];
		while (aRange.length == 1) {
			[proposedFilename replaceCharactersInRange:aRange withString:@"-"];
			aRange = [proposedFilename rangeOfString:@":"];
		}
		[savePanel beginSheetForDirectory:[[ISOPreferences sharedInstance] genericPrefForKey:@"ISOManualRawSourceDirectory"]
					file:proposedFilename
					modalForWindow:[subscriptionWindowMgr window]
					modalDelegate:self
					didEndSelector:@selector(reallySaveRawSource:returnCode:contextInfo:)
					contextInfo:nil];
	}
}


/* TABVIEW STUFF */
- (void)textTabSelected
{
	ISONewsPosting 				*aPosting;
    NSMutableAttributedString	*body;
	NSRange						aRange;
	aPosting = thePosting;
	if (aPosting) {
		int prfLoad = [[ISOPreferences sharedInstance] prefsPostingClickedAction];
		if (![aPosting isBodyLoaded] && (prfLoad == PREFS_PostingClickedDontLoad)) {
			[textField setString:@""];
//			[textField scrollRangeToVisible:NSMakeRange(0, 1)];
		} else {
//			[textField scrollRangeToVisible:NSMakeRange(0, 1)];
			body = [self viewableBody:aPosting];
			[[textField textStorage] setAttributedString:body];
			[body release];
			if ([aPosting hasAttachments] == 0) {
				aRange = [[[subscriptionWindowMgr activeGroup] groupName] rangeOfString:@".binaries."];
				if (aRange.length != [@".binaries." length]) {
					aRange = [[[subscriptionWindowMgr activeGroup] groupName] rangeOfString:@".binary"];
					if (aRange.length != [@".binary" length]) {
						[textField colorizeRange:NSMakeRange(0, [[textField textStorage] length])];
						if ([[ISOPreferences sharedInstance] prefsUsenetFormats]) {
							[textField displayUsenetAttributes];
						}
					}
				}
			}
			[saveTextButton setEnabled:YES];
		}
	} else {
		[saveTextButton setEnabled:NO];
	}
}

- (void)picturesTabSelected
{
	if ([self decodeIfNecessary] == INP_DecodeSuccessfull) {
		[picturesTable reloadData];
		[pictureView setImage:nil];
		if (thePosting) {
			[picturesTable selectRow:0 byExtendingSelection:NO];
			[self pictureSelected:self];
		}
	}
}

- (void)videosTabSelected
{
	if ([self decodeIfNecessary] == INP_DecodeSuccessfull) {
		[videosTable reloadData];
		if (thePosting) {
			[videosTable selectRow:0 byExtendingSelection:NO];
			[self performSelector:@selector(videoSelected:) withObject:self afterDelay:0.25];
		}
	}
}

- (void)musicTabSelected
{
	if ([self decodeIfNecessary] == INP_DecodeSuccessfull) {
		[musicTable reloadData];
		if (thePosting) {
			[musicTable selectRow:0 byExtendingSelection:NO];
			[self performSelector:@selector(musicSelected:) withObject:self afterDelay:0.25];
		}
	}
}

- (void)otherTabSelected
{
	if ([self decodeIfNecessary] == INP_DecodeSuccessfull) {
		[otherTable reloadData];
	}
}

- (void)rawSourceTabSelected
{
	ISONewsPosting 	*aPosting;
	NSMutableString	*aString;
	
	aPosting = thePosting;
	if (aPosting) {
		aString = [NSMutableString stringWithString:[aPosting headerAsRawText]];
		[aString appendString:@"\r\n\r\n"];
		[aString appendString:[aPosting bodyAsRawText]];
		[rawSourceField setString:aString];
		[saveSourceButton setEnabled:YES];
//		[rawSourceField scrollRangeToVisible:NSMakeRange(0, 1)];
	} else {
		[saveSourceButton setEnabled:NO];
	}
}

- (BOOL)_showPostingInTabView:(NSTabViewItem *)tabViewItem
{
	NSString	*anIdentifier = [tabViewItem identifier];

	if ([anIdentifier compare:@"TEXT"] == NSOrderedSame) {
		[self textTabSelected];
	} else if ([anIdentifier compare:@"PICTURES"] == NSOrderedSame) {
		[self picturesTabSelected];
	} else if ([anIdentifier compare:@"VIDEOS"] == NSOrderedSame) {
		[self videosTabSelected];
	} else if ([anIdentifier compare:@"MUSIC"] == NSOrderedSame) {
		[self musicTabSelected];
	} else if ([anIdentifier compare:@"OTHER"] == NSOrderedSame) {
		[self otherTabSelected];
	} else if ([anIdentifier compare:@"RAWSOURCE"] == NSOrderedSame) {
		[self rawSourceTabSelected];
	}
	return YES;
}

- (BOOL)_clearPostingInTabView:(NSTabViewItem *)tabViewItem
{
	if ([[[subscriptionWindowMgr window] contentView] lockFocusIfCanDraw]) {
		[textField setString:@""];
		[pictureView setImage:nil];
		[picturesTable reloadData];
		[videosTable reloadData];
		[musicTable reloadData];
		[otherTable reloadData];
		[rawSourceField setString:@""];
		[saveTextButton setEnabled:NO];
		[savePictureButton setEnabled:NO];
		[saveVideoButton setEnabled:NO];
		[saveMusicButton setEnabled:NO];
		[saveOtherButton setEnabled:NO];
		[saveSourceButton setEnabled:NO];
		[[[subscriptionWindowMgr window] contentView] unlockFocus];
	}
	return YES;
}

- (void)showPosting
{
	[self _showPostingInTabView:[tabView selectedTabViewItem]];
}

- (void)clearPosting
{
	[self _clearPostingInTabView:[tabView selectedTabViewItem]];
}

- (void)clearDisplay
{
	[self _clearPostingInTabView:nil];
}

- (void)tabView:(NSTabView *)tabView didSelectTabViewItem:(NSTabViewItem *)tabViewItem
{
	[self _showPostingInTabView:tabViewItem];
}


/* TabView Actions */
- (int)decodeIfNecessary
{
//    NSAutoreleasePool	*aPool;
	int					retval;
	
//	aPool = [[NSAutoreleasePool alloc] init];
	retval = [thePosting decodeIfNecessary];
	if (retval == INP_DecodeMultipart) {
		retval = NSRunAlertPanel(NSLocalizedString(@"Missing Parts", @""),
			NSLocalizedString(@"This is a multi-part attachment, i.e. the attachment is distributed over multiple news postings.\nDo you want me to try to detect the missing postings and try to decode again (also add not downloaded postings to the Send/Receive Manager, if necessary)?", @""),
			NSLocalizedString(@"Yes, Try to Decode", @""),
			nil,
			NSLocalizedString(@"Forget it", @""));
		if (retval == NSAlertDefaultReturn) {
			retval = [thePosting decodeMultiIfNecessary:[[subscriptionWindowMgr activeGroup] postingsFlat] forSender:self];
/*
			[progressIndicator setIndeterminate:NO];
			[progressIndicator setDoubleValue:0.0];
			[progressMessageField setStringValue:NSLocalizedString(@"Ready.", @"")];
			[progressMessageField display];
*/
			if (retval == INP_DecodeMultipartAdded) {
				retval = NSRunAlertPanel(NSLocalizedString(@"Some Postings not Downloaded", @""),
					NSLocalizedString(@"Some postings necessary to decode this multipart attachment are not yet downloaded. These are added to the Send/Receive Manager. You can download those postings and try again.",@""),
					NSLocalizedString(@"Open Send/Receive Manager", @""),
					nil,
					NSLocalizedString(@"Okay, I'll Check Later", @""));
				if (retval == NSAlertDefaultReturn) {
					[[ISOOfflineMgr sharedOfflineMgr] showSendReceiveWindowSwitchingTo:OFFLINE_OUTGOING];
					[[ISOOfflineMgr sharedOfflineMgr] setUploadOutgoing:YES];
				}
			} else if (retval == INP_DecodeMultipartMissingPosting) {
				retval = NSRunAlertPanel(NSLocalizedString(@"Some Postings are Missing", @""),
					NSLocalizedString(@"Some postings which are necessary to decode this multipart attachment are missing, i.e. there are no headers for those postings. You can try and check for new postings on the server.\nAlso, the missing postings may arrive at a later time. You may wish to keep this posting until you either find the missing postings or decide to delete this posting.",@""),
					NSLocalizedString(@"Check for New Postings", @""),
					nil,
					NSLocalizedString(@"Okay, I'll Check Later", @""));
				if (retval == NSAlertDefaultReturn) {
					[theSubscriptionMgr checkForNewPostings];
				}
			}
		}
	} else if (retval == INP_DecodeError) {
	//	[ISOBeep beep:@"There was an error decoding the attachment."];
	}
	
//	[aPool release];
	return retval;
}

/* Autoamtic saving... */
- (void)_autoSaveAttachement:(ISOPostingContentRep *)aRep
{
	NSMutableString	*destinationPath;
	NSFileManager	*fileManager = [NSFileManager defaultManager];
	BOOL			returnvalue;
	
	returnvalue = YES;
	if (aRep) {
		destinationPath = [NSMutableString stringWithString:[[ISOPreferences sharedInstance] prefsExtractionDirectory]];
		if ([[ISOPreferences sharedInstance] prefsCreateGroupSubdirs]) {
			NSMutableString	*groupName = [NSMutableString stringWithString:[thePosting mainGroupName]];
			NSRange			aRange;
			
			NS_DURING
				aRange = [groupName rangeOfString:@"."];
				while (aRange.length == 1) {
					[groupName replaceCharactersInRange:aRange withString:@"/"];
					aRange = [groupName rangeOfString:@"."];
				}
				[destinationPath appendFormat:@"/%@", groupName];
			NS_HANDLER
				[destinationPath appendString:@"/UNREADABLEGROUPNAME"];
			NS_ENDHANDLER
		}
		if ([[ISOPreferences sharedInstance] prefsCreateDateSubdirs]) {	
			NSCalendarDate	*date = [NSCalendarDate calendarDate];
			[destinationPath appendFormat:@"/%04d/%02d/%02d", [date yearOfCommonEra], [date monthOfYear], [date dayOfMonth]];
		}
		if ([ISOResourceMgr createDirectory:destinationPath]) {
			NSString *fileName = [NSString stringWithFormat:@"%@/%@", destinationPath, [[aRep path] lastPathComponent]];
			if (![fileManager copyPath:[aRep path] toPath:fileName handler:nil]) {
				returnvalue = NO;
			}
		} else {
			returnvalue = NO;
		}
	} else {
		returnvalue = NO;
	}
	if (!returnvalue) {
		NSBeep();
	}
}

- (void)autoSaveDependingOnCurrentView
{
	NSString *anIdentifier = [[tabView selectedTabViewItem] identifier];
	if ([anIdentifier compare:@"TEXT"] == NSOrderedSame) {
		[self saveRawSource:self];
	} else if ([anIdentifier compare:@"PICTURES"] == NSOrderedSame) {
		[self _autoSaveAttachement:[self _getSelectedPicture]];
	} else if ([anIdentifier compare:@"VIDEOS"] == NSOrderedSame) {
		[self _autoSaveAttachement:[self _getSelectedMovie]];
	} else if ([anIdentifier compare:@"MUSIC"] == NSOrderedSame) {
		[self _autoSaveAttachement:[self _getSelectedMusic]];
	} else if ([anIdentifier compare:@"OTHER"] == NSOrderedSame) {
		[self _autoSaveAttachement:[self _getSelectedAttachment]];
	} else if ([anIdentifier compare:@"RAWSOURCE"] == NSOrderedSame) {
		[self saveRawSource:self];
	} else {
		NSBeep();
	}
}

- (void)encodingChangedTo:(int)anEncoding
{
	if (thePosting) {
		[thePosting setDisplayEncoding:anEncoding];
		[self showPosting];
	}
}

- (void)multipartFile:(char *)filename decodingAction:(int)action size:(int)size partno:(int)partno numparts:(int)numparts percent:(float)percent
{
	NSString	*msg;
	
	if (action == UUACT_SCANNING) {
		msg = NSLocalizedString(@"Scanning Postings for Attachments...", @"");
	} else if (action == UUACT_DECODING) {
		msg = NSLocalizedString(@"Decoding Attachment(s)...", @"");
	} else if (action == UUACT_COPYING) {
		msg = NSLocalizedString(@"Copying Attachment(s)...", @"");
	} else {
		msg = @"";
	}
	/*
	if ([msg compare:[progressMessageField stringValue]] != NSOrderedSame) {
		[progressMessageField setStringValue:msg];
		[progressMessageField display];
	}
	*/
}

- (void)scaleImageToFitClicked:sender
{
	[self pictureSelected:self];
}

- (NSString *)selectedBodyPart
{
	NSString	*retvalue = nil;
	if (thePosting) {
		NSRange selectionRange = [textField selectedRange];
		if (selectionRange.length != 0) {
			NSAttributedString *aString  = [textField attributedSubstringFromRange:selectionRange];
			if (aString) {
				retvalue = [aString string];
			}
		}
	}
	return retvalue;
}


@end
