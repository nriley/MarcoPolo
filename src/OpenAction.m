//
//  OpenAction.m
//  MarcoPolo
//
//  Created by David Symonds on 3/04/07.
//

#import "OpenAction.h"


@implementation OpenAction

- (NSString *)descriptionOf:(NSDictionary *)actionDict
{
	return [NSString stringWithFormat:NSLocalizedString(@"Opening '%@'.", @""),
		[[actionDict valueForKey:@"parameter"] lastPathComponent]];
}

- (BOOL)execute:(NSDictionary *)actionDict error:(NSString **)errorString
{
	NSString *path = [actionDict valueForKey:@"parameter"];
	NSString *app, *fileType;

	if (![[NSWorkspace sharedWorkspace] getInfoForFile:path application:&app type:&fileType])
		goto failed_to_open;

#ifdef DEBUG_MODE
	NSLog(@"[%@]: Type: '%@'.", [self class], fileType);
#endif

	if ([[fileType uppercaseString] isEqualToString:@"SCPT"]) {
		NSArray *args = [NSArray arrayWithObject:path];
		NSTask *task = [NSTask launchedTaskWithLaunchPath:@"/usr/bin/osascript" arguments:args];
		[task waitUntilExit];
		if ([task terminationStatus] == 0)
			return YES;
	} else {
		// Fallback
		if ([[NSWorkspace sharedWorkspace] openFile:path])
			return YES;
	}

failed_to_open:
	*errorString = [NSString stringWithFormat:NSLocalizedString(@"Failed opening '%@'.", @""), path];
	return NO;
}

@end
