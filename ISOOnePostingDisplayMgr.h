//
//  ISOOnePostingDisplayMgr.h
//  Halime
//
//  Created by Imdat Solak on Sun Sep 15 2002.
//  Copyright (c) 2002 Imdat Solak. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "ISONewsPosting.h"
#import "ISOSubscriptionMgr.h"

@interface ISOOnePostingDisplayMgr : NSObject 
{
	ISONewsPosting		*thePosting;
	ISOSubscriptionMgr	*theSubscriptionMgr;
    id	textField;
    
    id	picturesTable;
    id	pictureView;
	id	pictureScrollView;
    
    id	videosTable;
    id	videoView;

    id	musicTable;
    id	musicView;
    
    id	otherTable;
    id	otherMimeField;
    id	otherExtField;
    
    id	rawSourceField;
    
    id	saveTextButton;
    id	savePictureButton;
    id	saveVideoButton;
    id	saveMusicButton;
    id	saveOtherButton;
    id	saveSourceButton;
    id	tabView;
	id	scaleImageToFitSwitch;
	id	subscriptionWindowMgr;
}

- init;
- (void)dealloc;
- setOwner:(id)anObject;
- setSubscriptionMgr:(ISOSubscriptionMgr *)aMgr;
- setPosting:(ISONewsPosting *)aPosting;
- (int)numberOfRowsInTableView:(NSTableView *)aTableView;
- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex;
- (id)picturesTableValueForTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex;
- (id)videosTableValueForTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex;
- (id)musicTableValueForTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex;
- (id)otherTableValueForTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex;
- (void)tableViewSelectionDidChange:(NSNotification *)aNotification;
- (void)_addFilteredHeadersFromPosting:(ISONewsPosting *)aPosting toString:(NSMutableAttributedString *)aString boldAttrib:(NSMutableDictionary *)bold unboldAttrib:(NSMutableDictionary *)unbold;
- (void)_addAllHeadersFromPosting:(ISONewsPosting *)aPosting toString:(NSMutableAttributedString *)aString boldAttrib:(NSMutableDictionary *)bold unboldAttrib:(NSMutableDictionary *)unbold;
- (NSMutableAttributedString *)viewableBody:(ISONewsPosting *)aPosting;
- (void)pictureSelected:sender;
- (void)videoSelected:sender;
- (void)musicSelected:sender;
- (void)otherSelected:sender;
- (void)picturesDoubleClicked:sender;
- (void)videosDoubleClicked:sender;
- (void)musicDoubleClicked:sender;
- (void)attachmentDoubleClicked:sender;
- (void)saveText:sender;
- (void)reallySaveAttachment:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void  *)conInfo;
- (void)savePicture:sender;
- (void)saveVideo:sender;
- (void)saveMusic:sender;
- (void)saveOther:sender;
- (void)reallySaveRawSource:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void  *)con;
- (void)saveRawSource:sender;
- (void)textTabSelected;
- (void)picturesTabSelected;
- (void)videosTabSelected;
- (void)musicTabSelected;
- (void)otherTabSelected;
- (void)rawSourceTabSelected;
- (void)showPosting;
- (void)clearPosting;
- (void)clearDisplay;
- (void)tabView:(NSTabView *)tabView didSelectTabViewItem:(NSTabViewItem *)tabViewItem;
- (int)decodeIfNecessary;
- (void)autoSaveDependingOnCurrentView;
- (void)encodingChangedTo:(int)anEncoding;
- (void)multipartFile:(char *)filename decodingAction:(int)action size:(int)size partno:(int)partno numparts:(int)numparts percent:(float)percent;
- (void)scaleImageToFitClicked:sender;
- (NSString *)selectedBodyPart;

@end
