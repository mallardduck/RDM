

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import <IOKit/graphics/IOGraphicsLib.h>

#import "SRApplicationDelegate.h"

#import "utils.h"
#import "ResMenuItem.h"
#import "RDM-Swift.h"


#define MAX_DISPLAYS 0x10


void DisplayReconfigurationCallback(CGDirectDisplayID cg_id,
                                    CGDisplayChangeSummaryFlags change_flags,
                                    void *app_delegate)
{
	SRApplicationDelegate *appDelegate = (__bridge SRApplicationDelegate*)app_delegate;
    [appDelegate refreshStatusMenu];
}




@implementation SRApplicationDelegate

- (void) showAbout
{
  [NSApp activateIgnoringOtherApps:YES];
  [NSApp orderFrontStandardAboutPanel:self];
}


- (void) quit
{
	[NSApp terminate: self];
}



- (void) refreshStatusMenu
{
	
	statusMenu = [[NSMenu alloc] initWithTitle: @""];
	
	uint32_t nDisplays;
	CGDirectDisplayID displays[MAX_DISPLAYS];
	CGGetOnlineDisplayList(MAX_DISPLAYS, displays, &nDisplays);
	
	for(int i=0; i<nDisplays; i++)
	{
		CGDirectDisplayID display = displays[i];
		{
			NSMenuItem* item;
			NSString* title = i ? [NSString stringWithFormat: @"Display %d", i+1] : @"Main Display";
			item = [[NSMenuItem alloc] initWithTitle: title action: nil keyEquivalent: @""];
			[item setEnabled: NO];
			[statusMenu addItem: item];
		}
		
		
		int mainModeNum;
		CGSGetCurrentDisplayMode(display, &mainModeNum);
		//modes_D4 mainMode;
		//CGSGetDisplayModeDescriptionOfLength(display, mainModeNum, &mainMode, 0xD4);
		ResMenuItem* mainItem = nil;
		
		
		int nModes;
		modes_D4* modes;
		CopyAllDisplayModes(display, &modes, &nModes);
		
		{
			NSMutableArray* displayMenuItems = [NSMutableArray new];
			//ResMenuItem* mainItem = nil;
			
			for(int j = 0; j <nModes; j++)
		    {
				ResMenuItem* item = [[ResMenuItem alloc] initWithDisplay: display andMode: &modes[j]];
				//[item autorelease];
				if(mainModeNum == j)
				{
					mainItem = item;
					[item setState: NSControlStateValueOn];
				}
				[displayMenuItems addObject: item];
			}
			int idealColorDepth = 32;
			double idealRefreshRate = 0.0f;
			if(mainItem)
			{
				idealColorDepth = [mainItem colorDepth];
				idealRefreshRate = [mainItem refreshRate];
			}
			[displayMenuItems sortUsingSelector: @selector(compareResMenuItem:)];
		
		
			NSMenu* submenu = [[NSMenu alloc] initWithTitle: @""];
			
			ResMenuItem* lastAddedItem = nil;
			for(int j=0; j < [displayMenuItems count]; j++)
			{
				ResMenuItem* item = [displayMenuItems objectAtIndex: j];
				if([item colorDepth] == idealColorDepth)
				{
					if([item refreshRate] == idealRefreshRate)
					{
						[item setTextFormat: 1];
					}
					
					if(lastAddedItem && [lastAddedItem width]==[item width] && [lastAddedItem height]==[item height] && [lastAddedItem scale]==[item scale])
					{
						double lastRefreshRate = lastAddedItem ? [lastAddedItem refreshRate] : 0;
						double refreshRate = [item refreshRate];
						if(!lastAddedItem || (lastRefreshRate != idealRefreshRate && (refreshRate == idealRefreshRate || refreshRate > lastRefreshRate)))
						{
							if(lastAddedItem)
							{
								[submenu removeItem: lastAddedItem];
								lastAddedItem = nil;
							}
							[submenu addItem: item];
							lastAddedItem = item;
						}
					}
					else
					{	
						[submenu addItem: item];
						lastAddedItem = item;
					}
				}
			}
			
			NSString *screenName = @"";
			NSDictionary *deviceInfo = (__bridge NSDictionary *)IODisplayCreateInfoDictionary(CGDisplayIOServicePort(display), kIODisplayOnlyPreferredName);
			NSDictionary *localizedNames = [deviceInfo objectForKey:[NSString stringWithUTF8String:kDisplayProductName]];
			if ([localizedNames count] > 0) {
				screenName = [localizedNames objectForKey:[[localizedNames allKeys] objectAtIndex:0]];
			}
			
			[submenu addItem:[NSMenuItem separatorItem]];
			
			[submenu addItem:[[EditDisplayPlistItem alloc] initWithTitle:@"Edit..." action:@selector(editResolutions:) vendorID:CGDisplayVendorNumber(display) productID:CGDisplayModelNumber(display) displayName:screenName]];
			
			NSString* title = [NSString stringWithFormat: @"%d × %d%@",
							   [mainItem width], [mainItem height], ([mainItem scale] == 2.0f) ? @" ⚡️" : @""];
			
			NSMenuItem* resolution = [[NSMenuItem alloc] initWithTitle: title action: nil keyEquivalent: @""];
			[resolution setSubmenu: submenu];
			[statusMenu addItem: resolution];
		}
		
		{
			NSMutableArray* displayMenuItems = [NSMutableArray new];
			ResMenuItem* mainItem = nil;
			for(int j = 0; j < nModes; j++)
		    {
				ResMenuItem* item = [[ResMenuItem alloc] initWithDisplay: display andMode: &modes[j]];
				[item setTextFormat: 2];
				if(mainModeNum == j) {
					mainItem = item;
					[item setState: NSControlStateValueOn];
				}
				[displayMenuItems addObject: item];
			}
			int idealColorDepth = 32;
			double idealRefreshRate = 0.0f;
			if(mainItem) {
				idealColorDepth = [mainItem colorDepth];
				idealRefreshRate = [mainItem refreshRate];
			}
			[displayMenuItems sortUsingSelector: @selector(compareResMenuItem:)];
			
			
			NSMenu* submenu = [[NSMenu alloc] initWithTitle: @""];
			for(int j=0; j< [displayMenuItems count]; j++) {
				ResMenuItem* item = [displayMenuItems objectAtIndex: j];
				if([item colorDepth] == idealColorDepth) {
					if([mainItem width]==[item width] && [mainItem height]==[item height] && [mainItem scale]==[item scale])
						[submenu addItem: item];
				}
			}
			if(idealRefreshRate)
			{
				NSMenuItem* freq = [[NSMenuItem alloc] initWithTitle: [NSString stringWithFormat: @"%.0f Hz", [mainItem refreshRate]] action: nil keyEquivalent: @""];
			
				if([submenu numberOfItems] > 1)
					[freq setSubmenu: submenu];
				else
					[freq setEnabled: NO];
				[statusMenu addItem: freq];
			}
		}
		
		
		free(modes);
		
		
		[statusMenu addItem: [NSMenuItem separatorItem]];
	}
	
	if (nDisplays > 1) {
		NSMenuItem * mirroring = [[NSMenuItem alloc] initWithTitle:@"Display mirroring" action:@selector(toggleMirroring:) keyEquivalent: @""];
		mirroring.state = CGDisplayIsInMirrorSet(CGMainDisplayID());
		[statusMenu addItem:mirroring];
		[statusMenu addItem: [NSMenuItem separatorItem]];
	}
	
	[statusMenu addItemWithTitle: @"About RDM" action: @selector(showAbout) keyEquivalent: @""];
	
	
	[statusMenu addItemWithTitle: @"Quit" action: @selector(quit) keyEquivalent: @""];
	[statusMenu setDelegate: self];
	[statusItem setMenu: statusMenu];
}



- (void) editResolutions: (EditDisplayPlistItem *)sender {
	NSStoryboard *storyBoard = [NSStoryboard storyboardWithName:@"Main" bundle:nil];
	editResolutionsController = [storyBoard instantiateControllerWithIdentifier:@"edit"];
	ViewController *vc = (ViewController*)editResolutionsController.window.contentViewController;
	vc.vendorID = sender.vendorID;
	vc.productID = sender.productID;
	vc.displayProductName = sender.displayName;
	[editResolutionsController showWindow:self];
	[editResolutionsController.window makeKeyAndOrderFront:self];
	[[NSApplication sharedApplication] activateIgnoringOtherApps:YES];
}



CGError multiConfigureDisplays(CGDisplayConfigRef configRef, CGDirectDisplayID *displays, int count, CGDirectDisplayID master) {
	CGError error = kCGErrorSuccess;
	for (int i = 0; i < count; i++)
		if (displays[i] != master)
			error = error ? error : CGConfigureDisplayMirrorOfDisplay(configRef, displays[i], master);
	return error;
}

- (void) toggleMirroring: (NSMenuItem *)sender {
	CGDisplayCount numberOfOnlineDspys;
	CGDirectDisplayID displays[MAX_DISPLAYS];
	CGGetOnlineDisplayList(MAX_DISPLAYS, displays, &numberOfOnlineDspys);
	CGDisplayConfigRef configRef;
	CGBeginDisplayConfiguration (&configRef);
	multiConfigureDisplays(configRef, displays, numberOfOnlineDspys, sender.state ? kCGNullDirectDisplay : CGMainDisplayID());
	CGCompleteDisplayConfiguration (configRef,kCGConfigurePermanently);
}


- (void) setMode: (ResMenuItem*) item
{
	CGDirectDisplayID display = [item display];
	int modeNum = [item modeNum];
	
	SetDisplayModeNum(display, modeNum);
	/*
	
	CGDisplayConfigRef config;
    if (CGBeginDisplayConfiguration(&config) == kCGErrorSuccess) {
        CGConfigureDisplayWithDisplayMode(config, display, mode, NULL);
        CGCompleteDisplayConfiguration(config, kCGConfigureForSession);
    }*/
	[self refreshStatusMenu];
}

- (void) applicationDidFinishLaunching: (NSNotification*) notification
{
//	NSLog(@"Finished launching");
	statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength: NSSquareStatusItemLength];
	
	NSImage* statusImage = [NSImage imageNamed: @"StatusIcon"];
	statusItem.button.image = statusImage;
	[statusItem.button.image setTemplate:YES];
	
	[self refreshStatusMenu];
    CGDisplayRegisterReconfigurationCallback(DisplayReconfigurationCallback, (void*)self);
}

@end
