//
//  MPApplication.m
//  MarcoPolo
//
//  Created by David Symonds on 2/11/07.
//

#import "MPApplication.h"


@implementation MPApplication

#pragma mark AppleScript hooks

- (Context *)currentContext
{
	return [[ContextTree sharedInstance] contextByUUID:[mpController valueForKey:@"currentContextUUID"]];
}

@end
