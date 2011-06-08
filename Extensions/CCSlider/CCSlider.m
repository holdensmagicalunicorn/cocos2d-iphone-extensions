//
//  CCSlider.h
//  CCSliderControl from http://srooltheknife.blogspot.com/
//  https://bitbucket.org/iroth_net/ccslider
//
//  Created by Israel Roth 
//	Edited by Stepan Generalov on 23.01.11 for 
//   iTraceur - Parkour / Freerunning Platform Game
//         http://www.iTraceur.ru

#import "CCSlider.h"


@implementation CCSlider


+ (id) sliderWithBackgroundFile: (NSString *) bgFile thumbFile: (NSString *) thumbFile
{
	return [  [ [self alloc]  initWithBackgroundFile: bgFile 
										   thumbFile: thumbFile ]  autorelease  ];
}

+(id) sliderWithBackgroundSprite: (CCSprite *) bgSprite thumbMenuItem: (CCMenuItem *) aThumb
{
	return [  [ [self alloc]  initWithBackgroundSprite: bgSprite 
										 thumbMenuItem: aThumb ]  autorelease  ];
}

// Easy init
- (id) initWithBackgroundFile: (NSString *) bgFile thumbFile: (NSString *) thumbFile
{	
	// Prepare background for slider.
	CCSprite *bg = [CCSprite spriteWithFile:bgFile];
	
	// Prepare thumb (menuItem) for slider.
	CCSprite *thumbNormal = [CCSprite spriteWithFile: thumbFile];
	CCSprite *thumbSelected = [CCSprite spriteWithFile: thumbFile];
	thumbSelected.color = ccGRAY;		
	CCMenuItemSprite *thumbMenuItem = [CCMenuItemSprite itemFromNormalSprite:thumbNormal selectedSprite: thumbSelected];
	
	// Continue with designated init on successfull prepare.
	if (thumbNormal && thumbSelected && thumbMenuItem && bg)
	{
		self = [self initWithBackgroundSprite:bg thumbMenuItem: thumbMenuItem];
		return self;
	}
		
	// Don't leak & return nil on fail.
	[self release];
	return nil;
}

// Designated init
-(id) initWithBackgroundSprite: (CCSprite *) bgSprite thumbMenuItem: (CCMenuItem *) aThumb  
{  
	if ((self = [super init]))  
	{   
#ifdef __IPHONE_OS_VERSION_MAX_ALLOWED
		self.isTouchEnabled = YES;  
#else if (__MAC_OS_X_VERSION_MAX_ALLOWED)
		self.isMouseEnabled = YES;
#endif
		value = 0;  
		
		// add the slider background  
		_bg = bgSprite; 
		[self setContentSize:[_bg contentSize]];  
		self.isRelativeAnchorPoint = YES;
		self.anchorPoint = ccp(0.5f,0.5f);
		
		_bg.position = CGPointMake([_bg contentSize].width / 2, [_bg contentSize].height / 2);  
		[self addChild:_bg];  
		
		// add the slider thumb  
		CGSize thumbSize;  
		_thumb = aThumb;
		thumbSize = [_thumb contentSize];  
		minX = thumbSize.width / 2;  
		maxX = [self contentSize].width - thumbSize.width / 2;  
		_thumb.position = CGPointMake(minX, [self contentSize].height / 2);  
		[self addChild:_thumb];  
	}  
	return self;  
}  

@synthesize delegate;
@dynamic value;

- (float) value
{
	return value;
}

- (void) setValue:(float) newValue
{
	// set new value with sentinel
    if (newValue < 0) 
		newValue = 0;
	
    if (newValue > 1.0) 
		newValue = 1.0;
	
    value = newValue;
	
	// update thumb position for new value
    CCMenuItem *thumb = _thumb;
    CGPoint pos = thumb.position;
    pos.x = minX + newValue * (maxX - minX);
    thumb.position = pos;
	
	[delegate valueChanged:value tag:self.tag];
    
}

- (NSInteger) mouseDelegatePriority
{
	return kCCSliderPriority;
}

-(BOOL) isTouchForMe:(CGPoint)touchLocation
{
    if (CGRectContainsPoint([_bg boundingBox], touchLocation))
		return YES;
	
	// Enlarge touch zone, when bg is thinner than thumb.
	if (CGRectContainsPoint([_thumb boundingBox], touchLocation))
		return YES;
	
	return NO;
}

#ifdef __IPHONE_OS_VERSION_MAX_ALLOWED
-(void) registerWithTouchDispatcher
{
    [[CCTouchDispatcher sharedDispatcher] addTargetedDelegate:self priority:kCCSliderPriority swallowsTouches:YES];
}

-(CGPoint) locationFromTouch:(UITouch *)touch
{
    CGPoint touchLocation = [touch locationInView: [touch view]];
	touchLocation = [[CCDirector sharedDirector] convertToGL: touchLocation];
    touchLocation = [self convertToNodeSpace: touchLocation];
    return touchLocation;
}

-(BOOL) ccTouchBegan:(UITouch *)touch withEvent:(UIEvent *)event
{
    CGPoint location = [self locationFromTouch:touch];
    bool isTouchHandled = [self isTouchForMe:location];
    if (isTouchHandled) {
        CCMenuItem *thumb = _thumb;
        [thumb selected];
		
        CGPoint pos = thumb.position;
        pos.x = location.x;
        thumb.position = pos;
    }
    return isTouchHandled; // YES for events I handle
}

-(void) ccTouchMoved:(UITouch *)touch withEvent:(UIEvent *)event
{
    CGPoint location = [self locationFromTouch:touch];
    if ((location.x < minX) || (location.x > maxX))
        return;
	
    CCSprite *thumb = (CCSprite *)[[self children] objectAtIndex:1];
    CGPoint pos = thumb.position;
    pos.x = location.x;
    thumb.position = pos;
}

-(void) ccTouchEnded:(UITouch *)touch withEvent:(UIEvent *)event
{
    CCSprite *thumb = (CCSprite *)[[self children] objectAtIndex:1];
    [_thumb unselected];
    self.value = (thumb.position.x - minX) / (maxX - minX);
}
#endif

#ifdef __MAC_OS_X_VERSION_MAX_ALLOWED

-(CGPoint) locationFromEvent:(NSEvent *) theEvent
{
	CGPoint location = [[CCDirector sharedDirector] convertEventToGL:theEvent];
	return [self convertToNodeSpace: location];
}

-(BOOL) ccMouseDown:(NSEvent*)event
{
	CGPoint location = [self locationFromEvent: event];
    BOOL isTouchHandled = [self isTouchForMe:location];
    
	if (isTouchHandled) 
	{
        CCMenuItem *thumb = _thumb;
        [thumb selected];
		
        CGPoint pos = thumb.position;
        pos.x = location.x;
        thumb.position = pos;
    }
    return isTouchHandled; // YES for events I handle
}


-(BOOL) ccMouseDragged:(NSEvent*)event
{
	CGPoint location = [self locationFromEvent: event];
	
	if (! _thumb.isSelected)
		return NO;
    
	if ((location.x < minX) || (location.x > maxX))
        return NO;
	
    CGPoint pos = _thumb.position;
    pos.x = MIN(location.x, maxX);
	pos.x = MAX(pos.x, minX );
    _thumb.position = pos;
	
	return YES;
}

-(BOOL) ccMouseUp:(NSEvent*)event
{
	[_thumb unselected];
    self.value = (_thumb.position.x - minX) / (maxX - minX);
    
	
	return [_thumb isSelected];
}

#endif

@end