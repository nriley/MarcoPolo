//
//  MountAction.m
//  MarcoPolo
//
//  Created by David Symonds on 9/06/07.
//

#import "MountAction.h"


@implementation MountAction

- (NSString *)leadText
{
	return NSLocalizedString(@"Mount this volume:", @"");
}

- (NSString *)descriptionOf:(NSDictionary *)actionDict
{
	return [NSString stringWithFormat:NSLocalizedString(@"Mounting '%@'.", @""),
		[actionDict valueForKey:@"parameter"]];
}

- (BOOL)execute:(NSDictionary *)actionDict error:(NSString **)errorString
{
	// TODO: properly escape path?
	NSString *script = [NSString stringWithFormat:
		@"tell application \"Finder\"\n"
		"  activate\n"
		"  mount volume \"%@\"\n"
		"end tell\n", [actionDict valueForKey:@"parameter"]];

	if (![self executeAppleScript:script]) {
		*errorString = NSLocalizedString(@"Couldn't mount that volume!", @"In MountAction");
		return NO;
	}

	return YES;
}

@end
