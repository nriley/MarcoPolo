/* PrefsWindowController */

#import <Cocoa/Cocoa.h>
#import "ContextTree.h"
#import "ContextSelectionButton.h"
#import "MPController.h"

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
	IBOutlet NSArrayController *rulesController, *filteredRulesController, *actionsController;
	IBOutlet NSArrayController *whenActionController;

	// Selection controls for rules/actions
	IBOutlet ContextSelectionButton *defaultContextButton;
	IBOutlet ContextSelectionButton *editActionContextButton;

	// New action creation hooks
	IBOutlet NSWindow *newActionWindow;
	NSString *newActionType, *newActionTypeString;
	NSString *newActionWindowHelpText;
	IBOutlet NSView *newActionWindowParameterView;
	NSView *newActionWindowParameterViewCurrentControl;
	IBOutlet NSArrayController *newActionLimitedOptionsController;
	IBOutlet NSPopUpButton *newActionContext;
	NSString *newActionWindowWhen;

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
- (IBAction)doAddAction:(id)sender;

@end
