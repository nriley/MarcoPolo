//
//  MPController.h
//  MarcoPolo
//
//  Created by David Symonds on 1/02/07.
//

#include "Growl/GrowlApplicationBridge.h"
#import <Cocoa/Cocoa.h>
#import "Action.h"
#import "ContextTree.h"
#import "EvidenceSource.h"


@interface MPController : NSObject <GrowlApplicationBridgeDelegate> {
	IBOutlet NSMenu *sbMenu;
	NSStatusItem *sbItem;
	NSImage *sbImageActive, *sbImageInactive;
	NSTimer *sbHideTimer;

	NSString *currentContextUUID, *currentContextName;
	NSString *guessConfidence;
	BOOL guessIsConfident;
	int smoothCounter;

	IBOutlet NSMenuItem *forceContextMenuItem;
	BOOL forcedContextIsSticky;
	NSMenuItem *stickForcedContextMenuItem;

	NSTimer *updatingTimer;
	NSThread *updatingThread;
	NSLock *updatingSwitchingLock;
	NSConditionLock *updatingLock;
	BOOL timeToDie;

	ContextTree *contextTree;
	IBOutlet EvidenceSourceSetController *evidenceSources;
	IBOutlet ActionSetController *actionSet;

	IBOutlet NSArrayController *rulesController;
	IBOutlet NSArrayController *actionsController;

	IBOutlet NSWindow *prefsWindow;
	IBOutlet NSOutlineView *contextOutlineView;	// in Context pane
}

@end
