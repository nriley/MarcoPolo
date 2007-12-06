//
//  TimeZoneAction.m
//  MarcoPolo
//
//  Created by David Symonds on 22/09/07.
//

#import "TimeZoneAction.h"


@interface TimeZoneAction (Private)

- (NSArray *)validTimeZones;

@end

#pragma mark -

@implementation TimeZoneAction

- (NSString *)descriptionOf:(NSDictionary *)actionDict
{
	return [NSString stringWithFormat:NSLocalizedString(@"Setting time zone to '%@'.", @""),
		[actionDict valueForKey:@"parameter"]];
}

- (BOOL)execute:(NSDictionary *)actionDict error:(NSString **)errorString
{
	NSString *zone = [actionDict valueForKey:@"parameter"];

	// Sanity check: parameter should describe a known timezone
	NSTimeZone *tz = [NSTimeZone timeZoneWithName:zone];
	if (!tz) {
		NSLog(@"Didn't recognise '%@' as a time zone", zone);
		*errorString = NSLocalizedString(@"Couldn't set time zone!", @"");
		return NO;
	}

	// Sanity check: parameter should have no more than one "/" in it, and no periods
	if ([[zone componentsSeparatedByString:@"/"] count] > 2) {
		NSLog(@"'%@' has too many slashes", zone);
		*errorString = NSLocalizedString(@"Couldn't set time zone!", @"");
		return NO;
	} else if ([[zone componentsSeparatedByString:@"."] count] > 1) {
		NSLog(@"'%@' has too many periods", zone);
		*errorString = NSLocalizedString(@"Couldn't set time zone!", @"");
		return NO;
	}

	// TODO: verify things more carefully?

	// Relink /etc/localtime symlink to /usr/share/zoneinfo/<zone-name>,
	// where <zone-name> is like Australia/Sydney
	NSString *destPath = [@"/usr/share/zoneinfo" stringByAppendingPathComponent:zone];
	NSString *tool = @"/bin/ln";
	NSArray *args = [NSArray arrayWithObjects:@"-sfv", destPath, @"/etc/localtime", nil];
	NSString *prompt = NSLocalizedString(@"MarcoPolo needs to change a system file to set your timezone.\n\n",
					     @"In TimeZoneAction");

	if (![self authExec:tool args:args authPrompt:prompt]) {
		*errorString = NSLocalizedString(@"Couldn't set time zone!", @"");
		return NO;
	}

	// TODO: What standard system programs do we need to restart to get clock displays correct?

	return YES;
}

- (NSString *)suggestionLeadText
{
	return NSLocalizedString(@"Set this time zone:", @"");
}

- (NSArray *)suggestions
{
	NSArray *zones = [self validTimeZones];

	NSMutableArray *opts = [NSMutableArray arrayWithCapacity:[zones count]];
	NSEnumerator *en = [zones objectEnumerator];
	NSTimeZone *zone;
	while ((zone = [en nextObject])) {
		// Standard timezone offset format is in hundredths of minutes
		NSString *desc = [NSString stringWithFormat:@"%@ (%@) (%+04d)",
				[zone name], [zone abbreviation], [zone secondsFromGMT] / 36];
		[opts addObject:[NSDictionary dictionaryWithObjectsAndKeys:
				[zone name], @"parameter", desc, @"description", nil]];
	}

	return opts;
}

#pragma mark -

- (NSArray *)validTimeZones
{
	NSArray *zoneNames = [[NSTimeZone knownTimeZoneNames] sortedArrayUsingSelector:@selector(compare:)];
	NSMutableArray *validZones = [NSMutableArray arrayWithCapacity:[zoneNames count]];

	NSEnumerator *en = [zoneNames objectEnumerator];
	NSString *name;
	while ((name = [en nextObject])) {
		NSTimeZone *zone = [NSTimeZone timeZoneWithName:name];
		if (!zone)
			continue;

		[validZones addObject:[NSTimeZone timeZoneWithName:name]];
	}

	return validZones;
}

@end
