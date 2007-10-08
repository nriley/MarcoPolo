//
//  ContextFilteredController.h
//  MarcoPolo
//
//  Created by David Symonds on 8/10/07.
//

#import <Cocoa/Cocoa.h>


@interface ContextFilteredController : NSArrayController {
	NSString *selectedContext;
	IBOutlet NSOutlineView *outlineView;
}

@end
