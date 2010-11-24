//
//  MPApplication.m
//  MarcoPolo
//
//  Created by David Symonds on 2/11/07.
//

#import "MPApplication.h"


@implementation MPApplication

#pragma mark AppleScript hooks

- (NSArray *)contexts
{
    static NSMutableArray *contexts = nil;
    if (contexts == nil)
        contexts = [[NSMutableArray alloc] init];
    [contexts removeAllObjects];
    [contexts addObjectsFromArray:[[ContextTree sharedInstance] orderedTraversal]];
    return contexts;
}

- (Context *)currentContext
{
	return [[ContextTree sharedInstance] contextByUUID:[mpController valueForKey:@"currentContextUUID"]];
}

@end
