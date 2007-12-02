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
	// TODO: verify things more carefully

	NSString *zone = [actionDict valueForKey:@"parameter"];
	NSTimeZone *tz = [NSTimeZone timeZoneWithName:zone];
	if (!tz) {
		*errorString = NSLocalizedString(@"Couldn't set time zone!", @"");
		return NO;
	}

	// TODO: Relink /etc/localtime symlink to /usr/share/zoneinfo/<zone-name>,
	// where <zone-name> is like Australia/Sydney

	// TODO: Would we need to restart any standard system programs to get clock displays correct?

//	NSArray *args = [NSArray arrayWithObjects:@"-d", printerQueue, nil];
//	NSTask *task = [NSTask launchedTaskWithLaunchPath:@"/usr/bin/lpoptions" arguments:args];
//	[task waitUntilExit];
//
//	if ([task terminationStatus] != 0) {
		*errorString = NSLocalizedString(@"Couldn't set time zone!", @"");
		return NO;
//	}
//
//	return YES;
}

- (NSString *)suggestionLeadText
{
	return NSLocalizedString(@"Use this time zone:", @"");
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
				[zone name], @"option", desc, @"description", nil]];
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
