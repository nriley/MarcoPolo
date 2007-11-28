//
//  MPApplication.h
//  MarcoPolo
//
//  Created by David Symonds on 2/11/07.
//

#import <Cocoa/Cocoa.h>
#import "ContextTree.h"


@class MPController;

@interface MPApplication : NSApplication {
	IBOutlet MPController *mpController;
}

- (Context *)currentContext;

@end
