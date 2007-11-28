/* PrefsWindowController */

#import <Cocoa/Cocoa.h>
#import "Action.h"
#import "ContextTree.h"
#import "ContextSelectionButton.h"
#import "MPController.h"
#import "PopButton.h"

@interface PrefsWindowController : NSWindowController
{
	IBOutlet NSWindow *prefsWindow;
	IBOutlet NSView *generalPrefsView, *contextsPrefsView, *evidenceSourcesPrefsView,
			*rulesPrefsView, *actionsPrefsView, *advancedPrefsView;
	NSString *currentPrefsGroup;
	NSView *currentPrefsView, *blankPrefsView;
	NSArray *prefsGroups;
	NSToolbar *prefsToolbar;

	IBOutlet MPController *mpController;
	IBOutlet EvidenceSourceSetController *evidenceSources;
	IBOutlet ActionSetController *actionSet;
	IBOutlet NSArrayController *rulesController, *filteredRulesController, *actionsController;

	// Selection controls for rules
	IBOutlet ContextSelectionButton *defaultContextButton;

	// New action creation hooks
//	NSString *newActionType, *newActionTypeString;
//	NSString *newActionWindowHelpText;
//	NSView *newActionWindowParameterViewCurrentControl;
//	NSString *newActionWindowWhen;

	// Action trigger hooks
	IBOutlet PopButton *newActionTriggerButton;
	IBOutlet NSArrayController *triggersController;

	IBOutlet NSTextView *logBufferView;
	NSNumber *logBufferPaused;
	NSTimer *logBufferTimer;

	// Context pane
	IBOutlet NSOutlineView *contextOutlineView;
	Context *contextSelection;

	// Context UI bits
	IBOutlet NSPanel *newContextSheet;
	IBOutlet NSTextField *newContextSheetName;
}

- (IBAction)runPreferences:(id)sender;
- (IBAction)runAbout:(id)sender;
- (IBAction)runWebPage:(id)sender;

- (void)switchToViewFromToolbar:(NSToolbarItem *)item;
- (void)switchToView:(NSString *)identifier;
- (void)resizeWindowToSize:(NSSize)size withMinSize:(NSSize)minSize limitMaxSize:(BOOL)limitMaxSize;

// NSToolbar delegates
- (NSToolbarItem *)toolbar:(NSToolbar *)toolbar itemForItemIdentifier:(NSString *)groupId willBeInsertedIntoToolbar:(BOOL)flag;
- (NSArray *)toolbarAllowedItemIdentifiers:(NSToolbar *)toolbar;
- (NSArray *)toolbarDefaultItemIdentifiers:(NSToolbar *)toolbar;
- (NSArray *)toolbarSelectableItemIdentifiers:(NSToolbar *)toolbar;

- (IBAction)newContextPromptingForName:(id)sender;
- (IBAction)newContextSheetAccepted:(id)sender;
- (IBAction)newContextSheetRejected:(id)sender;
- (IBAction)removeContext:(id)sender;
- (id)contextSelectionIndexPaths;
- (void)setContextSelectionIndexPaths:(id)arg;

- (void)addRule:(id)sender;
- (IBAction)editRule:(id)sender;

- (void)addAction:(id)sender;
- (IBAction)editAction:(id)sender;

- (IBAction)removeTrigger:(id)sender;

@end
