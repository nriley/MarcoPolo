//
//  UnmountAction.m
//  MarcoPolo
//
//  Created by Mark Wallis on 14/11/07.
//

#import "UnmountAction.h"


@implementation UnmountAction

- (NSString *)leadText
{
	return NSLocalizedString(@"Unmount this volume:", @"");
}

- (NSString *)descriptionOf:(NSDictionary *)actionDict
{
	return [NSString stringWithFormat:NSLocalizedString(@"Unmounting '%@'.", @""),
		[actionDict valueForKey:@"parameter"]];
}

- (BOOL)execute:(NSDictionary *)actionDict error:(NSString **)errorString
{
	// TODO: properly escape path?
	NSString *script = [NSString stringWithFormat:
		@"tell application \"Finder\"\n"
		"  activate\n"
		"  eject \"%@\"\n"
		"end tell\n", [actionDict valueForKey:@"parameter"]];

	if (![self executeAppleScript:script]) {
		*errorString = NSLocalizedString(@"Couldn't unmount that volume!", @"In UnmountAction");
		return NO;
	}

	return YES;
}

@end
