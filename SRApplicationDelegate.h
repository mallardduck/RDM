


@interface SRApplicationDelegate : NSObject <NSApplicationDelegate, NSMenuDelegate>
{
	NSMenu* statusMenu;
	NSWindowController *editResolutionsController;
	NSStatusItem* statusItem;
}
- (io_service_t) IOServicePortFromCGDisplayID: (CGDirectDisplayID) displayID;
- (void) refreshStatusMenu;
@end

