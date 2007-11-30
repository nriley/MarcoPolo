//
//  DesktopBackgroundAction.m
//  MarcoPolo
//
//  Created by David Symonds on 12/11/07.
//

#import "DesktopBackgroundAction.h"


@implementation DesktopBackgroundAction

- (NSString *)descriptionOf:(NSDictionary *)actionDict
{
	return [NSString stringWithFormat:NSLocalizedString(@"Setting desktop background to '%@'.", @""),
		[[actionDict valueForKey:@"parameter"] lastPathComponent]];
}

- (NSString *)pathAsHFSPath:(NSString *)path
{
	CFURLRef url = CFURLCreateWithFileSystemPath(NULL, (CFStringRef) path, kCFURLPOSIXPathStyle, false);
	NSString *ret = (NSString *) CFURLCopyFileSystemPath(url, kCFURLHFSPathStyle);
	CFRelease(url);

	return ret;
}

- (BOOL)execute:(NSDictionary *)actionDict error:(NSString **)errorString
{
	NSString *path = [actionDict valueForKey:@"parameter"];

	if (![[NSFileManager defaultManager] fileExistsAtPath:path])
		goto failed_to_set;

	// TODO: properly escape status path
	NSString *script = [NSString stringWithFormat:
		@"tell application \"Finder\"\n"
		"  set desktop picture to \"%@\"\n"
		"end tell\n", [self pathAsHFSPath:path]];

	if ([self executeAppleScript:script])
		return YES;

failed_to_set:
	*errorString = [NSString stringWithFormat:NSLocalizedString(@"Failed setting '%@' as desktop background.", @""),
		[path lastPathComponent]];
	return NO;
}

@end
