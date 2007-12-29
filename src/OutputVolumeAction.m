//
//  OutputVolumeAction.m
//  MarcoPolo
//
//  Created by David Symonds on 12/12/07.
//

#import "OutputVolumeAction.h"


@implementation OutputVolumeAction

- (NSString *)leadText
{
	return NSLocalizedString(@"Set output volume:", @"");
}

- (NSString *)descriptionOf:(NSDictionary *)actionDict
{
	return [NSString stringWithFormat:NSLocalizedString(@"Setting output volume to %.0f%%.", @""),
		[[actionDict valueForKey:@"parameter"] floatValue] * 100];
}

- (BOOL)execute:(NSDictionary *)actionDict error:(NSString **)errorString
{
	NSString *script = [NSString stringWithFormat:
		@"set volume output volume %.1f", [[actionDict valueForKey:@"parameter"] floatValue] * 100];

	if (![self executeAppleScript:script]) {
		*errorString = NSLocalizedString(@"Couldn't set output volume!", @"In OutputVolumeAction");
		return NO;
	}

	return YES;
}

@end
