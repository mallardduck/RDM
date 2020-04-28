


@interface SRApplicationDelegate : NSObject <NSApplicationDelegate, NSMenuDelegate>
{
	NSMenu* statusMenu;
	NSWindowController *editResolutionsController;
	NSStatusItem* statusItem;
}
- (void) refreshStatusMenu;
@end

