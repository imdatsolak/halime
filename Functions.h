#import <Cocoa/Cocoa.h>

extern NSString *ISOCreateComparableDateFromDateHeader(NSString *dateHeader);
extern NSString *ISOHumanReadableSizeFrom(int sizeInBytes);
extern NSString *ISONameOnlyFromSenderString(NSString *aSender);
extern NSCalendarDate *ISOCalendarDateFromString(NSString *aString);
extern NSImage *ISOCreateXFaceImageFromString(NSString *xFace);
extern NSImage *ISOCreateXFaceURLImageFromString(NSString *xFaceURL);
extern NSString *ISOBitsForCFStringEncoding(CFStringEncoding stringEncoding);
extern NSString *ISOCreateDisplayableDateFromDateHeader(NSString *originalDate, BOOL relativeDate, BOOL shortDate);

extern int compareSubjects(id postingOne, id postingTwo, void *ascending);
extern int compareSender(id postingOne, id postingTwo, void *ascending);
extern int compareDate(id postingOne, id postingTwo, void *ascending);
extern int compareSize(id postingOne, id postingTwo, void *ascending);

