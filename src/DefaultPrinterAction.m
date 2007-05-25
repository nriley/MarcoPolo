//
//  DefaultPrinterAction.m
//  MarcoPolo
//
//  Created by David Symonds on 3/04/07.
//

#import "DefaultPrinterAction.h"


@implementation DefaultPrinterAction

- (id)init
{
	if (!(self = [super init]))
		return nil;

	printerQueue = @"";

	return self;
}

- (id)initWithDictionary:(NSDictionary *)dict
{
	if (!(self = [super init]))
		return nil;

	printerQueue = [dict valueForKey:@"parameter"];

	return self;
}

- (void)dealloc
{
	[super dealloc];
}

- (NSMutableDictionary *)dictionary
{
	NSMutableDictionary *dict = [super dictionary];

	[dict setObject:printerQueue forKey:@"parameter"];

	return dict;
}

- (NSString *)description
{
	return [NSString stringWithFormat:NSLocalizedString(@"Setting default printer to '%@'.", @""),
		printerQueue];
}

- (BOOL)execute:(NSString **)errorString
{
	NSArray *args = [NSArray arrayWithObjects:@"-d", printerQueue, nil];
	NSTask *task = [NSTask launchedTaskWithLaunchPath:@"/usr/bin/lpoptions" arguments:args];
	[task waitUntilExit];

	if ([task terminationStatus] != 0) {
		*errorString = NSLocalizedString(@"Couldn't set default printer!", @"");
		return NO;
	}

	return YES;
}

+ (NSString *)helpText
{
	return NSLocalizedString(@"The parameter for DefaultPrinter actions is the name of the "
				 "printer queue. This is usually the name of the printer, with "
				 "spaces replaced by underscores.", @"");
}

+ (NSArray *)limitedOptions
{
	NSTask *task = [[[NSTask alloc] init] autorelease];

	[task setLaunchPath:@"/usr/bin/lpstat"];
	[task setArguments:[NSArray arrayWithObject:@"-a"]];
	[task setStandardOutput:[NSPipe pipe]];

	[task launch];
	NSData *data = [[[task standardOutput] fileHandleForReading] readDataToEndOfFile];
	[task waitUntilExit];
	if ([task terminationStatus] != 0)	// failure
		return [NSArray array];
	// XXX: what's the proper string encoding here?
	NSString *s_data = [[[NSString alloc] initWithData:data encoding:NSMacOSRomanStringEncoding] autorelease];
	NSArray *lines = [s_data componentsSeparatedByString:@"\n"];
	//NSLog(@"[%@ limitedOptions] got data:\n%@", [self class], lines);

	NSMutableArray *opts = [NSMutableArray arrayWithCapacity:[lines count]];
	NSEnumerator *en = [lines objectEnumerator];
	NSString *line;
	while ((line = [en nextObject])) {
		if ([line length] < 2)
			continue;
		// Printer queue name is first field on the line
		NSString *queue = [[line componentsSeparatedByString:@" "] objectAtIndex:0];
		[opts addObject:[NSDictionary dictionaryWithObjectsAndKeys:
				queue, @"option", queue, @"description", nil]];
	}

	return opts;
}

+ (NSString *)limitedOptionHelpText
{
	return NSLocalizedString(@"Change default printer to", @"");
}

- (id)initWithOption:(NSString *)option
{
	[self init];
	printerQueue = option;
	return self;
}

@end
